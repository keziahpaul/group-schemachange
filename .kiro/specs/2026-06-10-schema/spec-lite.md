# Spec Lite: Add New Schema

## What
Add a new schema to a Snowflake database via a repeatable schemachange script.

## Where
`schemachange/scripts/db_objects/database_schema/R__<number>_<description>.sql`

## Template
```sql
{% from 'modules/create_database_schema.j2' import create_database_schema-%}

--creating <description> schema for env {{in_sf_env}}

{{create_database_schema(in_sf_env, '<DATABASE_NAME>', "<SCHEMA_NAME>" )}}
```

## Key Rules
- **Naming**: `R__<number>_create_<desc>_database_schema.sql` — number sets execution order
- **Macro**: `create_database_schema(in_sf_env, '<DB>', "<SCHEMA>")` — supports string or array of schemas
- **Environment**: `{{in_sf_env}}` auto-prefixes DB names; never hardcode env
- **Case**: Database and schema names UPPERCASE
- **Idempotent**: Macro uses `IF NOT EXISTS`
- **Script number**: Check highest in directory or `CHANGE_HISTORY` table, increment by 1

## Existing Databases
- `GROUP_RAW` (R__01) — KAPICHE, SENDFX, FMS, JIRA, GENESYS, BILLING_AND_INVOICING
- `GROUP_CURATE` (R__02) — SALESFORCE, SENDFX, KAPICHE, FMS, JIRA, GENESYS, BILLING_AND_INVOICING
- `GROUP_STAGE` (R__12) — SENDFX, FMS, BILLING_AND_INVOICING
- `GROUP_COMMON_DATA_LAYER` (R__17) — CDM, ODS
- `LOGGING` (R__37) — TRUSTCENTER

## Decision: New File vs Append
- **Append to existing script**: simpler, but triggers full re-execution of that file
- **New script**: isolated, only runs when its content changes

## Deployment
Feature branch → dev | `develop` → tst | release PR to `main` → pst → prd
