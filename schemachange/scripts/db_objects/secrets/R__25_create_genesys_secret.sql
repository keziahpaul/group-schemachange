-- Secret Configuration that would be used for connecting to Genesys Static Link
-- NOTE: 
-- - The client credentails are stored in AWS Secret manager
-- - The secret here is created with dummy client values
-- - After deployment, we need to manually get the client credentials from AWS Secret Manager and manually update this secret object before calling the procedure
-- - Currently taking this tatical approach due to the urgency of the project delivery, stratergic solution would be automate this proceess

use role securityadmin;
grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;

use role accountadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema genesys;

EXECUTE IMMEDIATE $$
DECLARE
    secret_exists INTEGER;
BEGIN
    -- Check secret exists first
    SHOW SECRETS LIKE 'GENESYS_CREDENTIALS' IN SCHEMA {{in_sf_env}}_GROUP_RAW.genesys;
    SELECT COUNT(*) INTO :secret_exists FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    IF (secret_exists = 0) THEN
        CREATE SECRET {{ in_sf_env }}_GROUP_RAW.GENESYS.GENESYS_CREDENTIALS
        TYPE = GENERIC_STRING
        SECRET_STRING = '{
            "client_id": "xxx",
            "client_secret": "xxx",
            "static_url": "{{ genesys['static_url'] }}",
            "token_url": "{{ genesys['token_url'] }}",
            "api_url": "{{ genesys['api_url'] }}"
        }';
    END IF;
    RETURN 'SUCCESS';
END;
$$;

grant usage on secret genesys_credentials to role sysadmin;
grant usage on secret genesys_credentials to role {{ in_sf_env }}_dbt_integration_role_s;
grant usage on secret genesys_credentials to role {{ in_sf_env }}_support_f;

grant modify on secret genesys_credentials to role sysadmin;

grant read on secret genesys_credentials to role sysadmin;
grant read on secret genesys_credentials to role {{ in_sf_env }}_dbt_integration_role_s;
grant read on secret genesys_credentials to role {{ in_sf_env }}_support_f;

use role securityadmin;
revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
