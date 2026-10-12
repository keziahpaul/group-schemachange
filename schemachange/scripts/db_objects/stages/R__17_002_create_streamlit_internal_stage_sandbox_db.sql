{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}
USE ROLE SYSADMIN;


CREATE OR REPLACE STAGE {{ in_sf_env }}_SANDBOX.DE_SANDBOX.{{ in_sf_env }}_STREAMLIT_APPS;
CREATE OR REPLACE STAGE {{ in_sf_env }}_SANDBOX.DI_SANDBOX.{{ in_sf_env }}_STREAMLIT_APPS;

{% else %}
select 1;
{% endif %}