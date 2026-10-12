--Creating Network Rules for Genesys
use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema genesys;
CREATE OR REPLACE NETWORK RULE genesys_access_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ({{ genesys['network_identifiers'] }});

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
