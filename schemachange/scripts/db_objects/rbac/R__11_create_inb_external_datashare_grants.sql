
--creating RBACs for env {{in_sf_env}}


{% if in_sf_env.lower() == 'prd' %}
    use role securityadmin;
    grant IMPORTED PRIVILEGES on database SEND_TO_PEXA_DATA_SHARE to role PRD_SUPPORT_F;
    grant IMPORTED PRIVILEGES on database SEND_TO_PEXA_DATA_SHARE to role PRD_DATA_GOVERNANCE_SPECIALIST_F;
    grant IMPORTED PRIVILEGES on database SEND_TO_PEXA_DATA_SHARE to role PRD_dbt_integration_role_s;
{% else %}
    {% set db_name = in_sf_env + "_SEND_TO_PEXA_DATA_SHARE" %}
    {% set in_schema = db_name + ".DYNAMO" %}
    {% set db_reader_a_role = db_name + "." + "READER_DBROLE_A" %}
    {% set dbt_role = in_sf_env+"_DBT_INTEGRATION_ROLE_S" %}
    {% set dg_role = in_sf_env+"_DATA_GOVERNANCE_SPECIALIST_F" %}
    {% set support_role= in_sf_env+"_SUPPORT_F" %}

    use role sysadmin;
    create database role if not exists {{ db_reader_a_role }};
    
    use role securityadmin;
    grant database role  {{db_reader_a_role}}    to role     {{ dbt_role }};
    grant database role  {{db_reader_a_role}}    to role     {{dg_role}};
    grant database role  {{db_reader_a_role}}    to role     {{support_role}};

    grant usage                            on database                                    {{ db_name }}     to database role {{db_reader_a_role}} ;
    grant usage                            on schema                                      {{ in_schema }} to database role {{db_reader_a_role}} ;
    grant select, references               on all tables             in schema {{ in_schema }} to database role {{db_reader_a_role}} ;
    grant select, references               on all views              in schema {{ in_schema }} to database role {{db_reader_a_role}} ;
{% endif %}
   
   