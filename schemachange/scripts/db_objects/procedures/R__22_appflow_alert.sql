use database {{in_sf_env}}_logging;
use schema splunk_logging;
CREATE OR REPLACE PROCEDURE send_appflow_failure_alerts(database_name string, schema_name string, stage_name string, table_name string, last_n_hours int)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'refresh_stage_and_send_alerts_handler'
EXECUTE AS CALLER
AS
$$
def refresh_stage_and_send_alerts_handler (session, database_name, schema_name, stage_name, table_name, last_n_hours):

    fully_qualified_stage = f"{database_name}.{schema_name}.{stage_name}"

    # Refresh the external stage
    try:
        session.sql(f"ALTER STAGE {fully_qualified_stage} REFRESH").collect()
    except Exception as err:
        return f"Error refreshing external stage {fully_qualified_stage}: {err}"

    # Get new filenames from stage directory file registration history and add them to the alert queue
    try:
        query = f"""
INSERT INTO {{in_sf_env}}_logging.splunk_logging.appflow_exceptions_alerts (STAGE_NAME, TABLE_NAME, STAGE_FILE_NAME, IS_ALERT_SENT, CREATED_TIMESTAMP)
SELECT
    '@{fully_qualified_stage}' AS STAGE_NAME,
    lower('{table_name}') AS TABLE_NAME,
    SUBSTRING(FILE_NAME, CHARINDEX('/', FILE_NAME) + 1) AS STAGE_FILE_NAME,
    FALSE,
    CURRENT_TIMESTAMP
FROM TABLE({database_name}.INFORMATION_SCHEMA.STAGE_DIRECTORY_FILE_REGISTRATION_HISTORY(
    START_TIME=>DATEADD('hour', -{last_n_hours}, CURRENT_TIMESTAMP),
    STAGE_NAME=>'{fully_qualified_stage}'))
WHERE lower(file_name) LIKE lower('%/{table_name}/%')
        """
        result = session.sql(query).collect()
    except Exception as err:
        return f"Error getting new file paths: {err}"

    if result and result[0][0] > 0:
        # Determine if the message could be received out of hours
        session.sql("ALTER SESSION SET TIMEZONE = 'Australia/Sydney'").collect()
        need_resend = session.sql("SELECT NOT (EXTRACT(WEEKDAY FROM CURRENT_TIMESTAMP) BETWEEN 1 AND 5 AND EXTRACT(HOUR FROM CURRENT_TIMESTAMP) BETWEEN 9 AND 15) AS RESEND").collect()
        session.sql("ALTER SESSION UNSET TIMEZONE").collect()
        need_resend = need_resend[0][0]
        session.sql('CALL {{in_sf_env}}_logging.splunk_logging.resend_out_of_hours_appflow_failure_alerts(?)', params=[need_resend]).collect()
        return f"Sent a notification related to {result[0][0]} files"
    else:
        return "No new files found in the specified time period"
$$;

CREATE OR REPLACE PROCEDURE resend_out_of_hours_appflow_failure_alerts(need_resend boolean)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'resend_alerts_handler'
EXECUTE AS CALLER
AS
$$
from datetime import datetime, timedelta
from snowflake.snowpark.functions import call_builtin

def resend_alerts_handler (session, need_resend):

    stage_names = session.sql("""
SELECT DISTINCT STAGE_NAME, TABLE_NAME
FROM {{in_sf_env}}_logging.splunk_logging.appflow_exceptions_alerts
WHERE IS_ALERT_SENT = FALSE
    """).collect()

    for stage_name, table_name in stage_names:
        # Get this batch of records from appflow_exceptions_alerts
        unsent_alerts = session.sql(f"""
SELECT
    GET_PRESIGNED_URL({stage_name}, STAGE_FILE_NAME, 3600) AS SIGNED_URL,
    REGEXP_SUBSTR(STAGE_FILE_NAME, '[^/]+$') AS ERROR_FILENAME
FROM {{in_sf_env}}_logging.splunk_logging.appflow_exceptions_alerts
WHERE IS_ALERT_SENT = FALSE
  AND STAGE_NAME = '{stage_name}'
  AND TABLE_NAME = '{table_name}'
        """).collect()

        # Create a formatted list of files for the email body
        file_list_html = ('<ul>' +
                          ''.join([f'<li><a href="{row[0]}">{row[1]}</a></li>' for row in unsent_alerts]) +
                          '</ul>')
        subject = f'Job environment {{in_sf_env}}: {table_name}-table-appflow-failure'

        try:
            # Send email alert
            message_body = f"""
<p>Hi Team,<br><br>
There is an error alert caused by Appflow.<br><br>
Please find below url for error file details:<br>
{file_list_html}</p>
            """
            if need_resend:
                message_body += "<p>This message will be resent at 9am Mon-Fri<p>"

            query = f"""
CALL SYSTEM$SEND_SNOWFLAKE_NOTIFICATION(
    SNOWFLAKE.NOTIFICATION.TEXT_HTML(?),
    SNOWFLAKE.NOTIFICATION.EMAIL_INTEGRATION_CONFIG(
        '{{in_sf_env}}_slack_alert_integration',
        ?,
        ARRAY_CONSTRUCT({{ params_dict['slack_job_notification_email_address'] }})
    )
)
            """
            session.sql(query, params=[message_body, subject]).collect()

            # remove them if this is "in hours"
            if not need_resend:
                result = session.sql(f"""
DELETE FROM {{in_sf_env}}_logging.splunk_logging.appflow_exceptions_alerts
WHERE STAGE_NAME = '{stage_name}'
  AND TABLE_NAME = '{table_name}'
                """).collect()
        except Exception as err:
            return f"Error in sending email notification: {err}"

    return f"Alerts sent successfully for files {file_list_html}"
$$;
