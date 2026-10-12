
{% from 'modules/create_warehouse.j2' import create_warehouse-%}
{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'tst') or (in_sf_env.lower() == 'prd') %}

--below values need to be updated based on every streamlit app
{% set streamlit_database = in_sf_env + "_sandbox" %}
{% set streamlit_schema = "de_sandbox" %}
{% set streamlit_app = "dbt_cloud_api" %}
-- Choose one of the tag values below to set it to the warehouse
-- ( 'Account management','Account management practitioners','Pexa products','Pexa features','Customer support','Marketing','Enterprise','Data engineering','Data science' )
{% set tag_value = "Data engineering" %}


use role sysadmin;
use database {{streamlit_database}};
use schema {{streamlit_schema}};
--creating  warehouse for streamlit app 
{% set streamlit_app_wh = in_sf_env+"_"+streamlit_app+"_xs_wh" %}
{% set streamlit_stage_location = in_sf_env + "_streamlit_apps/"+streamlit_app %}
{% set tag_db_schema = in_sf_env + "_governance_db.compliance" %}

create warehouse if not exists {{streamlit_app_wh}}
  warehouse_type =  standard , 
  warehouse_size =  XSMALL  ,
  max_cluster_count = 1,
  min_cluster_count = 1,
  scaling_policy =  standard  ,
  auto_suspend =  60  ,
  auto_resume =  true  ,
  initially_suspended =  true  ,
  comment = 'This warehouse used by dbt_cloud_api streamli app' ;
alter warehouse {{streamlit_app_wh}} set tag {{tag_db_schema}}.streamlit= '{{tag_value}}';

--create streamlit
create streamlit if not exists {{ streamlit_app }} root_location = '@{{streamlit_stage_location}}' main_file = '/streamlit_main.py'
query_warehouse = {{streamlit_app_wh}};

--grant usage access to warehouse
use role securityadmin;
grant usage on warehouse {{streamlit_app_wh}} to role {{ in_sf_env }}_support_f;

{% else %}
select 1;
{% endif %}