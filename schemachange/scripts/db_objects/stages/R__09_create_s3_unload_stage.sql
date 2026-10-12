{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}
USE ROLE SYSADMIN;

CREATE OR REPLACE STAGE {{ in_sf_env }}_GROUP_INT_DATASERVICES.SALESFORCE_DATASERVICES.SALESFORCE_S3_OUTBOUND_STAGE
STORAGE_INTEGRATION = group_salesforce_s3_integration
URL = '{{ allowed_s3_path }}onedata/'
FILE_FORMAT = {{ in_sf_env }}_GROUP_INT_DATASERVICES.SALESFORCE_DATASERVICES.CSV_FILE_FORMAT;

-- Points to S3 Bucket in Kapiche AWS account
USE SCHEMA {{ in_sf_env }}_GROUP_RAW.KAPICHE;
CREATE OR REPLACE STAGE {{ in_sf_env }}_KAPICHE_S3_INBOUND_STAGE
STORAGE_INTEGRATION = GROUP_KAPICHE_S3_INTEGRATION
URL = '{{ kapiche_allowed_s3_path }}data/'
FILE_FORMAT = {{ in_sf_env }}_GROUP_RAW.KAPICHE.CSV_FILE_FORMAT;

-- Points to S3 Bucket in PEXA Data AWS account for Kapiche Data rentention
CREATE STAGE IF NOT EXISTS {{ in_sf_env }}_KAPICHE_S3_ARCHIVE_STAGE
STORAGE_INTEGRATION = {{ in_sf_env }}_GROUP_KAPICHE_S3_ARCHIVE_INTEGRATION
URL = '{{ kapiche_allowed_s3_archive_path }}'
FILE_FORMAT = {{ in_sf_env }}_GROUP_RAW.KAPICHE.CSV_FILE_FORMAT;

ALTER STAGE {{ in_sf_env }}_KAPICHE_S3_ARCHIVE_STAGE
SET
STORAGE_INTEGRATION = {{ in_sf_env }}_GROUP_KAPICHE_S3_ARCHIVE_INTEGRATION
URL = '{{ kapiche_allowed_s3_archive_path }}'
FILE_FORMAT = {{ in_sf_env }}_GROUP_RAW.KAPICHE.CSV_FILE_FORMAT;

{% else %}
select 1;
{% endif %}
