{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}
USE ROLE SYSADMIN;
 
--stage

CREATE OR REPLACE STAGE {{ in_sf_env }}_GROUP_RAW.SALESFORCE.{{ in_sf_env }}_INGRESS_SALESFORCE_INBOUND_STAGE
STORAGE_INTEGRATION = {{in_sf_env}}_GROUP_INGRESS_S3_INTEGRATION
URL = '{{ ingress_allowed_s3_path }}salesforce/inbound/'
FILE_FORMAT = {{ in_sf_env }}_GROUP_RAW.SALESFORCE.JSON_FILE_FORMAT;




{% else %}
select 1;
{% endif %}