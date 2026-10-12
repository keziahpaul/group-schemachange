
{% set ds_database = in_sf_env+'_GROUP_COMMON_DATA_LAYER' %}

{% set schema_name = 'CDM' %}

{% set common_tables_list = [
    'DIM_DATE',
    'DIM_STATE'
] %}

{% if in_sf_env.lower() == 'dev' %} 
    {% set share_name = 'DEV_NON_PROD_COMMON_DATA' %}
{% elif in_sf_env.lower() == 'tst' %}
    {% set share_name = 'NON_PROD_COMMON_DATA' %}
{% elif in_sf_env.lower() == 'prd' %}
    {% set share_name = 'PROD_COMMON_DATA' %}
{% else %}
    {% set share_name = none %}
{% endif %}

{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;
use role accountadmin;

create share if not exists {{share_name}};

grant usage on database  {{ds_database}}  to share {{ share_name }};
grant usage  on schema  {{ds_database}}.{{schema_name}}  to share {{ share_name }};

--grants to PII DB roles
grant usage on database  {{ds_database}}  to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
grant usage on database  {{ds_database}}  to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;

grant usage  on schema  {{ds_database}}.{{schema_name}}   to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
grant usage  on schema  {{ds_database}}.{{schema_name}}   to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;


{% for tbl in common_tables_list %}
    grant select on  {{ds_database}}.{{schema_name}}.{{tbl}} to database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE;
    grant select on  {{ds_database}}.{{schema_name}}.{{tbl}} to database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE;
    grant select on  {{ds_database}}.{{schema_name}}.{{tbl}} to share {{share_name}};
{% endfor %}

--granting PII db roles to share
grant database role {{ds_database}}.PI_MASKED_DATASHARE_DBROLE to share {{ share_name }};
grant database role {{ds_database}}.PI_PUBLIC_DATASHARE_DBROLE to share {{ share_name }};

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
{% else %}
select 1 ;
{% endif %}