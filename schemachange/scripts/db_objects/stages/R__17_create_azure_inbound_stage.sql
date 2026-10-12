{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}
USE ROLE SYSADMIN;


CREATE STAGE IF NOT EXISTS {{ in_sf_env }}_GROUP_RAW.SENDFX.{{ in_sf_env }}_SENDFX_AZURE_INBOUND_STAGE
STORAGE_INTEGRATION = sendfx_azure_integration
URL = '{{ sendfx_allowed_azure_path }}'
FILE_FORMAT = {{ in_sf_env }}_GROUP_RAW.SENDFX.CSV_FILE_FORMAT;

ALTER STAGE {{ in_sf_env }}_GROUP_RAW.SENDFX.{{ in_sf_env }}_SENDFX_AZURE_INBOUND_STAGE
SET
STORAGE_INTEGRATION = sendfx_azure_integration
URL = '{{ sendfx_allowed_azure_path }}'
FILE_FORMAT = {{ in_sf_env }}_GROUP_RAW.SENDFX.CSV_FILE_FORMAT; 
{% else %}
select 1;
{% endif %}