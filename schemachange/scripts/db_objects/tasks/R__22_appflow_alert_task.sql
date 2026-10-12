use database {{in_sf_env}}_logging;
use schema splunk_logging;

-- This task is scheduled to run every weekday at 9 AM Sydney time.
CREATE OR REPLACE TASK send_appflow_failure_task
    WAREHOUSE = {{in_sf_env}}_trn_xs_wh
    SCHEDULE = 'USING CRON 0 9 * * MON-FRI Australia/Sydney'
AS
    CALL {{in_sf_env}}_logging.splunk_logging.resend_out_of_hours_appflow_failure_alerts(FALSE);

ALTER TASK send_appflow_failure_task RESUME;
