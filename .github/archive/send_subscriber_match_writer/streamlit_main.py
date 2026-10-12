# Import python packages
import streamlit as st
import uuid
import pandas as pd
from streamlit import session_state as ss
from pandas.api.types import is_categorical_dtype
import re
import time

st.set_page_config(layout="wide")
st.title("Send Subscriber Manual Registry")
session = st.connection('snowflake').session()
current_db = session.sql("select CURRENT_DATABASE()").collect()
current_env = current_db[0][0][:3] 
user_email = st.user.email
if current_env =="PRD" or current_env == "PST" :
    exchange_db = 'EXCHANGE_INBOUND_DATASHARING'
else:
    exchange_db ='NONPROD_EXCHANGE_DATA_SHARE'
    

#https://blog.streamlit.io/auto-generate-a-dataframe-filtering-ui-in-streamlit-with-filter_dataframe/
def filter_dataframe(df,key):
    """
    Adds a UI on top of a dataframe to let viewers filter columns

    Args:
        df (pd.DataFrame): Original dataframe

    Returns:
        pd.DataFrame: Filtered dataframe
    """
    modify = st.checkbox("Add filters",key=key)

    if not modify:
        return df

    df = df.copy()

    modification_container = st.container()

    with modification_container:
        to_filter_columns = st.multiselect("Filter data on", df.columns)
        for column in to_filter_columns:
            left, right = st.columns((1,35))
            left.write("↳")
            # Treat columns with < 10 unique values as categorical
            if is_categorical_dtype(df[column]) or df[column].nunique() < 10:
                user_cat_input = right.multiselect(
                    f"Values for {column}",
                    df[column].unique(),
                    default=list(df[column].unique()),
                )
                df = df[df[column].isin(user_cat_input)]
  
            else:
                user_text_input = right.text_input(
                    f"Search for a substring in {column}",
                )
                if user_text_input:
                    df = df[df[column].astype(str).str.contains(user_text_input,flags=re.IGNORECASE)]

    return df


def get_unmatched(_session):
    query = """ select master_registration_id,
    match_method,
    subscriber_id::varchar as subscriber_id,
    REGISTRATION_CREATED_SOURCE,abn_acn, business_name,full_name, 
    registration_account_manager,DAY_OF_REGISTRATION_DATE_AEST,
    AFFILIATE_BRANCH,AFFILIATE_EMPLOYEE, DOMAIN_EMAIL_ADDRESS
    from SEND_SUBSCRIBER_MATCH_EXCEPTION
    QUALIFY ROW_NUMBER() OVER (PARTITION BY MASTER_REGISTRATION_ID ORDER BY Registration_created_source desc) =1
    """
    data = _session.sql(query).collect()
    return data

def get_manual_matched(_session):
    query = """
    select p.Registration_id,
    REGISTRATION_CREATED_SOURCE, match_method, 
    subscriber_id::varchar as subscriber_id,
    abn_acn, business_name,full_name, 
    registration_account_manager,DAY_OF_REGISTRATION_DATE_AEST,
    AFFILIATE_BRANCH,AFFILIATE_EMPLOYEE, DOMAIN_EMAIL_ADDRESS,
    m.inserted_at as created_at,
    m.inserted_by as created_by,
    m.updated_at as last_modified_at,
    m.updated_by as last_modified_by
    from SEND_SUBSCRIBER_MATCH_PROCESS p
    inner join manual_send_subscriber_match m
    on p.registration_id = m.registration_id
    where lower(match_method) in ('orphan', 'cannot match', 'referral','manual')
    """
    data = _session.sql(query).collect()
    return data

def get_cannot_be_matched(_session):
    query = """
    select Registration_id,
    REGISTRATION_CREATED_SOURCE, match_method, 
    subscriber_id::varchar as subscriber_id,
    abn_acn, business_name,full_name, 
    registration_account_manager,DAY_OF_REGISTRATION_DATE_AEST,
    AFFILIATE_BRANCH,AFFILIATE_EMPLOYEE, DOMAIN_EMAIL_ADDRESS
    from SEND_SUBSCRIBER_MATCH_PROCESS
    where lower(match_method) in ('orphan', 'cannot match')
    """
    data = _session.sql(query).collect()
    return data
    
