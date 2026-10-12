
use role sysadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema genesys;
use warehouse {{in_sf_env}}_TRN_XS_WH;

{% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'pst') or (in_sf_env.lower() == 'prd') %}
CREATE OR REPLACE PROCEDURE FETCH_CALL_CENTRE_DATA()
RETURNS OBJECT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests', 'snowflake-snowpark-python')
EXTERNAL_ACCESS_INTEGRATIONS = (genesys_access)
SECRETS = ('cred' = genesys_credentials)
HANDLER = 'main'
AS
$$
import base64, requests, sys, io, json
import pandas as pd
from snowflake.snowpark import Session
import _snowflake
from datetime import datetime

def get_secrets():
    """
    Get secrets from Snowflake and validate them
    """
    try:
        secret_str = _snowflake.get_generic_secret_string('cred')
        credentials = json.loads(secret_str)
        
        # Required credential keys
        required_credentials = ['client_id', 'client_secret', 'token_url', 'static_url']
        
        # Check for missing or empty credentials
        missing_creds = [key for key in required_credentials 
                        if not credentials.get(key) or not str(credentials.get(key)).strip()]
        
        if missing_creds:
            raise ValueError(f"Missing or empty credentials: {', '.join(missing_creds)}")
        
        return (credentials['client_id'].strip(),
                credentials['client_secret'].strip(),
                credentials['token_url'].strip(),
                credentials['static_url'].strip())
                
    except Exception as e:
        raise Exception(f"Secret validation failed: {str(e)}")

def get_oauth_token(client_id: str, client_secret: str, token_url: str):
    """
    Get OAuth token using client credentials
    """
    try:
        auth_bytes = base64.b64encode(
            bytes(client_id + ":" + client_secret, "ISO-8859-1")
        ).decode("ascii")
        
        response = requests.post(
            token_url,
            headers={
                "Authorization": f'Basic {auth_bytes}',
                "Content-Type": "application/x-www-form-urlencoded"
            },
            data={"grant_type": "client_credentials"},
            timeout=30
        )
        
        if response.status_code != 200:
            raise Exception(f"Failed with status {response.status_code}: {response.text}")
            
        return response.json()
            
    except Exception as e:
        raise Exception(f"OAuth token request failed: {str(e)}")

def fetch_data(static_url: str, token_data: dict):
    """
    Fetch CSV data using the provided token
    """
    try:
        response = requests.get(
            static_url,
            headers={
                "Authorization": f"{token_data['token_type']} {token_data['access_token']}"
            },
            timeout=30
        )
        
        if response.status_code != 200:
            raise Exception(f"Failed with status {response.status_code}: {response.text}")
            
        df = pd.read_csv(io.StringIO(response.content.decode('utf-8')))
        
        if df.empty:
            raise ValueError("Received empty dataset")
            
        return df
        
    except Exception as e:
        raise Exception(f"Data fetch failed: {str(e)}")

def save_to_tables(session: Session, df: pd.DataFrame, summary_table: str, detail_table: str):
    """
    Save DataFrame to Summary and Detail tables
    - First row goes to summary table
    - Remaining rows go to detail table
    - Both tables maintain insertion timestamp for auditing
    """
    try:
        # Store original column count
        original_column_count = len(df.columns)
        
        # Get Melbourne timestamp
        melbourne_timestamp = session.sql("""
            SELECT CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Melbourne', 
                CURRENT_TIMESTAMP()
            ) as melb_time
        """).collect()[0]['MELB_TIME']
        
        # Split data into summary and detail
        df_summary = df.iloc[:1].copy()  # First row
        df_detail = df.iloc[1:].copy()   # Remaining rows
        
        # Add insertion timestamp to both dataframes
        df_summary['INSERTED_AT'] = melbourne_timestamp
        df_detail['INSERTED_AT'] = melbourne_timestamp
        
        # Function to check table existence and column count
        def validate_table(table_name, data_df):
            table_exists = session.sql(f"""
                SELECT COUNT(*) as count 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_NAME = '{table_name}'
            """).collect()[0]['COUNT'] > 0
            
            if table_exists:
                column_count = session.sql(f"""
                    SELECT COUNT(*) as count 
                    FROM INFORMATION_SCHEMA.COLUMNS 
                    WHERE TABLE_NAME = '{table_name}'
                """).collect()[0]['COUNT']
                
                if column_count != len(data_df.columns):
                    raise Exception(f"Column count mismatch in {table_name}. Table has {column_count} columns, but source has {len(data_df.columns)} columns")
            
            return table_exists
        
        # Process Summary Table
        summary_df = session.create_dataframe(df_summary)
        summary_df.write.saveAsTable(summary_table, mode="append")
        
       # Process Detail Table
        detail_df = session.create_dataframe(df_detail)
        detail_df.write.saveAsTable(detail_table, mode="append")
        
        return {
            "summary_records": len(df_summary),
            "detail_records": len(df_detail)
        }
        
    except Exception as e:
        raise Exception(f"Failed to save to tables: {str(e)}")

