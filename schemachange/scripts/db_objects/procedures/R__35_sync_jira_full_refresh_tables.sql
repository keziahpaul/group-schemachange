use role sysadmin;
use database {{in_sf_env}}_GROUP_RAW;
use schema jira;
use warehouse {{in_sf_env}}_TRN_XS_WH;
CREATE OR REPLACE PROCEDURE SYNC_JIRA_FULL_REFRESH_TABLES(TABLE_NAMES ARRAY)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests','snowflake-snowpark-python')
EXTERNAL_ACCESS_INTEGRATIONS = (jira_end_point_access)
SECRETS = ('cred' = jira_credentials)
HANDLER = 'run'
AS
$$
import json
import requests
import _snowflake
from datetime import datetime

def get_jira_data(jira_url, email, api_token, api_endpoint, is_paginated=True):
    """Get data from Jira API endpoint with pagination support"""
    auth = (email, api_token)
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    
    try:
        if is_paginated:
        # Initialize variables for pagination
            start_at = 0
            max_results = 100  # Standard value for Jira APIs
            all_data = []

            while True:
                # Add pagination parameters to URL
                paginated_url = f"{jira_url}{api_endpoint}"
                if '?' in paginated_url:
                    paginated_url += f"&startAt={start_at}&maxResults={max_results}"
                else:
                    paginated_url += f"?startAt={start_at}&maxResults={max_results}"

                print(f"Fetching data from: {paginated_url}")  # Debug log

                response = requests.get(paginated_url, headers=headers, auth=auth)
                response.raise_for_status()

                # For users endpoint, response is directly a list
                if '/rest/api/3/users/search' in api_endpoint:
                    data = response.json()
                    if not data:  # No more users
                        break
                    all_data.extend(data)
                    if len(data) < max_results:  # Last page
                        break
                    start_at += max_results
                else:
                    # For other endpoints that return paginated data in 'values' array
                    data = response.json()
                    if isinstance(data, dict) and 'values' in data:
                        values = data.get('values', [])
                        if not values:
                            break
                        all_data.extend(values)
                        total = data.get('total', 0)
                        if len(values) < max_results or start_at + max_results >= total:
                            break
                        start_at += max_results
                    else:
                        # For non-paginated responses
                        return data

                print(f"Retrieved {len(all_data)} records so far...")

            print(f"Total records retrieved: {len(all_data)}")
            return all_data
        else:
            # For non-paginated endpoints, make a single request
            url = f"{jira_url}{api_endpoint}"
            print(f"Fetching data from: {url}")

            response = requests.get(url, headers=headers, auth=auth)
            response.raise_for_status()
            return response.json()

    except Exception as e:
        error_msg = str(e)
        if hasattr(e, 'response') and hasattr(e.response, 'text'):
            error_msg += f"\nResponse text: {e.response.text}"
        raise RuntimeError(f"Error in Jira API request: {error_msg}")


def get_melbourne_timestamp():
    """Get current timestamp in Melbourne timezone"""
    return "CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::TIMESTAMP"


def get_table_configs(snowpark_session, table_names):
    """Get configurations for specified tables"""
    table_names_str = ", ".join(f"'{name}'" for name in table_names)
    query = f"""
    SELECT
        TABLE_NAME,
        API_ENDPOINT,
        TABLE_COLUMNS,
        IS_PAGINATED
    FROM JIRA_TABLE_CONFIGS
    WHERE TABLE_NAME IN ({table_names_str})
    AND IS_ACTIVE = TRUE
    """
    configs = snowpark_session.sql(query).collect()
    # Convert row objects to dictionaries
    return [row.as_dict() for row in configs]

def create_table_if_not_exists(snowpark_session, table_name, columns_config):
    """Create table if it doesn't exist"""
    column_defs = [f'"{col["name"]}" {col["type"]}' for col in columns_config]
    column_defs.append("inserted_at TIMESTAMP")
    create_table_sql = f"""
    CREATE TABLE IF NOT EXISTS {table_name} (
        {', '.join(column_defs)}
    )
    """
    snowpark_session.sql(create_table_sql).collect()

