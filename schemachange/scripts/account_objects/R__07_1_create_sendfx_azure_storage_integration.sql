{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}

--create storage integration for sendfx
use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
CREATE STORAGE INTEGRATION IF NOT EXISTS sendfx_azure_integration
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = AZURE
ENABLED = TRUE
AZURE_TENANT_ID = '{{ sendfx_azure_tenant_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ sendfx_allowed_azure_path }}');

ALTER STORAGE INTEGRATION sendfx_azure_integration
SET
AZURE_TENANT_ID = '{{ sendfx_azure_tenant_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ sendfx_allowed_azure_path }}');



grant usage on integration sendfx_azure_integration to role sysadmin;
grant usage on integration sendfx_azure_integration to role {{ in_sf_env }}_dbt_integration_role_s;


use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
{% else %}
select 1;
{% endif %}