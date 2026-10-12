{#---- removed sendfx fileformat from group script -----#}
CREATE  EXTERNAL TABLE IF NOT EXISTS  {{ in_sf_env }}_GROUP_RAW.SENDFX.EXT_PBI_Pexa_Client_Activity(
    ABN_ACN VARCHAR AS (value:c1::varchar),
    Affiliate_Branch  VARCHAR AS (value:c2::varchar) ,
    Affiliate_Employee  VARCHAR AS (value:c3::varchar) ,
    Business_Name  VARCHAR AS (value:c4::varchar) ,
    Day_of_Lead_Created_Date_AEST  VARCHAR AS (value:c5::varchar) ,
    Day_of_Registration_Date_AEST  VARCHAR AS (value:c6::varchar) ,
    Domain_Email_Address VARCHAR AS (value:c7::varchar) ,
    Full_Name VARCHAR AS (value:c8::varchar) ,
    Master_Registration_ID VARCHAR AS (value:c9::varchar) ,
    Purpose  VARCHAR AS (value:c10::varchar) ,
    Registration_Account_Manager  VARCHAR AS (value:c11::varchar) ,
    Registration_Account_Manager_Email  VARCHAR AS (value:c12::varchar) ,
    Registration_Created_Source  VARCHAR AS (value:c13::varchar) ,
    Registration_ID  VARCHAR AS (value:c14::varchar) ,
    State  VARCHAR AS (value:c15::varchar) ,
    Min_Trade_Settled_for_Accounting_Date  VARCHAR AS (value:c16::varchar) ,
    Max_Trade_Settled_for_Accounting_Date  VARCHAR AS (value:c17::varchar) ,
    Registrations_PEXA_Opt_In_Flag  VARCHAR AS (value:c18::varchar) ,
    Registrations_PEXA_Opt_In_Date_AEST  VARCHAR AS (value:c19::varchar) ,
    ETL_INSERT_DATE_UTC  VARCHAR AS (value:c20::varchar)
)
PATTERN='VW_PBI_Pexa_Client_Activity.csv'
LOCATION=@{{ in_sf_env }}_GROUP_RAW.SENDFX.{{ in_sf_env }}_SENDFX_AZURE_INBOUND_STAGE
AUTO_REFRESH = FALSE
FILE_FORMAT = ( FORMAT_NAME = {{ in_sf_env }}_GROUP_RAW.SENDFX.CSV_FILE_FORMAT )
;


CREATE  EXTERNAL TABLE IF NOT EXISTS  {{ in_sf_env }}_GROUP_RAW.SENDFX.EXT_PBI_Pexa_PEXAAllTimeTransactionsList(
    ABN_ACN  VARCHAR AS (value:c1::varchar) ,
    Affiliate_Branch  VARCHAR AS (value:c2::varchar) ,
    Affiliate_Employee  VARCHAR AS (value:c3::varchar) ,
    BENEFICIARY_BANK_ACCOUNT_COUNTRY  VARCHAR AS (value:c4::varchar) ,
    Business_Name  VARCHAR AS (value:c5::varchar) ,
    Buy_currency  VARCHAR AS (value:c6::varchar) ,
    Completed_date_settlement_date  VARCHAR AS (value:c7::varchar) ,
    Conversion_id  VARCHAR AS (value:c8::varchar) ,
    Day_of_Lead_Created_Date_AEST  VARCHAR AS (value:c9::varchar) ,
    Day_of_Registration_Date_AEST  VARCHAR AS (value:c10::varchar) ,
    Domain_Email_Address  VARCHAR AS (value:c11::varchar) ,
    Full_Name  VARCHAR AS (value:c12::varchar) ,
    Master_Registration_ID  VARCHAR AS (value:c13::varchar) ,
    Purpose  VARCHAR AS (value:c14::varchar) ,
    Registration_Account_Manager  VARCHAR AS (value:c15::varchar) ,
    Registration_Created_Source  VARCHAR AS (value:c16::varchar) ,
    Registration_ID  VARCHAR AS (value:c17::varchar) ,
    Sell_currency  VARCHAR AS (value:c18::varchar) ,
    State  VARCHAR AS (value:c19::varchar) ,
    Pexa_commission  VARCHAR AS (value:c20::varchar) ,
    Settled_revenue  VARCHAR AS (value:c21::varchar) ,
    Settled_turnover  VARCHAR AS (value:c22::varchar) ,
    ETL_INSERT_DATE_UTC  VARCHAR AS (value:c23::varchar) 
    

)
LOCATION=@{{ in_sf_env }}_GROUP_RAW.SENDFX.{{ in_sf_env }}_SENDFX_AZURE_INBOUND_STAGE
PATTERN='VW_PBI_Pexa_PEXAAllTimeTransactionsList.csv'
AUTO_REFRESH = FALSE
FILE_FORMAT =( FORMAT_NAME = {{ in_sf_env }}_GROUP_RAW.SENDFX.CSV_FILE_FORMAT )
;


CREATE  EXTERNAL TABLE IF NOT EXISTS  {{ in_sf_env }}_GROUP_RAW.SENDFX.EXT_PBI_Pexa_Client_Incomplete_Applications(
    Business_Name  VARCHAR AS (value:c1::varchar) ,
    Registrations_status  VARCHAR AS (value:c2::varchar) ,
    Boomerang_Reason_or_Docs_Required  VARCHAR AS (value:c3::varchar) ,
    Domain_Email_Address  VARCHAR AS (value:c4::varchar) ,
    Full_Name  VARCHAR AS (value:c5::varchar) ,
    Registration_Account_Manager  VARCHAR AS (value:c6::varchar) ,
    Registration_Account_Manager_Email  VARCHAR AS (value:c7::varchar) ,
    Master_Registration_ID  VARCHAR AS (value:c8::varchar) ,
    Registration_ID  VARCHAR AS (value:c9::varchar) ,
    Day_of_Lead_Created_Date_AEST  VARCHAR AS (value:c10::varchar) ,
    ETL_INSERT_DATE_UTC  VARCHAR AS (value:c11::varchar) 
)
LOCATION=@{{ in_sf_env }}_GROUP_RAW.SENDFX.{{ in_sf_env }}_SENDFX_AZURE_INBOUND_STAGE
PATTERN='VW_PBI_Pexa_Client_Incomplete_Applications.csv'
AUTO_REFRESH = FALSE
FILE_FORMAT =( FORMAT_NAME = {{ in_sf_env }}_GROUP_RAW.SENDFX.CSV_FILE_FORMAT )
;