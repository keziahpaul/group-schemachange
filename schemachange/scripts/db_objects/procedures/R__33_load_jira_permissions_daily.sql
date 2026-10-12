use role sysadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema jira;

use warehouse {{in_sf_env}}_TRN_XS_WH;
CREATE OR REPLACE PROCEDURE LOAD_JIRA_PERMISSIONS_DAILY()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests','snowflake-snowpark-python')
EXTERNAL_ACCESS_INTEGRATIONS = (jira_end_point_access)
SECRETS = ('cred' = jira_credentials)
HANDLER = 'main'
AS
$$
import json
import requests
import _snowflake
from datetime import datetime
from snowflake.snowpark.functions import parse_json

def main(session):
    try:
        
        table_name = 'PERMISSIONS'
        records_loaded = 0
        current_ts = "CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::timestamp"

        # Create permissions table if it doesn't exist
        session.sql("""
            CREATE TABLE IF NOT EXISTS PERMISSIONS (
                INSERTED_AT TIMESTAMP,
                PERMISSION_KEY STRING,
                PERMISSION_DATA VARIANT
            )
        """).collect()

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

        # Get current timestamp in Melbourne timezone
        start_time = session.sql('''
                SELECT CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::timestamp as ts
            ''').collect()[0]['TS']
        
        response = requests.get(
            f"{jira_url}/rest/api/3/permissions",
            headers=headers,
            auth=(email, api_token),
            timeout=30
        )

        if response.status_code != 200:
                error_msg = f"Failed to fetch permissions. Status code: {response.status_code}, Response: {response.text[:500]}"
                raise Exception(error_msg)
            
        permissions_data = response.json()
        
        # Transform permissions data into list of tuples
        permissions_list = [
            (start_time,
                perm_key,
                json.dumps(perm_data))
            for perm_key, perm_data in permissions_data['permissions'].items()
        ]
        
        # Create DataFrame with the permissions data
        df = session.create_dataframe(
            permissions_list,
            ["INSERTED_AT", "PERMISSION_KEY", "PERMISSION_DATA"]
        )
        
        # Parse the JSON string into VARIANT type
        df = df.with_column("PERMISSION_DATA", parse_json(df["PERMISSION_DATA"]))
        
        # Write to the permissions table
        df.write.mode("append").save_as_table("PERMISSIONS")
        
        records_loaded = len(permissions_list)

        # Log successful run
        session.sql(f'''
            INSERT INTO JIRA_LOAD_LOG (
                TABLE_NAME, START_TIMESTAMP, END_TIMESTAMP,
                 RECORDS_LOADED, STATUS, ERROR_MESSAGE
            )
            VALUES (
                '{table_name}',
                '{start_time}',
                {current_ts},
                {records_loaded},
                'SUCCESS',
                NULL
            )
        ''').collect()
        
        return f"Successfully synced {records_loaded} Jira permissions"
            
    except Exception as e:
        # Log failed run
        error_message = str(e).replace("'", "''")  # Escape single quotes for SQL
        
        session.sql(f'''
            INSERT INTO JIRA_LOAD_LOG (
                TABLE_NAME, START_TIMESTAMP, END_TIMESTAMP,
                 RECORDS_LOADED, STATUS, ERROR_MESSAGE
            )
            VALUES (
                '{table_name}',
                '{start_time}',
                {current_ts},
                {records_loaded if "records_loaded" in locals() else 0},
                'FAILED',
                '{error_message}'
            )
        ''').collect()
        
        raise Exception(f"Error in SYNC_JIRA_PERMISSIONS: {str(e)}")
$$;