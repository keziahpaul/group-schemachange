-- seperated this into its own file as Bespoke outbound does not have PST

{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
CREATE STORAGE INTEGRATION IF NOT EXISTS {{in_sf_env}}_GROUP_BESPOKE_S3_INTEGRATION
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{{ aws_account_number }}:role/onedata-bespoke-snowflake-integration-role-{{in_sf_env}}'
STORAGE_AWS_EXTERNAL_ID = '{{ bespoke_aws_external_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ bespoke_allowed_s3_path }}');

ALTER STORAGE INTEGRATION {{in_sf_env}}_GROUP_BESPOKE_S3_INTEGRATION
SET
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{{ aws_account_number }}:role/onedata-bespoke-snowflake-integration-role-{{in_sf_env}}'
STORAGE_AWS_EXTERNAL_ID = '{{ bespoke_aws_external_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ bespoke_allowed_s3_path }}');

grant usage on integration {{in_sf_env}}_GROUP_BESPOKE_S3_INTEGRATION to role sysadmin;
grant usage on integration {{in_sf_env}}_GROUP_BESPOKE_S3_INTEGRATION to role {{ in_sf_env }}_dbt_integration_role_s;
grant usage on integration {{in_sf_env}}_GROUP_BESPOKE_S3_INTEGRATION to role {{ in_sf_env }}_ssa_dbt_integration_role_s;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
{% else %}
select 1;
{% endif %}