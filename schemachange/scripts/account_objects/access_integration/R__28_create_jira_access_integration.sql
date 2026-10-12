--Creating External Access Integration for snowflake to access JIRA
use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema jira;
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION jira_end_point_access
ALLOWED_NETWORK_RULES = (
{%- if (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}
    'PST_GROUP_RAW.JIRA.jira_network_rule',
    'PRD_GROUP_RAW.JIRA.jira_network_rule'
{%- else %}
    'DEV_GROUP_RAW.JIRA.jira_network_rule',
    'TST_GROUP_RAW.JIRA.jira_network_rule'
{%- endif %}
)
ALLOWED_AUTHENTICATION_SECRETS = (
{%- if (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}
    'PST_GROUP_RAW.JIRA.JIRA_CREDENTIALS',
    'PRD_GROUP_RAW.JIRA.JIRA_CREDENTIALS'
{%- else %}
    'DEV_GROUP_RAW.JIRA.JIRA_CREDENTIALS',
    'TST_GROUP_RAW.JIRA.JIRA_CREDENTIALS'
{%- endif %}
)
ENABLED = true;

grant usage on integration jira_end_point_access to role sysadmin;
grant usage on integration jira_end_point_access to role {{ in_sf_env }}_dbt_integration_role_s;
grant usage on integration jira_end_point_access to role {{ in_sf_env }}_support_f;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;