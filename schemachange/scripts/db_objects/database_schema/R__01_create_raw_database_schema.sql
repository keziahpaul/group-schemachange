{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  database and  schema for env {{in_sf_env}}
{{create_database_schema(in_sf_env, 'GROUP_RAW', "KAPICHE" )}}
{{create_database_schema(in_sf_env, 'GROUP_RAW', "SENDFX" )}}
{{create_database_schema(in_sf_env, 'GROUP_RAW', "FMS" )}}
{{create_database_schema(in_sf_env, 'GROUP_RAW', "JIRA" )}}
{{create_database_schema(in_sf_env, 'GROUP_RAW', "GENESYS" )}}