def get_referral(_session):
    query = """
    select master_registration_id,
    match_method,
    subscriber_id::varchar as subscriber_id,
    REGISTRATION_CREATED_SOURCE,abn_acn, business_name,full_name, 
    registration_account_manager,DAY_OF_REGISTRATION_DATE_AEST,
    AFFILIATE_BRANCH,AFFILIATE_EMPLOYEE, DOMAIN_EMAIL_ADDRESS
    from SEND_SUBSCRIBER_MATCH_PROCESS
    where lower(match_method) in ('referral')
    and subscriber_id is null
    QUALIFY ROW_NUMBER() OVER (PARTITION BY MASTER_REGISTRATION_ID ORDER BY Registration_created_source desc) =1
    """
    data = _session.sql(query).collect()
    return data

def get_transactions_by_inactive_subscribers(_session):
    query = """
    select m.master_registration_id,
    m.match_method,
    m.subscriber_id::varchar as subscriber_id,
    m.REGISTRATION_CREATED_SOURCE,abn_acn, business_name,full_name, 
    m.registration_account_manager,DAY_OF_REGISTRATION_DATE_AEST,
    m.AFFILIATE_BRANCH,m.AFFILIATE_EMPLOYEE, m.DOMAIN_EMAIL_ADDRESS
    from SEND_TRANSACTION_DETAILS t
    inner join SEND_SUBSCRIBER_MATCH_PROCESS m
    on t.registration_id = m.registration_id
    inner join """ + exchange_db+""".exchange.vw_subscribers s
    on t.subscriber_id = s.subscriber_id
    where upper(s.status) not in ('ACTIVE')
    and t.completed_date_settlement_date > add_months(current_date,-3)
    """
    data = _session.sql(query).collect()
    return data


def update_sub_match_process_query(row):
    return f"""update send_subscriber_match_process p
        set p.match_method = m.MATCH_STATUS
        , p.subscriber_id = m.MANUAL_SUB_ID
        , p.subscriber_status= m.SUBSCRIBER_STATUS
        , p.updated_at = convert_timezone('Australia/Melbourne', current_timestamp)::timestamp_ntz
        from manual_send_subscriber_match m
        where p.registration_id=m.REGISTRATION_ID
        and p.master_registration_id = '{row['master_registration_id']}' """

def rebuild_excpetion_query():
    return f"""
    create or replace table send_subscriber_match_exception
    as (
        select  s.ABN_ACN,
        s.Affiliate_Branch,
        s.Affiliate_Employee,
        s.Business_Name,
        s.Day_of_Lead_Created_Date_AEST,
        s.Day_of_Registration_Date_AEST,
        s.Domain_Email_Address,
        s.Full_Name,
        s.Master_Registration_ID,
        s.Purpose,
        s.Registration_Account_Manager,
        s.Registration_Created_Source,
        s.Registration_ID,
        s.State,
        s.Max_Trade_Settled_for_Accounting_Date,
        s.Min_Trade_Settled_for_Accounting_Date,
        s.registrations_pexa_opt_in_flag,
        s.Registrations_PEXA_Opt_In_Date_AEST,
        s.subscriber_id,
        s.match_method,
        s.subscriber_status
    from send_subscriber_match_process s
    where match_method in ('duplicate registrations', 'duplicate subscribers', 'no_match','new registration for existing subscriber')
    )
    """
def delete_from_execption_query(row):
    return f"""DELETE FROM send_subscriber_match_exception
    WHERE master_registration_id = '{row['master_registration_id']}'"""

def add_row_to_db(session, row):
    sql = f"""INSERT INTO manual_send_subscriber_match (REGISTRATION_ID, MANUAL_SUB_ID, INSERTED_AT, INSERTED_BY, UPDATED_AT, UPDATED_BY, MATCH_STATUS, SUBSCRIBER_STATUS)
    SELECT registration_id,
    TRY_TO_NUMBER('{row['subscriber_id']}'),
    convert_timezone('Australia/Melbourne', current_timestamp)::timestamp_ntz,
    '{user_email}',
    convert_timezone('Australia/Melbourne', current_timestamp)::timestamp_ntz,
    '{user_email}',
    '{row['status']}',
    (
        SELECT v.status
        FROM """+exchange_db+f""".exchange.vw_subscribers v
        WHERE v.subscriber_id = TRY_TO_NUMBER('{row['subscriber_id']}')
    ) AS status
    from send_subscriber_match_process p 
    where master_registration_id ='{row['master_registration_id']}'
    """

      
    update_sql = update_sub_match_process_query(row)


    delete_sql=delete_from_execption_query(row)

    session.sql(sql).collect()
    session.sql(update_sql).collect()
    session.sql(delete_sql).collect()


