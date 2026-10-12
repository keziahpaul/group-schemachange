--Creating Network Rules for JIRA
use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema jira;
CREATE OR REPLACE NETWORK RULE jira_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ({{ jira['network_identifier'] }});

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
