{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  database and  schema for env {{in_sf_env}}
{% if (in_sf_env.lower() != 'prd')  %}
    {{create_database_schema(in_sf_env,'SEND_TO_PEXA_DATA_SHARE','DYNAMO')}}
{% else %}
    select 1;
{% endif %}