def update_row_to_db(session, row):
    sql = f"""UPDATE manual_send_subscriber_match set
    manual_sub_id = TRY_TO_NUMBER('{row['subscriber_id']}'),
    match_status ='{row['status']}',
    subscriber_status = case when '{row['subscriber_id']}' = '' then NULL else 'ACTIVE' end,
    updated_at=convert_timezone('Australia/Melbourne', current_timestamp)::timestamp_ntz,
    updated_by=current_user
    where registration_id = ('{row['registration_id']}'
    )"""

    update_sql = update_sub_match_process_query(row)


   # rebuild_sql=rebuild_excpetion_query()

    session.sql(sql).collect()
    session.sql(update_sql).collect()
    #session.sql(rebuild_sql).collect()

def check_subscriber_exist(session, sub_id):
    query = f"""
         SELECT  exists (select subscriber_id from """ + exchange_db+ f""".exchange.vw_subscribers 
         where subscriber_id ='{sub_id}')"""
    data = session.sql(query).collect()
    return data

def check_valid_subscriber(session, sub_id):
    
    query = f"""
         SELECT  exists (select subscriber_id from """ + exchange_db+ f""".exchange.vw_subscribers where subscriber_id ='{sub_id}'
         and status ='ACTIVE'
         )"""
    data = session.sql(query).collect()
    return data

def check_rego_id(session, reg_id):
    query = f"""
     SELECT  exists (select registration_id from SEND_SUBSCRIBER_MATCH_EXCEPTION where registration_id ='{reg_id}'
     )"""
    data = session.sql(query).collect()
    return data
    
def check_dup_sub(session, sub_id):
    query = f"""
     SELECT  exists (select manual_sub_id from manual_send_subscriber_match where manual_sub_id ='{sub_id}'
     union all 
     select subscriber_id from send_subscriber_match_process where subscriber_id ='{sub_id}' 
     and match_method not in ('new registration for existing subscriber','no_match','duplicate registrations')
     )"""
    data = session.sql(query).collect()
    return data

def check_dup_sub_update(session, sub_id):
    query = f"""
     SELECT  exists (select manual_sub_id from manual_send_subscriber_match where manual_sub_id ='{sub_id}'
     union all 
     select subscriber_id from send_subscriber_match_process where subscriber_id ='{sub_id}'
     )"""
    data = session.sql(query).collect()
    return data
    
df_unmatched = pd.DataFrame(get_unmatched(session))
df_manual_matched = pd.DataFrame(get_manual_matched(session))
df_cannot_match = pd.DataFrame(get_cannot_be_matched(session))
df_referral = pd.DataFrame(get_referral(session))
df_terminated_sub_tran = pd.DataFrame(get_transactions_by_inactive_subscribers(session))

if 'dfk' not in ss:
    ss.dfk = str(uuid.uuid4())


def execute_cb(sinfo):
    """Change the dataframe key.
    
    This is called when the button with execute label
    is clicked. The dataframe key is changed to unselect rows on it.
    """
    # print(sinfo)
    
    ss.dfk = str(uuid.uuid4())
    


