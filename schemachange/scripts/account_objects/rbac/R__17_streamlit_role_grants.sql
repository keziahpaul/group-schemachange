USE ROLE securityadmin;

--PROD-SNOWFLAKE-AU-STREAMLIT-REG-AFFAIRS and PROD-SNOWFLAKE-AU-STREAMLIT-CUST-SUPPORT-LEGAL are okta created roles
{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') %} 

    grant role {{in_sf_env}}_REG_AFFAIRS_F to role "NON-PROD-SNOWFLAKE-AU-STREAMLIT-REG-AFFAIRS";
    grant role {{in_sf_env}}_CUST_SUPPORT_LEGAL_F to role "NON-PROD-SNOWFLAKE-AU-STREAMLIT-CUST-SUPPORT-LEGAL";

{% elif (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}

    grant role {{in_sf_env}}_REG_AFFAIRS_F to role "PROD-SNOWFLAKE-AU-STREAMLIT-REG-AFFAIRS";
    grant role {{in_sf_env}}_CUST_SUPPORT_LEGAL_F to role "PROD-SNOWFLAKE-AU-STREAMLIT-CUST-SUPPORT-LEGAL";

{%endif%}
