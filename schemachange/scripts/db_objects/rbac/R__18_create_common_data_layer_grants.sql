{% from 'modules/create_access_roles_privileges.j2' import create_access_roles_privileges-%}

--creating RBACs for env {{in_sf_env}}
{{create_access_roles_privileges(in_sf_env,'GROUP_COMMON_DATA_LAYER','CDM','all','TRN_XS_WH')}}

--creating RBACs for ODS in env {{in_sf_env}}
{{create_access_roles_privileges(in_sf_env,'GROUP_COMMON_DATA_LAYER','ODS','all','TRN_XS_WH')}}