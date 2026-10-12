
-- Create or replace alert
{% if in_sf_env.lower() == 'prd' or in_sf_env.lower() == 'pst' %}
{% set exchange_db = 'EXCHANGE_INBOUND_DATASHARING' %}
{% else %}
{% set exchange_db = 'NONPROD_EXCHANGE_DATA_SHARE' %}
{% endif %}

CREATE OR REPLACE ALERT {{ in_sf_env }}_GROUP_INT_DATASERVICES.SALESFORCE_DATASERVICES.ALERT_SEND_SUBSCRIBER_EXCEPTION
  WAREHOUSE = {{ in_sf_env }}_developer_xs_wh
  SCHEDULE = 'USING CRON 0 1 * * * UTC'
  IF (EXISTS (
    SELECT 'SEND_SUBSCRIBER_MATCH_EXCEPTION' AS issue_type, master_registration_id
    FROM {{ in_sf_env }}_group_int_dataservices.salesforce_dataservices.SEND_SUBSCRIBER_MATCH_EXCEPTION
    QUALIFY ROW_NUMBER() OVER (PARTITION BY MASTER_REGISTRATION_ID ORDER BY Registration_created_source desc) = 1
    
    
    UNION ALL

    -- 2) New query: inactive subscribers with transactions in last 3 months
    SELECT
      'INACTIVE_SUBSCRIBER_WITH_TRANSACTION' AS issue_type,
      m.master_registration_id
    FROM {{ in_sf_env }}_GROUP_INT_DATASERVICES.SALESFORCE_DATASERVICES.SEND_TRANSACTION_DETAILS t
    INNER JOIN {{ in_sf_env }}_GROUP_INT_DATASERVICES.SALESFORCE_DATASERVICES.SEND_SUBSCRIBER_MATCH_PROCESS m
      ON t.registration_id = m.registration_id
    INNER JOIN {{exchange_db}}.exchange.vw_subscribers s
      ON t.subscriber_id = s.subscriber_id
    WHERE UPPER(s.status) NOT IN ('ACTIVE')
      AND t.completed_date_settlement_date > ADD_MONTHS(CURRENT_DATE, -3)
    
  ))
  THEN
CALL SYSTEM$SEND_SNOWFLAKE_NOTIFICATION(
  SNOWFLAKE.NOTIFICATION.TEXT_HTML(
    (SELECT
     CONCAT(
        '<p>Hi Team,<br>',
        'There are ',  COUNT_IF(issue_type = 'SEND_SUBSCRIBER_MATCH_EXCEPTION'), ' send subscriber mapping exceptions.<br>',
        'There are ',  COUNT_IF(issue_type = 'INACTIVE_SUBSCRIBER_WITH_TRANSACTION'), ' inactive subscribers with transactions in last 3 months.<br>',
        'Please open app in snowflake to manually map a send registartion to a subscriber.<br>',
        'Thanks & Regards,<br>',
        'One Data Team</p>')
      FROM TABLE(RESULT_SCAN(SNOWFLAKE.ALERT.GET_CONDITION_QUERY_UUID()))
    )
  ),
  SNOWFLAKE.NOTIFICATION.EMAIL_INTEGRATION_CONFIG(
    '{{ in_sf_env }}_slack_alert_integration',
    '{{ in_sf_env }} - Send subscriber exception alert',
    ARRAY_CONSTRUCT({{ params_dict['send_alert_slack_email'] }})
  )
);

-- Alter alert to start it
{% if in_sf_env.lower() == 'prd' %}

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
GRANT EXECUTE ALERT ON ACCOUNT TO ROLE {{in_sf_env}}_GITHUB_INTEGRATION_ROLE_S;


use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;

use  role PRD_GITHUB_INTEGRATION_ROLE_S;
ALTER ALERT {{ in_sf_env }}_GROUP_INT_DATASERVICES.SALESFORCE_DATASERVICES.ALERT_SEND_SUBSCRIBER_EXCEPTION RESUME;
{% endif %}
select 1;
