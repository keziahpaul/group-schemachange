{% from 'modules/create_access_roles_privileges.j2' import create_access_roles_privileges-%}

--creating RBACs for env {{in_sf_env}}
{{create_access_roles_privileges(in_sf_env,'GROUP_INT_DATASERVICES','SALESFORCE_DATASERVICES','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_EXT_DATASERVICES','KAPICHE_DATASERVICES','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_EXT_DATASERVICES','CBA_DATASERVICES','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_EXT_DATASERVICES','WESTPAC_DATASERVICES','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_EXT_DATASERVICES','ANZ_DATASERVICES','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_EXT_DATASERVICES','NAB_DATASERVICES','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_INT_DATASERVICES','BILLING_AND_INVOICING','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_EXT_DATASERVICES','STOCKLAND_DATASERVICES','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_EXT_DATASERVICES','FMS_DATASERVICES','all','TRN_XS_WH')}}
{{create_access_roles_privileges(in_sf_env,'GROUP_EXT_DATASERVICES','BENDIGO_DATASERVICES','all','TRN_XS_WH')}}

