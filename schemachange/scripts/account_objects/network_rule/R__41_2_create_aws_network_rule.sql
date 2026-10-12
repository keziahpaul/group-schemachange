-- Creates network rule for group to aws connection

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GOVERNANCE_DB;
use schema COMPLIANCE;

CREATE OR REPLACE NETWORK RULE {{in_sf_env}}_GOVERNANCE_DB.COMPLIANCE.AWS_SECRETSMANAGER_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('secretsmanager.ap-southeast-2.amazonaws.com', 'secretsmanager.ap-southeast-4.amazonaws.com');

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;