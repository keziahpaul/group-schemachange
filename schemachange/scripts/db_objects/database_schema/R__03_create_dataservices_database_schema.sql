{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating  database and  schema for env {{in_sf_env}}
{{create_database_schema(in_sf_env,'GROUP_INT_DATASERVICES','SALESFORCE_DATASERVICES')}}
{{create_database_schema(in_sf_env,'GROUP_INT_DATASERVICES','OUTBOUND_SEEDS')}}
{{create_database_schema(in_sf_env,'GROUP_EXT_DATASERVICES','KAPICHE_DATASERVICES')}}
{{create_database_schema(in_sf_env,'GROUP_EXT_DATASERVICES','WESTPAC_DATASERVICES')}}
{{create_database_schema(in_sf_env,'GROUP_EXT_DATASERVICES','CBA_DATASERVICES')}}
{{create_database_schema(in_sf_env,'GROUP_EXT_DATASERVICES','ANZ_DATASERVICES')}}
{{create_database_schema(in_sf_env,'GROUP_EXT_DATASERVICES','NAB_DATASERVICES')}}
{{create_database_schema(in_sf_env,'GROUP_INT_DATASERVICES','BILLING_AND_INVOICING')}}
{{create_database_schema(in_sf_env,'GROUP_EXT_DATASERVICES','STOCKLAND_DATASERVICES')}}
{{create_database_schema(in_sf_env,'GROUP_EXT_DATASERVICES','FMS_DATASERVICES')}}
{{create_database_schema(in_sf_env,'GROUP_EXT_DATASERVICES','BENDIGO_DATASERVICES')}}
