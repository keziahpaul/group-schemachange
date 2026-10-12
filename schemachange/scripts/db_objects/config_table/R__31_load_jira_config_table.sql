use database {{in_sf_env}}_GROUP_RAW;
use schema jira;

CREATE TABLE IF NOT EXISTS JIRA_TABLE_CONFIGS (
	TABLE_NAME VARCHAR(255) NOT NULL,
	API_ENDPOINT VARCHAR(1000),
	TABLE_COLUMNS VARIANT,
	IS_ACTIVE BOOLEAN DEFAULT TRUE,
	CREATED_TIMESTAMP TIMESTAMP_NTZ(9) DEFAULT CAST(CONVERT_TIMEZONE('Australia/Melbourne', CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_TZ(9))) AS TIMESTAMP_NTZ(9)),
	MODIFIED_TIMESTAMP TIMESTAMP_NTZ(9) DEFAULT CAST(CONVERT_TIMEZONE('Australia/Melbourne', CAST(CURRENT_TIMESTAMP() AS TIMESTAMP_TZ(9))) AS TIMESTAMP_NTZ(9)),
	IS_PAGINATED BOOLEAN DEFAULT TRUE,
	primary key (TABLE_NAME)
)
 ; 

DELETE FROM JIRA_TABLE_CONFIGS;

-- FIELDS table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'FIELDS', '/rest/api/3/field', PARSE_JSON('[{"name": "clauseNames","type": "VARIANT"},{"name": "custom","type": "VARCHAR"},{"name": "id","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "navigable","type": "VARCHAR"},{"name": "orderable","type": "VARCHAR"},{"name": "schema","type": "VARIANT"},{"name": "searchable","type": "VARCHAR"}]'), true, '2025-05-26 18:47:28.797', '2025-05-26 18:47:28.797', true ; 

-- USERS table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'USERS', '/rest/api/3/users/search', PARSE_JSON('[{"name": "accountId","type": "VARCHAR"},{"name": "accountType","type": "VARCHAR"},{"name": "active","type": "VARCHAR"},{"name": "displayName","type": "VARCHAR"},{"name": "emailAddress","type": "VARCHAR"},{"name": "self","type": "VARCHAR"},{"name": "timeZone","type": "VARCHAR"},{"name": "locale","type": "VARCHAR"},{"name": "groups","type": "VARIANT"},{"name": "applicationRoles","type": "VARIANT"},{"name": "expand","type": "VARCHAR"},{"name": "avatarUrls","type": "VARIANT"}]'), true, '2025-05-26 19:17:10.986', '2025-05-26 19:17:10.986', true ; 

-- AGILE_BOARDS table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'AGILE_BOARDS', '/rest/agile/1.0/board', PARSE_JSON('[{"name": "id","type": "VARCHAR"},{"name": "self","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "type","type": "VARCHAR"},{"name": "location","type": "VARIANT"},{"name": "filtered","type": "VARCHAR"}]'), true, '2025-05-26 21:06:06.515', '2025-05-26 21:06:06.515', true ; 

-- GROUPS table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'GROUPS', '/rest/api/3/group/bulk', PARSE_JSON('[{"name": "name","type": "VARCHAR"},{"name": "groupId","type": "VARCHAR"},{"name": "self","type": "VARCHAR"},{"name": "users","type": "VARIANT"},{"name": "total","type": "NUMBER"}]'), true, '2025-05-26 21:17:32.559', '2025-05-26 21:17:32.559', true ; 

-- GROUP_USERS table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'GROUP_USERS', '/rest/api/3/group/member?groupname={groupname}', PARSE_JSON('[{"name": "self","type": "VARCHAR"},{"name": "accountId","type": "VARCHAR"},{"name": "emailAddress","type": "VARCHAR"},{"name": "displayName","type": "VARCHAR"},{"name": "active","type": "BOOLEAN"},{"name": "timeZone","type": "VARCHAR"},{"name": "accountType","type": "VARCHAR"},{"name": "avatarUrls","type": "VARIANT"},{"name": "groups","type": "VARIANT"},{"name": "applicationRoles","type": "VARIANT"},{"name": "groupName","type": "VARCHAR"}]'), true, '2025-05-27 10:54:14.830', '2025-05-27 10:54:14.830', true ; 

