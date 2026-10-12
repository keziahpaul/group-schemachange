{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd')%}
USE ROLE SYSADMIN;


--creating  file format for sendfx test

CREATE OR REPLACE FILE FORMAT {{ in_sf_env }}_GROUP_RAW.SENDFX.CSV_FILE_FORMAT
TYPE = CSV
FIELD_DELIMITER = ','
FIELD_OPTIONALLY_ENCLOSED_BY = '\"'
RECORD_DELIMITER = '\n'
SKIP_HEADER = 1
NULL_IF = ('') 
TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF9 TZHTZM'
ESCAPE = 'NONE'
COMPRESSION = none;

{% else %}
select 1;
{% endif %}
