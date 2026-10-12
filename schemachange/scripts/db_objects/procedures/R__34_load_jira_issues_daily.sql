use role sysadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema jira;

use warehouse {{in_sf_env}}_TRN_XS_WH;
CREATE OR REPLACE PROCEDURE LOAD_JIRA_ISSUES_DAILY()
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
from snowflake.snowpark.functions import parse_json
import datetime

BASE_DATE = "1990-01-01"

def _log_message(session: Session, table: str, start: datetime.datetime, records: int, status: str, message: str):
    session.sql("""
        INSERT INTO JIRA_LOAD_LOG (TABLE_NAME, START_TIMESTAMP, END_TIMESTAMP, RECORDS_LOADED, STATUS, ERROR_MESSAGE)
        VALUES (?, ?, CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::timestamp, ?, ?, ?)""",
        params=[table, start, records, status, message]).collect()

def err_message(session: Session, table: str, start: datetime.datetime, records: int, message: str):
    _log_message(session, table, start, records, 'FAILED', message)

def info_message(session: Session, table: str, start: datetime.datetime, records: int):
    _log_message(session, table, start, records, 'SUCCESS', None)

def main(session: Session):
    try:
        table_name= "ISSUES"

        # Get the latest INSERTED_AT timestamp and current timestamp in Melbourne timezone
        result = session.sql("""
            SELECT NVL(MAX(END_TIMESTAMP), ?::timestamp) AS LAST_INSERT_TIME,
                   CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::timestamp AS CURRENT_TS
            FROM JIRA_LOAD_LOG
            WHERE TABLE_NAME = ?
            AND STATUS = 'SUCCESS'
        """, params=[BASE_DATE, table_name]).collect()

        last_insert_time = result[0]["LAST_INSERT_TIME"]
        start_time = result[0]["CURRENT_TS"]

        # Retrieve credentials from Snowflake secret
        creds = _snowflake.get_generic_secret_string("cred")
        credentials = json.loads(creds)
        jira_url = credentials.get("url")
        email = credentials.get("email")
        api_token = credentials.get("api_token")
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json"
        }

        # Convert timestamp to Jira datetime format (yyyy-MM-dd HH:mm)
        last_insert_time_str = last_insert_time.strftime("%Y-%m-%d %H:%M")

        # Create JQL query to fetch issues created or updated after the last insert time
        jql_query = f'created > "{last_insert_time_str}" OR updated > "{last_insert_time_str}" ORDER BY created ASC, updated ASC'

        # Initialize pagination variables
        params={
            "jql": jql_query,
            "maxResults": 100,
            "fields": "*all"
        }
        total_issues = 0

        while True:
            response = requests.get(
                f"{jira_url}/rest/api/3/search/jql",
                params=params,
                headers=headers,
                auth=(email, api_token)
            )
            if response.status_code != 200:
                raise Exception(f"Error: {response.status_code} - {response.text}")

            data = response.json()
            if not data["issues"]:
                break

            # Insert raw JSON into table
            issues = [(start_time, issue["id"], json.dumps(issue)) for issue in data["issues"]]
            
            # Create DataFrame with all columns including INSERTED_AT
            df = session.create_dataframe(issues, ["INSERTED_AT", "ISSUE_ID", "ISSUE_DATA"]).select(
                "INSERTED_AT",
                "ISSUE_ID",
                parse_json("ISSUE_DATA").alias("ISSUE_DATA")
            )
            # Parse ISSUE_DATA as JSON
            df.write.mode("append").save_as_table("ISSUES")
            total_issues += len(data["issues"])

            params["nextPageToken"] = data.get("nextPageToken")
            if data.get("isLast", False) or not params["nextPageToken"]:
                break

        # Log successful run
        info_message(session, table_name, start_time, total_issues)
        return f"Successfully loaded {total_issues} issues created after : {start_time}"

    except Exception as e:
        # Log failed run
        err_str = str(e)
        err_message(session, table_name, start_time, total_issues if "total_issues" in locals() else 0, err_str)
        raise Exception(f"Error loading Jira issues: {err_str}")
$$;