-- PRIORITIES table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'PRIORITIES', '/rest/api/3/priority/search', PARSE_JSON('[{"name": "id","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "description","type": "VARCHAR"},{"name": "iconUrl","type": "VARCHAR"},{"name": "statusColor","type": "VARCHAR"},{"name": "self","type": "VARCHAR"}]'), true, '2025-05-27 14:08:41.663', '2025-05-27 14:08:41.663', true ; 

-- PROJECT_CATEGORIES table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'PROJECT_CATEGORIES', '/rest/api/2/projectCategory', PARSE_JSON('[{"name": "id","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "description","type": "VARCHAR"},{"name": "self","type": "VARCHAR"}]'), true, '2025-05-27 14:11:58.646', '2025-05-27 14:11:58.646', true ; 

-- PROJECTS table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'PROJECTS', '/rest/api/2/project', PARSE_JSON('[{"name": "id","type": "VARCHAR"},{"name": "key","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "self","type": "VARCHAR"},{"name": "simplified","type": "BOOLEAN"},{"name": "style","type": "VARCHAR"},{"name": "avatarUrls","type": "VARIANT"},{"name": "insight","type": "VARIANT"},{"name": "projectCategory","type": "VARIANT"}]'), true, '2025-05-27 14:18:47.283', '2025-05-27 14:18:47.283', true ; 

-- RESOLUTIONS table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'RESOLUTIONS', '/rest/api/3/resolution/search', PARSE_JSON('[{"name": "id","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "description","type": "VARCHAR"},{"name": "isDefault","type": "BOOLEAN"}]'), true, '2025-05-27 14:20:59.420', '2025-05-27 14:20:59.420', true ; 

-- ISSUETYPES table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'ISSUETYPES', '/rest/api/2/issuetype', PARSE_JSON('[{"name": "id","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "description","type": "VARCHAR"},{"name": "self","type": "VARCHAR"},{"name": "iconUrl","type": "VARCHAR"},{"name": "hierarchyLevel","type": "VARCHAR"},{"name": "avatarId","type": "NUMBER"},{"name": "entityId","type": "VARCHAR"},{"name": "subtask","type": "VARCHAR"},{"name": "scope","type": "VARIANT"}]'), true, '2025-05-27 14:23:58.241', '2025-05-27 14:23:58.241', true ; 

-- ISSUELINKTYPES table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'ISSUELINKTYPES', '/rest/api/2/issueLinkType', PARSE_JSON('[{"name": "issueLinkTypes","type": "VARIANT"}]'), true, '2025-05-27 14:31:50.570', '2025-05-27 14:31:50.570', true ; 

-- STATUSCATEGORIES table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'STATUSCATEGORIES', '/rest/api/3/statuscategory', PARSE_JSON('[{"name": "id","type": "NUMBER"},{"name": "key","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "colorName","type": "VARCHAR"},{"name": "self","type": "VARCHAR"}]'), true, '2025-05-27 14:39:27.167', '2025-05-27 14:39:27.167', true ; 

-- STATUSES table
INSERT INTO JIRA_TABLE_CONFIGS (TABLE_NAME, API_ENDPOINT, TABLE_COLUMNS, IS_ACTIVE, CREATED_TIMESTAMP, MODIFIED_TIMESTAMP, IS_PAGINATED)
SELECT 'STATUSES', '/rest/api/3/statuses/search', PARSE_JSON('[{"name": "id","type": "VARCHAR"},{"name": "name","type": "VARCHAR"},{"name": "description","type": "VARCHAR"},{"name": "statusCategory","type": "VARCHAR"},{"name": "scope","type": "VARIANT"},{"name": "usages","type": "VARIANT"},{"name": "workflowUsages","type": "VARIANT"}]'), true, '2025-05-27 15:09:56.435', '2025-05-27 15:09:56.435', true ; 