expander = st.expander("INSERT MANUAL MAPPINGS - MAPPING EXCEPTIONS")
with expander:
    df_unmatched=filter_dataframe(df_unmatched,"update")
    dups_event= st.dataframe(
                 df_unmatched,
                 use_container_width=True,
                 hide_index=False,
                 on_select="rerun", 
                 selection_mode="single-row")
                 #key=ss.dfk)


    form = st.form(key="annotation", clear_on_submit=True)
    with form:
        cols = st.columns((1, 1,1))
        if dups_event["selection"]["rows"]:
            master_registration_id=cols[0].text_input("Master Registration id:",df_unmatched.iat[dups_event["selection"]["rows"][0],0],disabled=True)
        else:
            master_registration_id = cols[0].text_input("Master Registration id:",disabled=True)
            
        subscriber_id = cols[1].text_input("Subscriber id:") 
        status = cols[2].selectbox("Mapping Status",("Manual", "Orphan", "Referral"),)
        
        row2=st.columns((1,5))
        
        submitted = row2[0].form_submit_button(label="Submit")
        
        selected_info = dups_event['selection']
        row2[1].form_submit_button('Clear', on_click=execute_cb, args=(selected_info,))

    if submitted:
        try:
            
            if master_registration_id =='':
                raise Exception("Master registration id is null")
            else: 
                df_chk_reg=check_rego_id(session, master_registration_id)
                if df_chk_reg[0][0] == False:
                   raise Exception("Master registration id doesnt exist")
    
            if status =='Manual':
                if subscriber_id == '':
                    raise Exception("subscriber id is null")
                else:
                    df_chk_sub=check_valid_subscriber(session, subscriber_id)
                    if df_chk_sub[0][0] == False:
                       raise Exception("subscriber id doesn't exist or not active")
                    df_chk_dup_sub=check_dup_sub(session, subscriber_id)
                    if df_chk_dup_sub[0][0] == True:
                       raise Exception("subscriber id already mapped")
            elif status == 'Referral':
                df_chk_sub=check_subscriber_exist(session, subscriber_id)
                if df_chk_sub[0][0] == False:
                    raise Exception("subscriber id doesn't exist ")
                
            else:
                if status =='Orphan' and subscriber_id != '':
                    raise Exception("subscriber id should be null for status Orphan")

# subscriber_id can be null or repeated only for referral. Referrals are excluded from downstream processing
                
            add_row_to_db(
                session,
                {'master_registration_id':master_registration_id,
                'subscriber_id': subscriber_id,
                 'status':status
                })
            
            st.success("Thank you! Your manual entry is recorded in the database.")
            time.sleep(1)
            st.rerun()
    
        except Exception as e:
            st.error(f"An error occured: {e}")





# expander2 = st.expander("UPDATE MANUAL MAPPINGS - MANUALLY MATCHED REGISTRATIONS ***DISABLED UPDATES TEMPORARILY***")
# with expander2:
#     df_manual_matched=filter_dataframe(df_manual_matched,"insert")
#     man_match_event= st.dataframe(
#                  df_manual_matched,
#                  use_container_width=True,
#                  hide_index=False,
#                  on_select="rerun", 
#                  selection_mode="single-row")
#                  #key=ss.dfk)


    # form2 = st.form(key="annotation1", clear_on_submit=True)
    # with form2:
    #     cols1 = st.columns((1, 1,1))
    #     if man_match_event["selection"]["rows"]:
    #         registration_id = cols1[0].text_input("Registration_id:", df_manual_matched.iat[man_match_event["selection"]["rows"][0],0],disabled=True)
    #     else:
    #         registration_id = cols1[0].text_input("Registration_id:",disabled=True)

    #     subscriber_id = cols1[1].text_input("Subscriber_id:")           
    #     status = cols1[2].selectbox("Mapping Status",("Manual", "Orphan", "Referral"),)
        
    #     row2=st.columns((1,5))
        
    #     submitted = row2[0].form_submit_button(label="Submit")
        
    #     selected_info = dups_event['selection']
    #     row2[1].form_submit_button('Clear', on_click=execute_cb, args=(selected_info,))

    #     if submitted:
    #         try:
    #             if registration_id =='':
    #                 raise Exception("Registration id is nul")
    #             # else: 
    #             #     df_chk_reg=check_rego_id(session, registration_id)
    #             #     if df_chk_reg[0][0] == False:
    #             #         raise Exception("registration id doesnt exist")
    
    #             if status =='Manual':
    #                 if subscriber_id == '':
    #                     raise Exception("subscriber id is null")
    #                 else:
    #                     df_chk_sub=check_valid_subscriber(session, subscriber_id)
    #                     if df_chk_sub[0][0] == False:
    #                        raise Exception("subscriber id doesn't exist or not active")
    #                     # df_chk_dup_sub=check_dup_sub(session, subscriber_id)
    #                     # if df_chk_dup_sub[0][0] == True:
    #                     #    raise Exception("subscriber id already mapped")
    #             else:
    #                 if subscriber_id != '':
    #                     raise Exception("subscriber id should be null for status cannot match or referral")


                
        
                
    #             update_row_to_db(
    #                 session,
    #                 {'registration_id':registration_id,
    #                 'subscriber_id': subscriber_id,
    #                 'status':status
    #                 })
    #             st.success("Thank you! Your manual entry is recorded in the database.")
    #             time.sleep(1)
    #             st.rerun()
                    
        
    #         except Exception as e:
    #             st.error(f"An error occured: {e}")




