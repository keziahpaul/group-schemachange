{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  database and  schema for env {{in_sf_env}} RUNNING FOR SALESFORCE AND EXCHANGE
{{create_database_schema(in_sf_env,  'GROUP_CURATE', ["SALESFORCE","SENDFX"])}}
{{create_database_schema(in_sf_env,  'GROUP_CURATE', "KAPICHE")}}
{{create_database_schema(in_sf_env,  'GROUP_CURATE', "FMS")}}
{{create_database_schema(in_sf_env,  'GROUP_CURATE', "JIRA")}}
{{create_database_schema(in_sf_env,  'GROUP_CURATE', "GENESYS")}}