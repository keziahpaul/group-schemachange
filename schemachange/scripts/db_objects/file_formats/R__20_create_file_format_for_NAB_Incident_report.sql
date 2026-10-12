{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}
USE ROLE SYSADMIN;

CREATE OR REPLACE FILE FORMAT {{ in_sf_env }}_GROUP_EXT_DATASERVICES.NAB_DATASERVICES.CSV_FILE_FORMAT
TYPE = CSV
COMPRESSION = NONE
TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS.FF9 TZHTZM'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
NULL_IF = ('');


{% else %}
select 1;
{% endif %}
