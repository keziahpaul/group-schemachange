# Security Guidelines

## Authentication
- Snowflake uses **key-pair authentication** (private key + passphrase)
- Keys are stored in **AWS Secrets Manager**, fetched at deploy time, written to a temp `.p8` file
- GitHub Actions uses **OIDC** for AWS IAM role assumption (no long-lived AWS credentials)

## Role Escalation
- The integration role (`<ENV>_GITHUB_INTEGRATION_ROLE_S`) is not an admin role
- Scripts that need `accountadmin` must explicitly grant and revoke it within the same script
- Always revoke elevated roles at the end of the script, even on failure paths

## Secrets in Snowflake
- Jira and Genesys secrets are created with **dummy values** via schemachange
- Actual credentials must be manually updated post-deployment from AWS Secrets Manager
- Never hardcode real credentials in SQL scripts

## Data Sharing
- Cross-account shares (e.g., Trust Center) are manually managed, not automated
- Share scripts should be parameterized with `{{in_sf_env}}` to avoid hardcoded environment prefixes

## Access Control
- Follow least-privilege: grant only required permissions per role
- Use database roles for data share access control
- Functional roles (`_f` suffix) for business users, service roles (`_s` suffix) for integrations

## Sensitive Config
- AWS account IDs, IAM role ARNs, and external IDs are in schemachange config files
- Slack notification email addresses are in config — treat as internal-only
- JFrog Artifactory token is a GitHub repository secret
