use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema jira;

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION aws_secretsmanager_integration
    ALLOWED_NETWORK_RULES = (
        {%- if (in_sf_env.lower() == 'pst') %}
            'PST_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_network_rule'
        {%- elif (in_sf_env.lower() == 'prd')  %}
            'PRD_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_network_rule',
            'PST_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_network_rule'
        {%- elif (in_sf_env.lower() == 'dev')  %}
            'DEV_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_network_rule'
        {%- elif (in_sf_env.lower() == 'tst')  %}
            'TST_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_network_rule',
            'DEV_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_network_rule'
        {%- endif %} 
)
    ALLOWED_AUTHENTICATION_SECRETS = (
        {%- if (in_sf_env.lower() == 'pst') %}
            'PST_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_token'
        {%- elif (in_sf_env.lower() == 'prd')  %}
            'PRD_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_token',
            'PST_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_token'
        {%- elif (in_sf_env.lower() == 'tst')  %}
            'TST_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_token',
            'DEV_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_token'
        {%- elif (in_sf_env.lower() == 'dev')  %}
            'DEV_GOVERNANCE_DB.COMPLIANCE.aws_secretsmanager_token'
        {%- endif %} 
    )
  ENABLED = TRUE;

grant usage on integration aws_secretsmanager_integration to role sysadmin;
grant usage on integration aws_secretsmanager_integration to role {{ in_sf_env }}_dbt_integration_role_s;
grant usage on integration aws_secretsmanager_integration to role {{ in_sf_env }}_support_f;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;