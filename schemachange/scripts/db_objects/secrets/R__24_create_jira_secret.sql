-- Secret Configuration that would be used for connecting to JIRA REST API
-- NOTE: 
-- - The client credentails are stored in AWS Secret manager
-- - The secret here is created with dummy client values
-- - After deployment, we need to manually get the client credentials from AWS Secret Manager and manually update this secret object before calling the procedure
-- - Currently taking this tatical approach due to the urgency of the project delivery, stratergic solution would be automate this proceess

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema jira;

CREATE SECRET IF NOT EXISTS {{ in_sf_env }}_GROUP_RAW.JIRA.JIRA_CREDENTIALS
TYPE = GENERIC_STRING
SECRET_STRING = '{
    "url": "{{ jira['url'] }}",
    "email": "{{ jira['email'] }}",
    "api_token": "xxx"
}';

grant usage on secret jira_credentials to role sysadmin;
grant usage on secret jira_credentials to role {{ in_sf_env }}_dbt_integration_role_s;
grant usage on secret jira_credentials to role {{ in_sf_env }}_support_f;

grant read on secret jira_credentials to role sysadmin;
grant read on secret jira_credentials to role {{ in_sf_env }}_dbt_integration_role_s;
grant read on secret jira_credentials to role {{ in_sf_env }}_support_f;

grant modify on secret jira_credentials to role sysadmin;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