def create_error_log_table(session: Session):
    """
    Create error log table if it doesn't exist using DataFrame
    """
    try:
        # Create a sample DataFrame with the error log structure
        error_data = {
            'timestamp': [session.sql("""
                SELECT CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Melbourne', 
                    CURRENT_TIMESTAMP()
                ) as melb_time
            """).collect()[0]['MELB_TIME']],
            'error_type': ['INITIALIZATION'],
            'error_message': ['Error log table created']
        }
        error_df = pd.DataFrame(error_data)
        
        # Convert to Snowpark DataFrame and create table
        snowpark_error_df = session.create_dataframe(error_df)
        snowpark_error_df.write.saveAsTable('GENESYS_INGESTION_ERROR_LOG', mode = "ignore") 
        
    except Exception as e:
        print(f"Failed to create error log table: {str(e)}")

def log_error(session: Session, error_type: str, error_message: str):
    """
    Log errors to error logging table using DataFrame
    """
    try:
        # Get Melbourne timestamp
        melbourne_timestamp = session.sql("""
            SELECT CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Melbourne', 
                CURRENT_TIMESTAMP()
            ) as melb_time
        """).collect()[0]['MELB_TIME']
        
        # Create error log DataFrame
        error_data = {
            'timestamp': [melbourne_timestamp],
            'error_type': [error_type],
            'error_message': [error_message]
        }
        error_df = pd.DataFrame(error_data)
        
        # Convert to Snowpark DataFrame and insert
        snowpark_error_df = session.create_dataframe(error_df)
        snowpark_error_df.write.saveAsTable('GENESYS_INGESTION_ERROR_LOG', mode="append")
        
    except Exception as e:
        print(f"Failed to log error: {str(e)}")
        print(f"Original error - Type: {error_type}, Message: {error_message}")

def main(session: Session):
    """
    Main function to orchestrate the data fetch and save process
    """

    # Ensure error log table exists before starting
    create_error_log_table(session)
    
    start_time = session.sql("""
        SELECT CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Melbourne', CURRENT_TIMESTAMP()
        ) as melb_time
    """).collect()[0]['MELB_TIME']
    
    try:
        # Get and validate secrets
        client_id, client_secret, token_url, static_url = get_secrets()
        
        # Get OAuth token
        token_data = get_oauth_token(client_id, client_secret, token_url)
        
        # Fetch CSV data
        df = fetch_data(static_url, token_data)
        
        # Save to summary and detail tables
        summary_table = "CALL_CENTRE_DATA_SUMMARY"
        detail_table = "CALL_CENTRE_DATA_DETAIL"
        load_results = save_to_tables(session, df, summary_table, detail_table)
        
        # Get current Melbourne time for response
        current_melb_time = session.sql("""
            SELECT CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Melbourne', CURRENT_TIMESTAMP()) as melb_time
        """).collect()[0]['MELB_TIME']
        
        return {
            "status": "success",
            "timestamp": current_melb_time.isoformat(),
            "summary_table": summary_table,
            "detail_table": detail_table,
            "summary_records": load_results['summary_records'],
            "detail_records": load_results['detail_records'],
            "execution_time_seconds": (current_melb_time - start_time).total_seconds()
        }
        
    except Exception as e:
        error_msg = str(e)
        log_error(session, "PROCEDURE_ERROR", error_msg)
        
        current_melb_time = session.sql("""
            SELECT CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Melbourne', CURRENT_TIMESTAMP()) as melb_time
        """).collect()[0]['MELB_TIME']
        
        return {
            "status": "error",
            "timestamp": current_melb_time.isoformat(),
            "error_message": error_msg,
            "execution_time_seconds": (current_melb_time - start_time).total_seconds()
        }
