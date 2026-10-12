# kspec Context
> Auto-generated. Always read this first after context compression.

## Current Spec
**2026-06-10-schema**
Path: `.kiro/specs/2026-06-10-schema`

**NOTE: spec.md was modified. Using spec.md directly for context.**
Run `kspec refresh` to generate optimized spec-lite.md summary.

## Requirements Summary
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
| (salesforce s3 ingres

... (truncated, run `kspec refresh` for full summary)

## Design
- Status: not yet created
- Run `kspec design` to create (optional)

## Quick Commands
- `kspec design` - Create technical design (optional)
- `kspec tasks` - Generate implementation tasks
- `kspec build` - Continue building tasks
- `kspec verify` - Verify implementation
- `kspec status` - Show current status
- `kspec context` - Refresh this file
