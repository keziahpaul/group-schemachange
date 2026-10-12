--Creating External Access Integration for snowflake to access JIRA
use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;

CREATE OR REPLACE SECURITY INTEGRATION {{ in_sf_env }}_aws_secretsmgr_security_integration
type = api_authentication
auth_type = aws_iam
enabled = true
aws_role_arn = 'arn:aws:iam::{{aws_account_number}}:role/{{aws_secretmgr_role}}';

grant usage on integration {{ in_sf_env }}_aws_secretsmgr_security_integration to role sysadmin;
grant usage on integration {{ in_sf_env }}_aws_secretsmgr_security_integration to role {{ in_sf_env }}_dbt_integration_role_s;
grant usage on integration {{ in_sf_env }}_aws_secretsmgr_security_integration to role {{ in_sf_env }}_support_f;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;