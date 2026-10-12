{% from 'modules/create_access_roles_privileges.j2' import create_access_roles_privileges-%}

--creating RBACs for env {{in_sf_env}}
{{create_access_roles_privileges(in_sf_env,'GROUP_CURATE','SALESFORCE','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_CURATE','SENDFX','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_CURATE','KAPICHE','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_CURATE','FMS','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_CURATE','JIRA','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_CURATE','GENESYS','all','TRN_XS_WH')}}
use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;

-- role got created in R__04_create_raw_grants
grant usage on database {{in_sf_env}}_group_curate to role incident_raw_data_read_role;
grant usage on schema {{in_sf_env}}_group_curate.jira to role incident_raw_data_read_role;
grant select on all tables in schema {{in_sf_env}}_group_curate.jira to role incident_raw_data_read_role;
grant select on all views in schema {{in_sf_env}}_group_curate.jira to role incident_raw_data_read_role;
grant select on all materialized views in schema {{in_sf_env}}_group_curate.jira to role incident_raw_data_read_role;

grant select on future tables in schema {{in_sf_env}}_group_curate.jira to role incident_raw_data_read_role;
grant select on future views in schema {{in_sf_env}}_group_curate.jira to role incident_raw_data_read_role;
grant select on future materialized views in schema {{in_sf_env}}_group_curate.jira to role incident_raw_data_read_role;

grant usage on schema {{in_sf_env}}_group_curate.genesys to role incident_raw_data_read_role;
grant select on all tables in schema {{in_sf_env}}_group_curate.genesys to role incident_raw_data_read_role;
grant select on all views in schema {{in_sf_env}}_group_curate.genesys to role incident_raw_data_read_role;
grant select on all materialized views in schema {{in_sf_env}}_group_curate.genesys to role incident_raw_data_read_role;

grant select on future tables in schema {{in_sf_env}}_group_curate.genesys to role incident_raw_data_read_role;
grant select on future views in schema {{in_sf_env}}_group_curate.genesys to role incident_raw_data_read_role;
grant select on future materialized views in schema {{in_sf_env}}_group_curate.genesys to role incident_raw_data_read_role;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
