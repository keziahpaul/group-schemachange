# Specification: Add New Schema

## Overview
Add a new schema to an existing Snowflake database (or create a new database with schema) using the project's schemachange repeatable script pattern and shared Jinja macro.

## Context
This project manages Snowflake database objects via schemachange with repeatable SQL scripts (`R__<number>_<description>.sql`). Schema creation uses the shared Jinja macro `create_database_schema` imported from `modules/create_database_schema.j2`.

## Requirements

### Inputs (from user)
1. **Database name** — The logical database (e.g., `GROUP_RAW`, `GROUP_CURATE`, `GROUP_STAGE`, `GROUP_COMMON_DATA_LAYER`, `LOGGING`)
2. **Schema name(s)** — One or more schema names to create (e.g., `JIRA`, `CDM`, `BILLING_AND_INVOICING`)
3. **Script placement** — Whether to add to an existing script or create a new one

### Implementation Steps

#### 1. Determine Script Number
- Query `<ENV>_METADATA.SCHEMACHANGE.CHANGE_HISTORY` for the last executed script number, OR
- Check existing files in `schemachange/scripts/db_objects/database_schema/` for the highest number
- New script number = highest existing number + 1 (if creating a new file)

#### 2. Create or Update the SQL Script
- **Location**: `schemachange/scripts/db_objects/database_schema/`
- **File name**: `R__<number>_create_<description>_database_schema.sql`
- **Template structure**:

```sql
{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating <description> schema for env {{in_sf_env}}

{{create_database_schema(in_sf_env, '<DATABASE_NAME>', "<SCHEMA_NAME>" )}}
```

#### 3. Macro Usage Patterns
- **Single schema**: `{{create_database_schema(in_sf_env, 'GROUP_RAW', "MY_SCHEMA" )}}`
- **Multiple schemas (array)**: `{{create_database_schema(in_sf_env, 'GROUP_STAGE', ["SCHEMA_A","SCHEMA_B"])}}`
- **Multiple separate calls** (for distinct schemas in same DB):
  ```sql
  {{create_database_schema(in_sf_env, 'GROUP_RAW', "SCHEMA_A" )}}
  {{create_database_schema(in_sf_env, 'GROUP_RAW', "SCHEMA_B" )}}
  ```

#### 4. Environment Handling
- The `{{in_sf_env}}` variable automatically prefixes database names per environment (dev/tst/pst/prd)
- No environment-specific logic needed unless the schema should only exist in certain environments
- Use Jinja conditionals if needed:
  ```sql
  {% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'prd') %}
  {{create_database_schema(in_sf_env, 'GROUP_RAW', "DEV_ONLY_SCHEMA" )}}
  {% else %}
  select 1;
  {% endif %}
  ```

### Existing Databases in Project
| Database | Script | Schemas |
|----------|--------|---------|
| GROUP_RAW | R__01 | KAPICHE, SENDFX, FMS, JIRA, GENESYS, BILLING_AND_INVOICING |
| GROUP_CURATE | R__02 | SALESFORCE, SENDFX, KAPICHE, FMS, JIRA, GENESYS, BILLING_AND_INVOICING |
| INB_EXTERNAL_DATASHARE | R__10 | (see file) |
| GROUP_STAGE | R__12 | SENDFX, FMS, BILLING_AND_INVOICING |
| DATA_SCIENCE | R__14 | (see file) |
| GROUP_COMMON_DATA_LAYER | R__17 | CDM, ODS |
| (salesforce s3 ingress) | R__18 | (see file) |
| LOGGING | R__37 | TRUSTCENTER |

### Validation Checklist
- [ ] Script uses repeatable naming convention `R__<number>_<description>.sql`
- [ ] Script imports `create_database_schema` from `modules/create_database_schema.j2`
- [ ] Database name and schema name are uppercase
- [ ] `{{in_sf_env}}` is used (not hardcoded environment prefix)
- [ ] Script number does not conflict with existing scripts
- [ ] Comment describes what the script does

### Deployment
- Push to feature branch → deploys to **dev**
- Merge to `develop` → deploys to **tst**
- Release/hotfix PR to `main` → deploys to **pst** then **prd**
- Repeatable scripts re-execute on every run if file content changes

### Risks & Considerations
- Adding a schema to an existing database script (e.g., appending to R__01) will trigger re-execution of that entire script on next deploy
- Creating a new script with a new number avoids this but adds a new file
- Schema names must not conflict with existing schemas in the same database
- The `create_database_schema` macro handles `CREATE DATABASE IF NOT EXISTS` and `CREATE SCHEMA IF NOT EXISTS` (idempotent)
