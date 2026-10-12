{% from 'modules/create_access_roles_privileges.j2' import create_access_roles_privileges-%}

--creating RBACs for env {{in_sf_env}}
{{create_access_roles_privileges(in_sf_env,'GROUP_RAW', "KAPICHE",'all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_RAW', "SENDFX",'all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_RAW', "FMS",'all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_RAW', "JIRA",'all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_RAW', "GENESYS",'all','TRN_XS_WH')}}


--granting PII access to the exchange data share
{% if in_sf_env.lower() in [ 'dev', 'tst' ]  %}

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;

grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_MASKED_DATASHARE_DBROLE to role {{in_sf_env}}_analyst_f;
grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_MASKED_DATASHARE_DBROLE to role {{in_sf_env}}_di_analyst_f;
grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_MASKED_DATASHARE_DBROLE to role {{in_sf_env}}_engineer_f;
grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_MASKED_DATASHARE_DBROLE to role {{in_sf_env}}_alation_integration_role_s;
grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_dbt_integration_role_s;
grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_data_governance_specialist_f;
grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_di_analyst_public_f;
grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_data_scientist_public_f;
grant database role NONPROD_EXCHANGE_DATA_SHARE.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_support_f;

-- Creating Custom Role to support Tableau Service User for accessing the Incident Data in Snowflake
create role if not exists incident_raw_data_read_role;

grant usage on database {{in_sf_env}}_group_raw to role incident_raw_data_read_role;
grant usage on schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on all tables in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on all views in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on all materialized views in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;

grant select on future tables in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on future views in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on future materialized views in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;

grant usage on schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on all tables in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on all views in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on all materialized views in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;

grant select on future tables in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on future views in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on future materialized views in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;

grant role incident_raw_data_read_role to role {{in_sf_env}}_di_analyst_public_f;
grant role incident_raw_data_read_role to role {{in_sf_env}}_tableau_integration_role_s;

{% elif in_sf_env.lower() in [ 'prd' ]  %}

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;

grant database role EXCHANGE_INBOUND_DATASHARING.PI_MASKED_DATASHARE_DBROLE to role {{in_sf_env}}_analyst_f;
grant database role EXCHANGE_INBOUND_DATASHARING.PI_MASKED_DATASHARE_DBROLE to role {{in_sf_env}}_di_analyst_f;
grant database role EXCHANGE_INBOUND_DATASHARING.PI_MASKED_DATASHARE_DBROLE to role {{in_sf_env}}_engineer_f;
grant database role EXCHANGE_INBOUND_DATASHARING.PI_MASKED_DATASHARE_DBROLE to role {{in_sf_env}}_alation_integration_role_s;
grant database role EXCHANGE_INBOUND_DATASHARING.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_dbt_integration_role_s;
grant database role EXCHANGE_INBOUND_DATASHARING.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_data_governance_specialist_f;
grant database role EXCHANGE_INBOUND_DATASHARING.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_di_analyst_public_f;
grant database role EXCHANGE_INBOUND_DATASHARING.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_data_scientist_public_f;
grant database role EXCHANGE_INBOUND_DATASHARING.PI_PUBLIC_DATASHARE_DBROLE to role {{in_sf_env}}_support_f;

-- Creating Custom Role to support Tableau Service User for accessing the Incident Data in Snowflake
create role if not exists incident_raw_data_read_role;

grant usage on database {{in_sf_env}}_group_raw to role incident_raw_data_read_role;
grant usage on schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on all tables in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on all views in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on all materialized views in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;

grant select on future tables in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on future views in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;
grant select on future materialized views in schema {{in_sf_env}}_group_raw.jira to role incident_raw_data_read_role;

grant usage on schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on all tables in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on all views in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on all materialized views in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;

grant select on future tables in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on future views in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;
grant select on future materialized views in schema {{in_sf_env}}_group_raw.genesys to role incident_raw_data_read_role;

grant role incident_raw_data_read_role to role {{in_sf_env}}_di_analyst_public_f;
grant role incident_raw_data_read_role to role {{in_sf_env}}_tableau_integration_role_s;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;

{% else %}
select 1;
{% endif %}
