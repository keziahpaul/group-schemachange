# CI/CD & Deployment

## Pipeline Flow
1. Developer pushes to feature branch → **dev** deploy
2. Merge to `develop` → **tst** deploy
3. PR from `release/*` or `hotfix/*` to `main` → **pst** deploy, then **prd** deploy (sequential)
4. PRD deploy is gated by `DEPLOY_SCHEMA_CHANGE_FLAG == 'TRUE'` environment variable

## Workflow Structure (per environment)
1. Set env variables (Docker image reference)
2. Fetch common Jinja modules from JFrog Artifactory (clones common-lib repo for version, downloads zip)
3. Assume AWS IAM role via OIDC (`configure-aws-credentials`)
4. Fetch Snowflake private key + passphrase from AWS Secrets Manager
5. Dry run (`schemachange deploy --dry-run`)
6. Deploy (`schemachange deploy`)

## Self-Hosted Runners
- Non-prod: labels `[non-prod, deploy]`
- Prod: labels `[prod, deploy]`
- All jobs run inside a Docker container from ECR: `pexa-one-data-snowflake-au-common-lib:latest_prod`

## Streamlit Deployment
- Separate `workflow_dispatch` workflow with manual inputs (folder, environment, database, schema)
- Uses `utils/streamlit_app_artefacts_upload_to_stage.py` to PUT files to Snowflake internal stage

## Key Secrets & Variables
- **GitHub Secrets**: `ARTIFACTORY_TOKEN` (JFrog access)
- **AWS Secrets Manager**: `onedata_<deploy_env>_<env>_group_snowflake-github-user-private-key`, `...-passphrase`
- **GitHub Environment Variables**: `DEPLOY_SCHEMA_CHANGE_FLAG` (prd gate), `PROD_PEXAONEDATA_AWS_ACCOUNT`, `NONPROD_PEXAONEDATA_AWS_ACCOUNT`

## Adding New Scripts
1. Query `<ENV>_METADATA.SCHEMACHANGE.CHANGE_HISTORY` for the last script number
2. Create `R__<next_number>_<description>.sql` in the appropriate subdirectory
3. Use Jinja `{{in_sf_env}}` for environment-specific object names
4. Import shared macros with `{% from 'modules/<macro>.j2' import <macro> %}`