def process_data(data, columns_config):
    """Process data according to column configuration"""
    processed_data = []

    if not isinstance(data, list):
        data = [data]

    for item in data:
        try:
            processed_item = {}
            for col in columns_config:
                field_name = col["name"]
                field_type = col["type"]
                value = item.get(field_name)

                if value is None:
                    processed_item[field_name] = 'null'
                elif field_type == 'VARIANT':
                    processed_item[field_name] = json.dumps(value).replace("'", "''")
                elif field_type == 'BOOLEAN':
                    processed_item[field_name] = str(value).lower()
                elif field_type == 'TIMESTAMP':
                    if value:
                        processed_item[field_name] = f"CONVERT_TIMEZONE('Australia/Melbourne', '{value}'::TIMESTAMP)::TIMESTAMP"
                    else:
                        processed_item[field_name] = 'null'
                else:
                    processed_item[field_name] = str(value).replace("'", "''")
            processed_data.append(processed_item)

        except Exception as e:
            print(f"Error processing item: {str(e)}")
            continue

    return processed_data

def log_sync_status(snowpark_session, table_name, start_timestamp, records_loaded=0, status='SUCCESS', error_message=None):
    """Log the sync status to JIRA_LOAD_LOG"""
    end_timestamp = get_melbourne_timestamp()
    if error_message:
        error_msg = error_message.replace("'", "''")
        error_msg = f"'{error_msg}'"
    else:
        error_msg = "NULL"

    insert_sql = f"""
    INSERT INTO JIRA_LOAD_LOG (
        TABLE_NAME,
        START_TIMESTAMP,
        END_TIMESTAMP,
        RECORDS_LOADED,
        STATUS,
        ERROR_MESSAGE
    )
    SELECT
        '{table_name}',
        '{start_timestamp}',
        {end_timestamp},
        {records_loaded},
        '{status}',
        {error_msg}
    """
    snowpark_session.sql(insert_sql).collect()

def run(snowpark_session, table_names):
    try:
        # Get credentials
        secret_str = _snowflake.get_generic_secret_string('cred')
        credentials = json.loads(secret_str)
        JIRA_URL = credentials.get('url')
        EMAIL = credentials.get('email')
        API_TOKEN = credentials.get('api_token')

        if not all([JIRA_URL, EMAIL, API_TOKEN]):
            raise Exception("Invalid Jira credentials format in secret.")

        # Get configurations for specified tables
        table_names_list = [name.strip() for name in table_names]
        table_configs = get_table_configs(snowpark_session, table_names_list)

        if not table_configs:
            return f"No active configurations found for tables: {', '.join(table_names_list)}"

        results = []

        for config in table_configs:
            try:
                # Convert row to dictionary if needed
                if not isinstance(config, dict):
                    config = config.as_dict()

                table_name = config['TABLE_NAME']
                api_endpoint = config['API_ENDPOINT']
                columns_config = config['TABLE_COLUMNS']

                # Ensure columns_config is properly parsed
                if isinstance(columns_config, str):
                    columns_config = json.loads(columns_config)

                # Get Melbourne timezone start timestamp
                start_timestamp = snowpark_session.sql(
                    "SELECT CONVERT_TIMEZONE('Australia/Melbourne', CURRENT_TIMESTAMP())::TIMESTAMP"
                ).collect()[0][0]


                print(f"Processing table: {table_name}")
                print(f"Using API endpoint: {api_endpoint}")

                is_paginated = config.get('IS_PAGINATED', True)  # Default to True for backward compatibility
                # Fetch data from API
                data = get_jira_data(JIRA_URL, EMAIL, API_TOKEN, api_endpoint, is_paginated=is_paginated)


                if not data:
                    log_sync_status(
                        snowpark_session,
                        table_name,
                        start_timestamp,
                        0,
                        'WARNING',
                        'No data found'
                    )
                    results.append(f"No data found for {table_name}")
                    continue

                # Create table if not exists
                create_table_if_not_exists(snowpark_session, table_name, columns_config)
                
                # Process data
                processed_data = process_data(data, columns_config)

                if not processed_data:
                    log_sync_status(
                        snowpark_session,
                        table_name,
                        start_timestamp,
                        0,
                        'WARNING',
                        'No data processed'
                    )
                    results.append(f"No data processed for {table_name}")
                    continue

                # Generate column names for insert
                column_names = [f'"{col["name"]}"' for col in columns_config]
                columns_str = ', '.join(column_names)

                # Batch insert all records
                records_loaded = 0
                print(f"Starting data load for {table_name}")

                for item in processed_data:
                    try:
                        values = []
                        for col in columns_config:
                            field_name = col["name"]
                            field_type = col["type"]
                            value = item.get(field_name, 'null')

                            if value == 'null':
                                values.append('null')
                            elif field_type == 'VARIANT':
                                values.append(f"parse_json('{value}')")
                            elif field_type == 'TIMESTAMP':
                                if value == 'null':
                                    values.append('null')
                                else:
                                    values.append(value)  # Already formatted in process_data
                            else:
                                values.append(f"'{value}'")

                        values_str = ', '.join(values)

                        insert_sql = f"""
                            INSERT INTO {table_name} (
                                {columns_str},
                                inserted_at
                            )
                            SELECT
                                {values_str},
                                '{start_timestamp}'
                        """

                        snowpark_session.sql(insert_sql).collect()
                        records_loaded += 1

                        if records_loaded % 100 == 0:  # Log progress every 100 records
                            print(f"Loaded {records_loaded} records into {table_name}")

                    except Exception as e:
                        print(f"Error inserting record: {str(e)}")
                        continue

                # Log success
                log_sync_status(
                    snowpark_session,
                    table_name,
                    start_timestamp,
                    records_loaded,
                    'SUCCESS'
                )

                results.append(f"Successfully loaded {records_loaded} records into {table_name}")
                print(f"Completed processing {table_name}")

            except Exception as e:
                error_message = str(e)
                print(f"Error processing table {table_name}: {error_message}")
                log_sync_status(
                    snowpark_session,
                    table_name,
                    start_timestamp,
                    0,
                    'ERROR',
                    error_message
                )
                results.append(f"Error processing table {table_name}: {error_message}")
                continue

        return "\n".join(results)

    except Exception as e:
        error_message = str(e)
        print(f"Debug - Full Error: {str(e)}")
        return f"Error in Jira sync procedure: {error_message}"
