{#---- removed sendfx fileformat from group script -----#}

create materialized view if not exists {{ in_sf_env }}_GROUP_RAW.SENDFX.VW_EXT_PBI_Pexa_Client_Incomplete_Applications(
        metadata_filename ,
        Business_Name   ,
        Registrations_status  ,
        Boomerang_Reason_or_Docs_Required  ,
        Domain_Email_Address  ,
        Full_Name  ,
        Registration_Account_Manager  ,
        Registration_Account_Manager_Email  ,
        Master_Registration_ID  ,
        Registration_ID  ,
        Day_of_Lead_Created_Date_AEST  ,
        ETL_INSERT_DATE_UTC  
    
     ) as
     select  
        METADATA$FILENAME as metadata_filename,
        Business_Name   ,
        Registrations_status  ,
        Boomerang_Reason_or_Docs_Required  ,
        Domain_Email_Address  ,
        Full_Name  ,
        Registration_Account_Manager  ,
        Registration_Account_Manager_Email  ,
        Master_Registration_ID ,
        Registration_ID  ,
        Day_of_Lead_Created_Date_AEST  ,
        ETL_INSERT_DATE_UTC  
    
    from {{ in_sf_env }}_GROUP_RAW.SENDFX.ext_pbi_pexa_client_incomplete_applications;



create materialized view if not exists {{ in_sf_env }}_GROUP_RAW.SENDFX.VW_EXT_PBI_Pexa_Client_Activity(
        metadata_filename ,
        ABN_ACN ,
        Affiliate_Branch  ,
        Affiliate_Employee  ,
        Business_Name  ,
        Day_of_Lead_Created_Date_AEST  ,
        Day_of_Registration_Date_AEST  ,
        Domain_Email_Address ,
        Full_Name ,
        Master_Registration_ID,
        Purpose  ,
        Registration_Account_Manager  ,
        Registration_Account_Manager_Email  ,
        Registration_Created_Source  ,
        Registration_ID  ,
        State  ,
        Min_Trade_Settled_for_Accounting_Date  ,
        Max_Trade_Settled_for_Accounting_Date  ,
        Registrations_PEXA_Opt_In_Flag  ,
        Registrations_PEXA_Opt_In_Date_AEST  ,
        ETL_INSERT_DATE_UTC  
    
     ) as
     select   
        METADATA$FILENAME as metadata_filename,
        ABN_ACN ,
        Affiliate_Branch  ,
        Affiliate_Employee  ,
        Business_Name  ,
        Day_of_Lead_Created_Date_AEST  ,
        Day_of_Registration_Date_AEST  ,
        Domain_Email_Address ,
        Full_Name ,
        Master_Registration_ID,
        Purpose  ,
        Registration_Account_Manager  ,
        Registration_Account_Manager_Email  ,
        Registration_Created_Source  ,
        Registration_ID  ,
        State  ,
        Min_Trade_Settled_for_Accounting_Date  ,
        Max_Trade_Settled_for_Accounting_Date  ,
        Registrations_PEXA_Opt_In_Flag  ,
        Registrations_PEXA_Opt_In_Date_AEST  ,
        ETL_INSERT_DATE_UTC  
    
    from {{ in_sf_env }}_GROUP_RAW.SENDFX.EXT_PBI_Pexa_Client_Activity;




create materialized view if not exists {{ in_sf_env }}_GROUP_RAW.SENDFX.VW_EXT_PBI_Pexa_PEXAAllTimeTransactionsList(
        metadata_filename ,
        ABN_ACN  ,
        Affiliate_Branch  ,
        Affiliate_Employee  ,
        BENEFICIARY_BANK_ACCOUNT_COUNTRY  ,
        Business_Name  ,
        Buy_currency  ,
        Completed_date_settlement_date  ,
        Conversion_id  ,
        Day_of_Lead_Created_Date_AEST  ,
        Day_of_Registration_Date_AEST  ,
        Domain_Email_Address  ,
        Full_Name  ,
        Master_Registration_ID  ,
        Purpose  ,
        Registration_Account_Manager  ,
        Registration_Created_Source  ,
        Registration_ID  ,
        Sell_currency  ,
        State  ,
        Pexa_commission  ,
        Settled_revenue  ,
        Settled_turnover  ,
        ETL_INSERT_DATE_UTC  
     ) as
     select   
        METADATA$FILENAME as metadata_filename,
        ABN_ACN  ,
        Affiliate_Branch  ,
        Affiliate_Employee  ,
        BENEFICIARY_BANK_ACCOUNT_COUNTRY  ,
        Business_Name  ,
        Buy_currency  ,
        Completed_date_settlement_date  ,
        Conversion_id  ,
        Day_of_Lead_Created_Date_AEST  ,
        Day_of_Registration_Date_AEST  ,
        Domain_Email_Address  ,
        Full_Name  ,
        Master_Registration_ID  ,
        Purpose  ,
        Registration_Account_Manager  ,
        Registration_Created_Source  ,
        Registration_ID  ,
        Sell_currency  ,
        State  ,
        Pexa_commission  ,
        Settled_revenue  ,
        Settled_turnover  ,
        ETL_INSERT_DATE_UTC  
    from {{ in_sf_env }}_GROUP_RAW.SENDFX.EXT_PBI_Pexa_PEXAAllTimeTransactionsList;

