{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}
USE ROLE SYSADMIN;


CREATE STAGE IF NOT EXISTS {{ in_sf_env }}_GROUP_RAW.FMS.FMS_AZURE_INBOUND_STAGE
STORAGE_INTEGRATION = fms_azure_integration
URL = '{{ fms_allowed_azure_path }}'
FILE_FORMAT = {{ in_sf_env }}_GROUP_RAW.FMS.PARQUET_FILE_FORMAT;

ALTER STAGE {{ in_sf_env }}_GROUP_RAW.FMS.FMS_AZURE_INBOUND_STAGE
SET
STORAGE_INTEGRATION = fms_azure_integration
URL = '{{ fms_allowed_azure_path }}'
FILE_FORMAT = {{ in_sf_env }}_GROUP_RAW.FMS.PARQUET_FILE_FORMAT; 

{% else %}
select 1;
{% endif %}