-- Creates secret for group to aws connection

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GOVERNANCE_DB;
use schema COMPLIANCE;

CREATE OR REPLACE SECRET {{in_sf_env}}_GOVERNANCE_DB.COMPLIANCE.AWS_SECRETSMANAGER_TOKEN
  TYPE = CLOUD_PROVIDER_TOKEN
  API_AUTHENTICATION = {{ in_sf_env }}_aws_secretsmgr_security_integration;

grant usage on secret AWS_SECRETSMANAGER_TOKEN to role sysadmin;
grant usage on secret AWS_SECRETSMANAGER_TOKEN to role {{ in_sf_env }}_dbt_integration_role_s;
grant usage on secret AWS_SECRETSMANAGER_TOKEN to role {{ in_sf_env }}_support_f;

grant read on secret AWS_SECRETSMANAGER_TOKEN to role sysadmin;
grant read on secret AWS_SECRETSMANAGER_TOKEN to role {{ in_sf_env }}_dbt_integration_role_s;
grant read on secret AWS_SECRETSMANAGER_TOKEN to role {{ in_sf_env }}_support_f;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;