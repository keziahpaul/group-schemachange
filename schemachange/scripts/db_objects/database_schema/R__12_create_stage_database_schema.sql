{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  database and  schema for env {{in_sf_env}} RUNNING FOR SALESFORCE EXCHANGE and FMS
{{create_database_schema(in_sf_env,  'GROUP_STAGE', ["SENDFX","FMS"])}}  

