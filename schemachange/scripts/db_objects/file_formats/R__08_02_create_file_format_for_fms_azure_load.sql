{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd')%}
USE ROLE SYSADMIN;


--creating  file format for sendfx test

CREATE OR REPLACE FILE FORMAT {{ in_sf_env }}_GROUP_RAW.FMS.PARQUET_FILE_FORMAT
USE_LOGICAL_TYPE = TRUE 
TYPE = PARQUET;

{% else %}
select 1;
{% endif %}