$$;

CREATE OR REPLACE PROCEDURE _JIRA_API("TARGET" VARCHAR, "SINCE" TIMESTAMP_TZ(9) DEFAULT null)
RETURNS TABLE ("EXTRACTED" TIMESTAMP_TZ(9), "ID" VARCHAR, "PAYLOAD" VARIANT)
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python==*','requests==2.32.4')
HANDLER = 'main'
EXTERNAL_ACCESS_INTEGRATIONS = (JIRA_END_POINT_ACCESS)
SECRETS = ('cred'=JIRA_CREDENTIALS)
EXECUTE AS OWNER
AS $$
from _snowflake import get_generic_secret_string
from snowflake.snowpark import Session, DataFrame
from snowflake.snowpark.types import StructType, StructField, StringType, VariantType
from snowflake.snowpark.functions import col, lit, lower
from snowflake.snowpark.exceptions import SnowparkSQLException

from typing import Any
from datetime import datetime
import pytz
import json
import requests
from urllib.parse import urlparse, urlunparse
import logging
from collections import defaultdict

# JIRA_DB = "{{in_sf_env}}_GROUP_RAW"
# JIRA_SCHEMA = "JIRA"
JIRA_CONFIG_TBL = "_JIRA_CONFIG"
# expected minimum structure
#   TARGET       VARCHAR - which JIRA source you want
#   IS_PAGED     BOOLEAN - is this a "paged" resource?
#   MAX_PAGES    NUMBER  - maximum number of pages to retrieve in a single call
#   ID_PATH      VARCHAR - the path to the ID with the response blob
#   ENDPOINT_URI VARCHAR - the API end point, not including host

PAGE_SIZE = 100
MAX_PAGES = 100
SCHEMA = StructType([StructField("ID", StringType()),
                     StructField("PAYLOAD", VariantType())])

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
            if part.endswith("[]") or part.endswith("{}"):
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
    if keys[0][0] == '' or keys[0][0] in data:
        iterable = data if keys[0][0] == '' else data[keys[0][0]].values() if isinstance(data[keys[0][0]], dict) else data[keys[0][0]]
        for r in iterable:
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


