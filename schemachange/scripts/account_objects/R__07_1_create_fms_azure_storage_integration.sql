{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or  (in_sf_env.lower() == 'prd') %}

--create storage integration for FMS
use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
CREATE STORAGE INTEGRATION IF NOT EXISTS fms_azure_integration
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = AZURE
ENABLED = TRUE
AZURE_TENANT_ID = '{{ fms_azure_tenant_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ fms_allowed_azure_path }}');

ALTER STORAGE INTEGRATION fms_azure_integration
SET
AZURE_TENANT_ID = '{{ fms_azure_tenant_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ fms_allowed_azure_path }}');

CREATE NOTIFICATION INTEGRATION IF NOT EXISTS fms_azure_notification_integration
  ENABLED = true
  TYPE = QUEUE
  NOTIFICATION_PROVIDER = AZURE_STORAGE_QUEUE
  AZURE_STORAGE_QUEUE_PRIMARY_URI = '{{ fms_azure_primary_storage_queue }}'
  AZURE_TENANT_ID = '{{ fms_azure_tenant_id }}';




grant usage on integration fms_azure_integration to role sysadmin;
grant usage on integration fms_azure_integration to role {{ in_sf_env }}_dbt_integration_role_s;

grant usage on integration fms_azure_notification_integration to role sysadmin;
grant usage on integration fms_azure_notification_integration to role {{ in_sf_env }}_dbt_integration_role_s;


use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
{% else %}
select 1;
{% endif %}