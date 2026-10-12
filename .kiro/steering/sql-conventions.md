# SQL Script Conventions

## Naming
- All scripts use **repeatable** naming: `R__<number>_<description>.sql`
- The number determines execution order (alphabetical within same number)
- Check `CHANGE_HISTORY` table for the last executed script number before adding new ones

## Jinja Templating
- All SQL scripts are Jinja2 templates processed by schemachange
- Environment variable `{{in_sf_env}}` (dev/tst/pst/prd) prefixes all object names
- Config vars are defined per-environment in `schemachange/config/<env>/schemachange-config.yml`
- Shared macros come from the common-lib repo via JFrog (not stored locally)

## Snowflake Roles
- Scripts run as `<ENV>_GITHUB_INTEGRATION_ROLE_S`
- When `accountadmin` is needed, it is granted temporarily and revoked at script end:
  ```sql
  use role securityadmin;
  grant role accountadmin to role {{in_sf_env}}_github_integration_role_s;
  -- ... do work ...
  use role securityadmin;
  revoke role accountadmin from role {{in_sf_env}}_github_integration_role_s;
  ```

## Environment Guards
- Use Jinja conditionals to restrict scripts to specific environments:
  ```sql
  {% if (in_sf_env.lower() == 'dev') or (in_sf_env.lower() == 'prd') %}
  -- env-specific SQL
  {% else %}
  select 1;
  {% endif %}
  ```

## Script Organization
- `account_objects/` — Storage integrations, network rules, access integrations, account-level RBAC
- `db_objects/` — Everything scoped to a database: schemas, stages, file formats, procedures, secrets, tables, views, external tables, tasks, notifications, streamlit apps, shares
- `masking_policies/` — Data masking (currently empty)
