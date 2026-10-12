{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  CDM schema for env {{in_sf_env}}

{{create_database_schema(in_sf_env, 'GROUP_COMMON_DATA_LAYER', "CDM" )}}

--creating  On Day Settlement Schema for env {{in_sf_env}}

{{create_database_schema(in_sf_env, 'GROUP_COMMON_DATA_LAYER', "ODS" )}}