expander3 = st.expander("ORPHAN REGISTRATIONS - CANNOT BE MATCHED")
with expander3:
    df_cannot_match=filter_dataframe(df_cannot_match,"select")
    orphan_match_event= st.dataframe(
                 df_cannot_match,
                 use_container_width=True,
                 hide_index=False,
                 on_select="rerun", 
                 selection_mode="single-row")
                 #key=ss.dfk)

if df_referral.empty == False:
    expander4 = st.expander("CONFIRM OR REMAP POSSIBLE REFERRALS")
    with expander4:
        df_referral=filter_dataframe(df_referral,"referral")
        dups_event= st.dataframe(
                     df_referral,
                     use_container_width=True,
                     hide_index=False,
                     on_select="rerun", 
                     selection_mode="single-row",
                     key=ss.dfk)
    
    
        form = st.form(key="referral_form", clear_on_submit=True)
        with form:
            cols = st.columns((1, 1,1))
            if dups_event["selection"]["rows"]:
                master_registration_id=cols[0].text_input("Master Registration id:",df_referral.iat[dups_event["selection"]["rows"][0],0],disabled=True)
            else:
                master_registration_id = cols[0].text_input("Master Registration id:",disabled=True)
                
            subscriber_id = cols[1].text_input("Subscriber id:") 
            status = cols[2].selectbox("Mapping Status",("Manual", "Orphan", "Referral"),)
            
            row2=st.columns((1,5))
            
            submitted = row2[0].form_submit_button(label="Submit")
            
            selected_info = dups_event['selection']
            row2[1].form_submit_button('Clear', on_click=execute_cb, args=(selected_info,))
    
        if submitted:
            try:
                
                if master_registration_id =='':
                    raise Exception("Master registration id is null")
        
                if status =='Manual':
                    if subscriber_id == '':
                        raise Exception("subscriber id is null")
                    else:
                        df_chk_sub=check_valid_subscriber(session, subscriber_id)
                        if df_chk_sub[0][0] == False:
                           raise Exception("subscriber id doesn't exist or not active")
                        df_chk_dup_sub=check_dup_sub(session, subscriber_id)
                        if df_chk_dup_sub[0][0] == True:
                           raise Exception("subscriber id already mapped")
                elif status =='Referral':
                    df_chk_sub=check_subscriber_exist(session, subscriber_id)
                    if df_chk_sub[0][0] == False:
                        raise Exception("subscriber id doesn't exist ")
                else:
                    if status =='Orphan' and subscriber_id != '':
                        raise Exception("subscriber id should be null for status Orphan")
    
    # subscriber_id can be null or repeated only for referral. Referrals are excluded from downstream processing
                    
                add_row_to_db(
                    session,
                    {'master_registration_id':master_registration_id,
                    'subscriber_id': subscriber_id,
                     'status':status
                    })
                
                st.success("Thank you! Your manual entry is recorded in the database.")
                time.sleep(1)
                st.rerun()
        
            except Exception as e:
                st.error(f"An error occured: {e}")
            
if df_terminated_sub_tran.empty == False:
    expander5 = st.expander("TRANSACTIONS BY TERMINATED SUBSCRIBERS")
    with expander5:
        df_terminated_sub_tran=filter_dataframe(df_terminated_sub_tran,"terminated_sub")
        dups_event= st.dataframe(
                     df_terminated_sub_tran,
                     use_container_width=True,
                     hide_index=False,
                     on_select="rerun", 
                     selection_mode="single-row")
                     #key=ss.dfk)