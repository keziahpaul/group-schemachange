{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}
USE ROLE SYSADMIN;


CREATE OR REPLACE STAGE {{ in_sf_env }}_GROUP_EXT_DATASERVICES.KAPICHE_DATASERVICES.{{ in_sf_env }}_KAPICHE_S3_OUTBOUND_STAGE
STORAGE_INTEGRATION = GROUP_KAPICHE_S3_INTEGRATION
URL = '{{ kapiche_allowed_s3_path }}onedata_outbound/'
FILE_FORMAT = {{ in_sf_env }}_GROUP_EXT_DATASERVICES.KAPICHE_DATASERVICES.CSV_FILE_FORMAT;
{% else %}
select 1;
{% endif %}