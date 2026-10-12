use role useradmin;
-- slack job alert user
create user if not exists {{ in_sf_env }}_SLACK_JOB_NOTIFICATION_USER;
  alter user {{ in_sf_env }}_SLACK_JOB_NOTIFICATION_USER set EMAIL = {{ params_dict['slack_job_notification_email_address'] }} ;
  alter user {{ in_sf_env }}_SLACK_JOB_NOTIFICATION_USER set password=null;