$$;
{% endif %}

DROP PROCEDURE IF EXISTS GENESYS_API(VARCHAR, TIMESTAMP_TZ(9));

CREATE OR REPLACE PROCEDURE _GENESYS_API("TARGET" VARCHAR, "SINCE" DATE DEFAULT null)
RETURNS TABLE ("EXTRACTED" TIMESTAMP_TZ(9), "ID" VARCHAR, "PAYLOAD" VARIANT)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python==*','requests==2.32.4')
HANDLER = 'main'
EXTERNAL_ACCESS_INTEGRATIONS = (GENESYS_ACCESS)
SECRETS = ('cred'=GENESYS_CREDENTIALS)
EXECUTE AS OWNER
AS $$
from _snowflake import get_generic_secret_string
from snowflake.snowpark import Session, DataFrame
from snowflake.snowpark.types import StructType, StructField, IntegerType, StringType, VariantType
from snowflake.snowpark.functions import col, lit, lower
from snowflake.snowpark.exceptions import SnowparkSQLException

from typing import Any
import requests
import base64
import json
import logging
from time import sleep
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo
from collections import defaultdict

MELBOURNE = ZoneInfo("Australia/Melbourne")

# GENESYS_DB = "{{in_sf_env}}_GROUP_RAW"
# GENESYS_SCHEMA = "GENESYS"
GENESYS_CONFIG_TBL = "_GENESYS_CONFIG"
# expected minimum structure
#   TARGET       VARCHAR - which GENESYS source you want
#   IS_PAGED     BOOLEAN - is this a "paged" resource?
#   MAX_PAGES    NUMBER  - maximum number of pages to retrieve in a single call
#   ID_PATH      VARCHAR - the path to the ID with the response blob
#   VERB         VARCHAR - the HTTP verb to use when calling the API (GET, POST, etc)
#   ENDPOINT_URI VARCHAR - the API end point, not including host
#   ARGS         VARIANT - any additional arguments to be passed to the API call, such as body parameters
#                          for a POST request. This is expected to be a JSON parseable object.

SCHEMA = StructType([StructField("ID", StringType()),
                     StructField("PAYLOAD", VariantType())])

# GENESYS_CREDENTIALS secret is expected to be in the following format:
# {
#   "client_id": "xxx",
#   "client_secret": "yyy",
#   "token_url": "https://somehost.com/to/get/authtoken",
#   "static_url": "https://somehost.com/path/to/data",
#   "api_url": "https://somehost.com"
# }

def truncate_midnight(dt: date) -> datetime:
    return datetime.combine(dt, time.min, tzinfo=MELBOURNE)

def format_timestamp(dt: datetime) -> str:
    return dt.isoformat(timespec="milliseconds")

def make_lambda(path_parts):
    # Create a lambda that indexes into dict using path_parts
    return lambda x, parts=path_parts: _extract(x, parts)

def _extract(obj, parts):
    for p in parts:
        obj = obj[p]
    return obj

def build_keys(paths):
    grouped = defaultdict(list)
    for path in paths:
        parts = path.split(".")
        current_array = None
        current_path = []
        for part in parts:
            if part.endswith("[]"):
                current_array = part[:-2]
                current_path = []
            else:
                current_path.append(part)
        field_name = current_path[-1]
        grouped[current_array].append(
            (field_name, make_lambda(current_path))
        )
    # convert to desired structure
    return [[k, v] for k, v in grouped.items()]

# keys is a list of tuples of the form (id_path, [(id_key, lambda to extract id value from record), ...])
# allowing for nested structures where the id values are not all at the same level.
# build_keys provides this.
# The final yielded record will have an ID of the form "id_key1/id_key2/..." and
# a payload of the full record with the id values added in.
def generate_records(data, keys, prefix=None):
    if keys[0][0] in data:
        for r in data[keys[0][0]]:
            # skip records where we can't find an id value
            try:
                id = {k: str(l(r)) for k, l in keys[0][1]}
                if prefix:
                    id = prefix | id
                if len(keys) > 1:
                    for s in generate_records(r, keys[1:], id):
                        yield s
                else:
                    yield(
                        "/".join(id.values()),
                        id | r
                    )
            except KeyError:
                continue


