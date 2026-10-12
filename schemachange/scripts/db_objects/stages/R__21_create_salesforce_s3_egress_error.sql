{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}
USE ROLE SYSADMIN;

CREATE OR REPLACE STAGE {{ in_sf_env }}_GROUP_INT_DATASERVICES.SALESFORCE_DATASERVICES.SALESFORCE_S3_EGRESS_ERRORS
STORAGE_INTEGRATION = group_salesforce_s3_integration
URL = '{{ allowed_s3_path }}egress-errors/'
FILE_FORMAT = {{ in_sf_env }}_GROUP_INT_DATASERVICES.SALESFORCE_DATASERVICES.CSV_FILE_FORMAT;


{% else %}
select 1;
{% endif %}