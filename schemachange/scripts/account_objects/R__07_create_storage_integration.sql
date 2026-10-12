{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'prd') %}

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
CREATE STORAGE INTEGRATION IF NOT EXISTS group_salesforce_s3_integration
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{{ aws_account_number }}:role/pexa-one-data-group-snowflake-access'
STORAGE_AWS_EXTERNAL_ID = '{{ aws_external_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ allowed_s3_path }}');

ALTER STORAGE INTEGRATION group_salesforce_s3_integration
SET
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{{ aws_account_number }}:role/pexa-one-data-group-snowflake-access'
STORAGE_AWS_EXTERNAL_ID = '{{ aws_external_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ allowed_s3_path }}');

CREATE STORAGE INTEGRATION IF NOT EXISTS GROUP_KAPICHE_S3_INTEGRATION
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{{ kapiche_aws_account_number }}:role/{{ kapiche_aws_role }}'
STORAGE_AWS_EXTERNAL_ID = '{{ kapiche_aws_external_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ kapiche_allowed_s3_path }}');

-- Helpful in future if we ever need to update details of the storage integration - just change the params in config
-- if original storage integration is dropped and re-created it will break the entire integration
-- therefor alter statement will help future proof that
ALTER STORAGE INTEGRATION GROUP_KAPICHE_S3_INTEGRATION
SET
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::{{ kapiche_aws_account_number }}:role/{{ kapiche_aws_role }}'
STORAGE_AWS_EXTERNAL_ID = '{{ kapiche_aws_external_id }}'
STORAGE_ALLOWED_LOCATIONS = ('{{ kapiche_allowed_s3_path }}');

grant usage on integration group_salesforce_s3_integration to role sysadmin;
grant usage on integration group_salesforce_s3_integration to role {{ in_sf_env }}_dbt_integration_role_s;

grant usage on integration GROUP_KAPICHE_S3_INTEGRATION to role sysadmin;
grant usage on integration GROUP_KAPICHE_S3_INTEGRATION to role {{ in_sf_env }}_dbt_integration_role_s;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
{% else %}
select 1;
{% endif %}