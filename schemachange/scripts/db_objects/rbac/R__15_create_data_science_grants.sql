{% from 'modules/create_access_roles_privileges.j2' import create_access_roles_privileges-%}

--creating RBACs for env {{in_sf_env}}
{{create_access_roles_privileges(in_sf_env,'GROUP_DATA_SCIENCE','MACHINE_LEARNING','all','TRN_XS_WH')}}

{% set science_db= in_sf_env+"_"+"group_data_science" %}
{% set sandbox_db= in_sf_env+"_"+"sandbox" %}
{% set scientist_role= in_sf_env+"_"+"data_scientist_public_f" %}
{% set dbt_role = in_sf_env+"_dbt_integration_role_s" %}
{% set selfservice_db = in_sf_env+"_group_selfservice_analytics" %}
{% set ssa_dbt_role = in_sf_env+"_ssa_dbt_integration_role_s" %}

--granting Ml access to DBT role in data science DB

grant create snowflake.ml.anomaly_detection on schema {{science_db}}.machine_learning to role {{dbt_role}};

grant create snowflake.ml.classification on schema {{science_db}}.machine_learning to role {{dbt_role}};

grant create snowflake.ml.forecast on schema {{science_db}}.machine_learning to role {{dbt_role}};

grant create snowflake.ml.document_intelligence on schema {{science_db}}.machine_learning to role {{dbt_role}};


--granting Ml access to special data scientist role in sandbox DB
grant create snowflake.ml.anomaly_detection on schema {{sandbox_db}}.ds_sandbox to role {{scientist_role}};

grant create snowflake.ml.classification on schema {{sandbox_db}}.ds_sandbox to role {{scientist_role}};

grant create snowflake.ml.forecast on schema {{sandbox_db}}.ds_sandbox to role {{scientist_role}};

grant create snowflake.ml.document_intelligence on schema {{sandbox_db}}.ds_sandbox to role {{scientist_role}};
--granting Ml access to to ssa_dbt role in sandbox DB 
grant create snowflake.ml.anomaly_detection on schema {{sandbox_db}}.ds_sandbox to role {{ssa_dbt_role}};

grant create snowflake.ml.classification on schema {{sandbox_db}}.ds_sandbox to role {{ssa_dbt_role}};

grant create snowflake.ml.forecast on schema {{sandbox_db}}.ds_sandbox to role {{ssa_dbt_role}};
grant create snowflake.ml.document_intelligence on schema {{sandbox_db}}.ds_sandbox to role {{ssa_dbt_role}};

--granting create SNOWFLAKE.ML.FORECAST to data scientist role
grant create snowflake.ml.forecast on schema {{selfservice_db}}.exchange to role {{scientist_role}};