class JiraAPIClient:
    def __init__(self, session: Session, target: str, since: datetime = None) -> None:
        self.start = datetime.now(pytz.timezone("Australia/Sydney"))
        self.session = session
        self.target = target
        self.since = since
        self.rows = []
        self.api_host = None
        self.endpoint_uri = None
        self.logger = SnowLogger(f"JIRA_{self.target}".upper())
        try:
            self.config = self.session.table(JIRA_CONFIG_TBL).filter(lower(col("TARGET")) == lower(lit(self.target))).collect()
            if self.config:
                self.target = self.config[0]["TARGET"]
                self.is_paged = self.config[0]["IS_PAGED"]
                self.max_pages = self.config[0]["MAX_PAGES"]
                if not self.max_pages or self.max_pages < 0:
                    self.max_pages = MAX_PAGES
                self.endpoint_uri = self.config[0]["ENDPOINT_URI"]
                self.id_path = self.config[0]["ID_PATH"]
        except SnowparkSQLException as se:
            self.logger.error(f"Configuration table {JIRA_CONFIG_TBL} not found", False)
        if not self.endpoint_uri:
            self.logger.error(f"No configuration found for target {self.target}", True)

    def create_request_args(self, api_uri: str) -> dict:
        creds = get_generic_secret_string("cred")
        credentials = json.loads(creds)
        self.api_host = urlparse(credentials.get("url")).netloc
        req_args = {
            "url": credentials.get("url") + api_uri,
            "headers": {"Accept": "application/json", "Content-Type": "application/json"},
            "auth": (credentials.get("email"), credentials.get("api_token"))
        }
        return req_args

    def samehost(self, url: str) -> str:
        parsed_url = urlparse(url)
        auth = ""
        if parsed_url.username:
            auth = parsed_url.username
            if parsed_url.password:
                auth += f":{parsed_url.password}"
            auth += "@"
        port = f":{parsed_url.port}" if parsed_url.port else ""
        new_netloc = f"{auth}{self.api_host}{port}"
        new_url = urlunparse(parsed_url._replace(netloc=new_netloc))
        return new_url

    def to_df(self) -> DataFrame:
        req_args = self.create_request_args(self.endpoint_uri.split("?")[0])
        params = {"fields": "*all"}
        if self.is_paged:
            params["maxResults"] = PAGE_SIZE
        if self.since and req_args["url"].endswith("/jql"):
            jql_since_str = self.since.strftime("%Y-%m-%d %H:%M")
            params["jql"] = f"""updated >= "{jql_since_str}" ORDER BY updated ASC"""

        if self.id_path.startswith('["') and self.id_path.endswith('"]'):
            paths = json.loads(self.id_path)
        else:
            paths = [self.id_path]
        keys = build_keys(paths)

        rows = []
        pages_remaining = self.max_pages if self.is_paged else 1
        with requests.Session() as s:
            while True:
                response = s.get(params=params, **req_args)
                if response.status_code != 200:
                    self.logger.error(f"HTTP Status: {response.status_code}\\n{response.text}", True)

                data = response.json()
                rows.extend(generate_records(data, keys, prefix=None))

                # limit the name of times we can loop
                pages_remaining -= 1
                if pages_remaining <= 0:
                    self.logger.info(f"Page limit {self.max_pages} for target {self.target} reached, exiting loop")
                    break

                if "startAt" in params:
                    # Old school pagination
                    if len(data) == 0:
                        break
                    params["startAt"] = params["startAt"] + len(data)
                elif "nextPage" in data:
                    # update the url to the "nextPage"
                    req_args["url"] = self.samehost(data["nextPage"])
                elif "nextPageToken" in data:
                    # update the param to the "nextPageToken"
                    params["nextPageToken"] = data["nextPageToken"]
                else:
                    break

        runtime = (datetime.now(pytz.timezone("Australia/Sydney")) - self.start).total_seconds()
        self.logger.info({"string": f"Retrieved {len(rows)} rows for {self.target} in {runtime} seconds",
                          "status": "COMPLETE",
                          "target": self.target,
                          "row_count": len(rows),
                          "runtime": runtime
                          })
        df = self.session.create_dataframe(rows, SCHEMA).distinct().select(lit(self.start).alias("EXTRACTED"), "ID", "PAYLOAD")
        return df

def main(session: Session, target: str, since: datetime = None) -> DataFrame:
    source = JiraAPIClient(session, target, since)
    df = source.to_df()

    return df
$$;

CREATE OR REPLACE PROCEDURE JIRA_API("TARGET" VARCHAR, "SINCE" TIMESTAMP_TZ(9) DEFAULT null)
RETURNS TABLE ("EXTRACTED" TIMESTAMP_TZ(9), "ID" VARCHAR, "PAYLOAD" VARIANT)
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
    BEGIN
        LET res RESULTSET := (CALL _JIRA_API(:TARGET, :SINCE));
        RETURN TABLE(res);
    EXCEPTION
        WHEN OTHER THEN
            -- Refresh the secret from AWS Secrets Manager
            CALL {{in_sf_env}}_GOVERNANCE_DB.COMPLIANCE.get_aws_secret('{{in_sf_env}}_group_raw.jira.jira_credentials');
            -- Retry with fresh secret
            LET res RESULTSET := (CALL _JIRA_API(:TARGET, :SINCE));
            RETURN TABLE(res);
    END;
END;
$$;
