use role sysadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema jira;
use warehouse {{in_sf_env}}_TRN_XS_WH;
CREATE OR REPLACE PROCEDURE LOAD_JIRA_ISSUES_HISTORICAL(YEAR_PARAM INTEGER)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python','requests')
HANDLER = 'main'
EXTERNAL_ACCESS_INTEGRATIONS = (jira_end_point_access)
SECRETS = ('cred' = jira_credentials)
AS
$$
import _snowflake
import requests
import json
from snowflake.snowpark import Session
from snowflake.snowpark.functions import parse_json, current_timestamp

def main(session: Session, year_param: int):
    try:
        # Validate year parameter
        current_year = session.sql('''
            SELECT YEAR(CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())) as current_year
        ''').collect()[0]['CURRENT_YEAR']
        table_name= 'ISSUES'
        
        if not (1900 <= year_param <= current_year):
            raise ValueError(f"Invalid year: {year_param}. Year must be between 1900 and {current_year}")

        # Create target table if not exists
        session.sql('''
            CREATE TABLE IF NOT EXISTS ISSUES (
                INSERTED_AT TIMESTAMP,
                ISSUE_ID STRING,
                ISSUE_DATA VARIANT
            )
        ''').collect()

        # Calculate start and end dates for the specified year
        date_result = session.sql(f'''
            SELECT 
                TO_DATE('{year_param}-01-01') as year_start,
                TO_DATE('{year_param}-12-31') as year_end,
                CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::DATE as today
        ''').collect()
        
        start_date = date_result[0]['YEAR_START']
        end_date = date_result[0]['YEAR_END']
        today = date_result[0]['TODAY']
        current_ts= "CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::timestamp"
        
        # If the year is current year, don't fetch future dates
        if year_param == current_year and end_date > today:
            end_date = today

        # Retrieve credentials from Snowflake secret
        creds = _snowflake.get_generic_secret_string('cred')
        credentials = json.loads(creds)
        jira_url = credentials.get('url')
        email = credentials.get('email')
        api_token = credentials.get('api_token')
        
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json"
        }

        # Create JQL date range query
        jql_query = f"created >= {start_date} AND created <= {end_date} ORDER BY created ASC"

        # Initialize pagination variables
        start_at = 0
        max_results = 100
        total_issues = 0
        start_time = session.sql('''
                SELECT CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::timestamp as ts
            ''').collect()[0]['TS']
            
        while True:
            response = requests.get(
                f"{jira_url}/rest/api/2/search",
                params={
                    "jql": jql_query,
                    "startAt": start_at,
                    "maxResults": max_results,
                    "fields": "*all"
                },
                headers=headers,
                auth=(email, api_token)
            )
            
            if response.status_code != 200:
                raise Exception(f"Error: {response.status_code} - {response.text}")
            
            data = response.json()
            
            if not data['issues']:
                break
                
            
                
            # Insert raw JSON into table
            issues = [
                (start_time,
                 issue['id'],
                 json.dumps(issue))
                for issue in data['issues']
            ]
            
            # Create DataFrame with all columns including INSERTED_AT
            df = session.create_dataframe(issues, ["INSERTED_AT", "ISSUE_ID", "ISSUE_DATA"])
            df = df.with_column("ISSUE_DATA", parse_json(df["ISSUE_DATA"]))
            df.write.mode("append").save_as_table("ISSUES")
            
            total_issues += len(data['issues'])
            
            if start_at + len(data['issues']) >= data['total']:
                break
                
            start_at += max_results

        # Log successful run
        session.sql(f'''
            CREATE TABLE IF NOT EXISTS JIRA_LOAD_LOG (
                RUN_ID NUMBER IDENTITY(1,1),
                TABLE_NAME STRING,
                STATUS STRING,
                START_TIMESTAMP TIMESTAMP,
                END_TIMESTAMP TIMESTAMP,
                RECORDS_LOADED NUMBER,
                ERROR_MESSAGE STRING,
                YEAR_LOADED INTEGER
                
            )
        ''').collect()

        session.sql(f'''
            INSERT INTO JIRA_LOAD_LOG (
                TABLE_NAME, START_TIMESTAMP, END_TIMESTAMP, 
                YEAR_LOADED, RECORDS_LOADED, STATUS, ERROR_MESSAGE
            )
            VALUES (
                '{table_name}',
                '{start_time}',
                {current_ts},
                {year_param},
                {total_issues},
                'SUCCESS',
                NULL
            )
        ''').collect()

        return f"Successfully loaded {total_issues} issues for year {year_param} (period: {start_date} to {end_date})"

    except Exception as e:
        # Log failed run
        error_message = str(e).replace("'", "''")  # Escape single quotes for SQL
        session.sql('''
            CREATE TABLE IF NOT EXISTS JIRA_LOAD_LOG (
                RUN_ID NUMBER IDENTITY(1,1),
                TABLE_NAME STRING,
                STATUS STRING,
                START_TIMESTAMP TIMESTAMP,
                END_TIMESTAMP TIMESTAMP,
                RECORDS_LOADED NUMBER,
                ERROR_MESSAGE STRING,
                YEAR_LOADED INTEGER
                
            )
        ''').collect()

        session.sql(f'''
            INSERT INTO JIRA_LOAD_LOG (
                TABLE_NAME, START_TIMESTAMP, END_TIMESTAMP, 
                YEAR_LOADED, RECORDS_LOADED, STATUS, ERROR_MESSAGE
            )
            VALUES (
                '{table_name}',
                '{start_time}',
                {current_ts},
                {year_param},
                {total_issues if "total_issues" in locals() else 0},
                'FAILED',
                '{error_message}'
            )
        ''').collect()
        
        raise Exception(f"Error loading Jira issues: {str(e)}")
$$;