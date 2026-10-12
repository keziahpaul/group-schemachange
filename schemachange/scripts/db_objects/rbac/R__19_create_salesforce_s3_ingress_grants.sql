{% from 'modules/create_access_roles_privileges.j2' import create_access_roles_privileges-%}

--creating RBACs for env {{in_sf_env}}
{{create_access_roles_privileges(in_sf_env,'GROUP_RAW', "SALESFORCE",'all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_STAGE', "SALESFORCE",'all','TRN_XS_WH')}}