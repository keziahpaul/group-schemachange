{% from 'modules/create_roles_and_grant_read_only.j2' import create_roles_and_grant_read_only-%}

use database {{ in_sf_env }}_GOVERNANCE_DB;
use schema COMPLIANCE;
-- CUST_INSIGHTS_F
{{ create_roles_and_grant_read_only(in_sf_env~"_CUST_INSIGHTS_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_CURATE", 'KAPICHE') }}
{{ create_roles_and_grant_read_only(in_sf_env~"_CUST_INSIGHTS_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_EXT_DATASERVICES", 'KAPICHE_DATASERVICES') }}

-- SALES_OPERATIONS_F
{{ create_roles_and_grant_read_only(in_sf_env~"_SALES_OPERATIONS_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_INT_DATASERVICES", 'SALESFORCE_DATASERVICES') }}

-- FINANCE_BILLING_VIEWER_F
{{ create_roles_and_grant_read_only(in_sf_env~"_FINANCE_BILLING_VIEWER_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_INT_DATASERVICES", 'SALESFORCE_DATASERVICES') }}

-- _FINANCE_BILLING_VIEWER_F
grant usage on warehouse {{ in_sf_env }}_DEVELOPER_XS_WH to role {{ in_sf_env }}_FINANCE_BILLING_VIEWER_F;
-- all three db roles usage_viewer, organization_billing_viewer & governance_viewer must be granted in order to view cost information in Snowsight
-- https://docs.snowflake.com/en/user-guide/cost-exploring-overall#granting-access-to-cost-and-usage-data
grant database role SNOWFLAKE.USAGE_VIEWER to role {{ in_sf_env }}_FINANCE_BILLING_VIEWER_F;
grant database role SNOWFLAKE.ORGANIZATION_BILLING_VIEWER to role {{ in_sf_env }}_FINANCE_BILLING_VIEWER_F;
grant database role SNOWFLAKE.GOVERNANCE_VIEWER to role {{ in_sf_env }}_FINANCE_BILLING_VIEWER_F;
grant database role SNOWFLAKE.OBJECT_VIEWER to role {{ in_sf_env }}_FINANCE_BILLING_VIEWER_F;

-- Streamlit roles
-- FIN_RISK_COMPLIANCE_F
{{ create_roles_and_grant_read_only(in_sf_env~"_FIN_RISK_COMPLIANCE_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_SANDBOX", 'DS_SANDBOX') }}

-- ACCT_MGMT_FI_F
{{ create_roles_and_grant_read_only(in_sf_env~"_ACCT_MGMT_FI_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}

-- ACCT_MGMT_PRACTITIONERS_F
{{ create_roles_and_grant_read_only(in_sf_env~"_ACCT_MGMT_PRACTITIONERS_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}

-- PEXA_PRODUCTS_F
{{ create_roles_and_grant_read_only(in_sf_env~"_PEXA_PRODUCTS_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}

-- PEXA_FEATURES_F
{{ create_roles_and_grant_read_only(in_sf_env~"_PEXA_FEATURES_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}

-- CUST_SUPPORT_F
{{ create_roles_and_grant_read_only(in_sf_env~"_CUST_SUPPORT_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}

-- MARKETING_F
{{ create_roles_and_grant_read_only(in_sf_env~"_MARKETING_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}

-- FIN_ENTERPRISE_F
{{ create_roles_and_grant_read_only(in_sf_env~"_FIN_ENTERPRISE_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}

-- CUST_SUPPORT_LEGAL_F
{{ create_roles_and_grant_read_only(in_sf_env~"_CUST_SUPPORT_LEGAL_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}

-- REG_AFFAIRS_F
{{ create_roles_and_grant_read_only(in_sf_env~"_REG_AFFAIRS_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_SELFSERVICE_ANALYTICS", 'EXCHANGE') }}


use role useradmin;
-- SALES UPLIFT USER
create user if not exists {{ in_sf_env }}_SALES_OPERATION_USER;

{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'prd') %}
    alter user {{ in_sf_env }}_SALES_OPERATION_USER set EMAIL = {{ params_dict['send_alert_slack_email'] }} ;

    alter user {{ in_sf_env }}_SALES_OPERATION_USER set password=null;
{%else%}
    select 1 ;
{%endif%}

USE ROLE {{ in_sf_env }}_GITHUB_INTEGRATION_ROLE_S;
-- SALES_OPERATION_WRITE_F
 --comment to rerun
{{ create_roles_and_grant_read_only(in_sf_env~"_SALES_OPERATION_WRITE_F", in_sf_env~"_DEVELOPER_XS_WH", in_sf_env~"_GROUP_INT_DATASERVICES", 'SALESFORCE_DATASERVICES') }}

{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') %} 
    grant role {{ in_sf_env }}_SALES_OPERATION_WRITE_F to role "NON-PROD-SNOWFLAKE-GROUP-SALES-OPERATIONS-WRITER";
{% elif (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}
    grant role {{ in_sf_env }}_SALES_OPERATION_WRITE_F to role "PROD-SNOWFLAKE-GROUP-SALES-OPERATIONS-WRITER";
{%else%}
  select 1; 
{%endif%}
select 1;