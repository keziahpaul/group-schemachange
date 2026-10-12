--Creating External Access Integration for snowflake to access Genesys
use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema genesys;
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION genesys_access
ALLOWED_NETWORK_RULES = (
{%- if (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}
    'PST_GROUP_RAW.GENESYS.genesys_access_rule'
{%- if (in_sf_env.lower() == 'prd') -%}
    , 'PRD_GROUP_RAW.GENESYS.genesys_access_rule'
{%- endif %}
{%- else %}
    'DEV_GROUP_RAW.GENESYS.genesys_access_rule'
{%- if (in_sf_env.lower() == 'tst') -%}
    , 'TST_GROUP_RAW.GENESYS.genesys_access_rule'
{%- endif %}
{%- endif %}
)
ALLOWED_AUTHENTICATION_SECRETS = (
{%- if (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}
    'PST_GROUP_RAW.GENESYS.GENESYS_CREDENTIALS'
{%- if (in_sf_env.lower() == 'prd') -%}
    , 'PRD_GROUP_RAW.GENESYS.GENESYS_CREDENTIALS'
{%- endif %}
{%- else %}
    'DEV_GROUP_RAW.GENESYS.GENESYS_CREDENTIALS'
{%- if (in_sf_env.lower() == 'tst') -%}
    , 'TST_GROUP_RAW.GENESYS.GENESYS_CREDENTIALS'
{%- endif %}
{%- endif %}
)
ENABLED = true;

grant usage on integration genesys_access to role sysadmin;
grant usage on integration genesys_access to role {{ in_sf_env }}_dbt_integration_role_s;
grant usage on integration genesys_access to role {{ in_sf_env }}_support_f;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