class SnowLogger:
    def __init__(self, procname: str) -> None:
        self.logger = logging.getLogger(procname)

    def error(self, message: Any, raise_error: bool) -> None:
        self.logger.error(message)
        if raise_error:
            raise Exception(message)

    def log(self, message: Any) -> None:
        self.logger.info(message)

    def info(self, message: Any) -> None:
        self.logger.info(message)

    def debug(self, message: Any) -> None:
        self.logger.debug(message)


class GenesysClient:
    # Resource Limits
    # The following limits apply to this resource.
    # For more information, see the main article on Rate Limits and the full list of Platform API Limits.

    # Key                                       Description                                                             Limit  Resource(s)                   Configurable?
    # ----------------------------------------  ---------------------------------------------------------------------  ------  --------------------------------------  ---
    # client.credentials.token.rate.per.minute  The maximum number of requests a Client Credentials grant token is        300  api/v2/*                                yes
    #                                           allowed per minute
    # token.rate.per.minute                     The maximum number of requests per token per minute                       300  api/v2/*                                 no
    # org.app.user.rate.per.minute              The maximum number of requests a user is allowed, per minute, with a     3000  api/v2/*                                 no
    #                                           specific Authorization Code or Token Implicit OAuth client grant
    # request.bytes.max                         The maximum content length of a request payload                        512000  api/v2/*                                 no
    # aggregates.query.predicates.max           The maximum number of query predicates for aggregate queries              200  api/v2/analytics/*/aggregates/query      no
    # aggregates.query.topn.limit.max           The maximum number of records that can be retrieved in top-N/bottom-N      50  api/v2/analytics/*/aggregates/query     yes
    #                                           aggregate queries.
    # aggregates.rate.per.second                The maximum number of requests per second for aggregates endpoints         75  api/v2/analytics/*/aggregates/query     yes
    # details.query.predicates.max              Maximum number of query predicates for details queries and jobs           200  api/v2/analytics/*/details/[jobs, query] no
    # details.jobs.concurrent.access.max        Details jobs max concurrent access values                                   4  api/v2/analytics/*/details/jobs          no
    # details.jobs.rate.per.second              Maximum operations per second for details jobs                             75  api/v2/analytics/*/details/jobs          no
    # details.query.concurrency.max             Maximum concurrent access for details queries                              50  api/v2/analytics/*/details/query         no
    # details.query.page.size.max               Max page size for query (individual orgs can be set by using              100  api/v2/analytics/*/details/query         no
    #                                           <organizationId>)
    # details.query.pagination.depth.max        Maximum pagination depth (page number x page size) before a query      100000  api/v2/analytics/*/details/query         no
    #                                           gets rejected

    # The following permissions and scopes must be associated with the API client for the respective endpoints.
    # user
    # Permission                                 Scope
    # -                                          * users
    #                                            * users:readonly

    # wrap_up_code
    # Permission                                 Scope
    # routing:wrapupCode:view                    * routing
    #                                            * routing:readonly

    # queue
    # Permission                                 Scope
    # * routing:queue:view                       * routing
    #                                            * routing:readonly

    # conversation
    # Permission                                 Scope
    # * analytics:conversationDetail:view        * analytics
    # * analytics:agentConversationDetail:view   * analytics:readonly

    # *queue_aggregate
    # Permission                                 Scope
    # * analytics:conversationAggregate:view     * analytics
    #                                            * analytics:readonly

    # These are the valid queue metrics

    # nBlindTransferred, nBotInteractions, nCallbackAttempts, nCallbackScheduled,
    # nCobrowseSessions, nConnected, nConsult, nConsultTransferred, nConversations,
    # nError, nOffered, nOutbound, nOutboundAbandoned, nOutboundAttempted,
    # nOutboundConnected, nOverSla, nStateTransitionError, nTakeover, nTransferred,

    # oAudioMessageCount, oExternalAudioMessageCount, oExternalMediaCount,
    # oMediaCount, oMessageCount, oMessageSegmentCount, oMessageTurn, oServiceLevel,
    # oServiceTarget,

    # tAbandon, tAcd, tActiveCallback, tActiveCallbackComplete, tAcw,
    # tAgentResponseTime, tAgentVideoConnected, tAlert, tAnswered,
    # tAverageAgentResponseTime, tAverageCustomerResponseTime, tBarging,
    # tCallbackAbandon, tCallbackConnect, tCallbackNotReached, tCoaching,
    # tCoachingComplete, tConnected, tContacting, tDialing, tFirstConnect,
    # tFirstDial, tFirstEngagement, tFirstResponse, tFlowOut, tHandle, tHeld,
    # tHeldComplete, tIvr, tMonitoring, tMonitoringComplete, tNotResponding, tPark,
    # tParkComplete, tScreenMonitoring, tShortAbandon, tSnippetRecord, tTalk,
    # tTalkComplete, tUserResponseTime, tVoicemail, tWait

    # unsupported metrics
    #   nCallbackAttempts, nCallbackScheduled, nTakeover, tAgentVideoConnected,
    #   tCallbackAbandon, tCallbackConnect, tCallbackNotReached, tScreenMonitoring

    MAX_DAYS = 100
    MAX_PAGE_SIZE = 1000
    MAX_PAGES = 1000
    MAX_WAIT = 10

    def __init__(self, session: Session, target: str, since: date = None):
        self.start = datetime.now(tz=MELBOURNE)
        self.session = session
        self.target = target
        self.since = since
        self.rows = []
        self.endpoint_uri = None
        self.logger = SnowLogger(f"GENESYS_{self.target}".upper())

        try:
            self.config = self.session.table(GENESYS_CONFIG_TBL).filter(lower(col("TARGET")) == lower(lit(self.target))).collect()
            if self.config:
                self.target = self.config[0]["TARGET"]
                self.is_paged = self.config[0]["IS_PAGED"]
                self.max_pages = self.config[0]["MAX_PAGES"]
                if not self.max_pages or self.max_pages < 0:
                    self.max_pages = GenesysClient.MAX_PAGES
                self.verb = self.config[0]["VERB"].upper()
                self.endpoint_uri = self.config[0]["ENDPOINT_URI"].lstrip("/")
                self.id_path = self.config[0]["ID_PATH"]
                self.arguments = json.loads(self.config[0]["ARGUMENTS"]) if self.config[0]["ARGUMENTS"] is not None else {}
        except SnowparkSQLException as se:
            self.logger.error(f"Configuration table {GENESYS_CONFIG_TBL} not found", False)
        if not self.endpoint_uri:
            self.logger.error(f"No configuration found for target {self.target}", True)

        if since:
            since = truncate_midnight(since)
            end = since + timedelta(days=GenesysClient.MAX_DAYS)
            if end > self.start:
                end = truncate_midnight(self.start)
            self.arguments["interval"] = f"{format_timestamp(since)}/{format_timestamp(end)}"
        self.since = since

        if since and since == end:
            self.logger.info({"string": f"Target {self.target} already up to date", "status": "COMPLETE", "target": self.target})
            self.api_url = None
            # Early return as no data will be retrieved. Use empty api_url to detect that
            return

        credentials = json.loads(get_generic_secret_string("cred"))
        self.api_url = credentials.get("api_url").strip().rstrip("/")
        auth_bytes = base64.b64encode(bytes(credentials.get("client_id").strip() + ":" + credentials.get("client_secret").strip(), "ISO-8859-1")).decode("ascii")
        response = requests.post(
            credentials.get("token_url").strip(),
            headers={
                "Authorization": f"Basic {auth_bytes}",
                "Content-Type": "application/x-www-form-urlencoded"
            },
            data={"grant_type": "client_credentials"},
            timeout=30
        )
        if response.status_code != 200:
            raise Exception(f"AUTH_FAILED: {response.status_code} - {response.text}")
        token = response.json()
        self.headers = {
            "Authorization": f"{token['token_type']} {token['access_token']}",
            "Content-Type": "application/json"
        }

    def __enter__(self):
        if self.api_url:
            self.req_session = requests.Session()
            self.req_session.headers.update(self.headers)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.api_url:
            response = self.req_session.delete(f"{self.api_url}/api/v2/tokens/me")
            if response.status_code != 200:
                raise Exception(response.text)
            self.req_session.close()

    def to_df(self) -> DataFrame:
        rows = []
        if self.api_url is not None:
            params = self.arguments if self.arguments else {}
            if self.is_paged:
                params["pageSize"] = GenesysClient.MAX_PAGE_SIZE
                params["pageNumber"] = 1

            if self.id_path.startswith('["') and self.id_path.endswith('"]'):
                paths = json.loads(self.id_path)
            else:
                paths = [self.id_path]
            keys = build_keys(paths)

            while True:
                if self.verb == "GET":
                    response = self.req_session.get(f"{self.api_url}/{self.endpoint_uri}", params=params)
                elif self.verb == "POST":
                    response = self.req_session.post(f"{self.api_url}/{self.endpoint_uri}", json=params)
                else:
                    raise ValueError(f"Unsupported verb {self.verb}")
                if response.status_code == 202:
                    jobid = response.json()["jobId"]
                    state = "QUEUED"
                    cur_loop = 0
                    while cur_loop < GenesysClient.MAX_WAIT:
                        if cur_loop > 0:
                            sleep(5)
                        cur_loop += 1
                        response = self.req_session.get(f"{self.api_url}/{self.endpoint_uri}/{jobid}")
                        if response.status_code >= 400:
                            raise Exception(response.text)
                        state = response.json()["state"]
                        # State      Description
                        # QUEUED     The job is in the queue, waiting to run
                        # PENDING    The job is running
                        # FAILED     The job completed with an error
                        # CANCELLED  The job was manually cancelled
                        # FULFILLED  The job completed successfully
                        # EXPIRED    The job previously completed, but results have since expired
                        if state in ["FAILED", "CANCELLED", "FULFILLED", "EXPIRED"]:
                            break
                    if state != "FULFILLED":
                        raise Exception(f"Job ended with state {state}")
                    self.verb = "GET"
                    self.endpoint_uri = f"{self.endpoint_uri}/{jobid}/results"
                    _ = params.pop("pageNumber", None)
                    continue
                elif response.status_code != 200:
                    raise Exception(response.text)
                data = response.json()

                rows.extend(generate_records(data, keys, prefix=None))

                if not data.get("nextUri") and not data.get("cursor"):
                    break
                if self.is_paged:
                    if "pageNumber" in params:
                        params["pageNumber"] = params["pageNumber"] + 1
                    elif "cursor" in data:
                        params["cursor"] = data["cursor"]
                    else:
                        raise Exception("Pagination enabled but no pageNumber param or cursor in response for next page")

        runtime = (datetime.now(tz=MELBOURNE) - self.start).total_seconds()
        self.logger.info({"string": f"Retrieved {len(rows)} rows for {self.target} in {runtime} seconds",
                          "status": "COMPLETE",
                          "target": self.target,
                          "row_count": len(rows),
                          "runtime": runtime
                          })
        df = self.session.create_dataframe(rows, SCHEMA).distinct().select(lit(self.start).alias("EXTRACTED"), "ID", "PAYLOAD")
        return df


def main(session: Session, target: str, since: date = None) -> DataFrame:
    with GenesysClient(session, target, since) as source:
        df = source.to_df()
    return df
$$;

CREATE OR REPLACE PROCEDURE GENESYS_API("TARGET" VARCHAR, "SINCE" DATE DEFAULT null)
RETURNS TABLE ("EXTRACTED" TIMESTAMP_TZ(9), "ID" VARCHAR, "PAYLOAD" VARIANT)
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
    BEGIN
        LET res RESULTSET := (CALL _GENESYS_API(:TARGET, :SINCE));
        RETURN TABLE(res);
    EXCEPTION
        WHEN OTHER THEN
            -- Refresh the secret from AWS Secrets Manager
            CALL {{in_sf_env}}_GOVERNANCE_DB.COMPLIANCE.get_aws_secret('{{in_sf_env}}_group_raw.genesys.genesys_credentials');
            -- Retry with fresh secret
            LET res RESULTSET := (CALL _GENESYS_API(:TARGET, :SINCE));
            RETURN TABLE(res);
    END;
END;
$$;