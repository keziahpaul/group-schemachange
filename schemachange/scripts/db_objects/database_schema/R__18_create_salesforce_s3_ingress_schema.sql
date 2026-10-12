{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  data science database and  machine learning schema for env {{in_sf_env}}

{{create_database_schema(in_sf_env, 'GROUP_RAW', "SALESFORCE" )}}
{{create_database_schema(in_sf_env, 'GROUP_STAGE', "SALESFORCE" )}}