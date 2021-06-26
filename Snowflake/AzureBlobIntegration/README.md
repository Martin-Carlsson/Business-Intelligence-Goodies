# Connect Azure blobstorage to Snowflake

Video showing how to do it: https://www.youtube.com/watch?v=JMSxzrmzOB0

# In Azure
## Create blob
```
<blob_account> 
<container> 
<path>
```

Upload TEST_FILE_1.csv

## Find tenant ID
Azure Active Directory > Properties > Directory ID

# In Snowflake
## Switch context
```SQL
use role sysadmin;
create database if not exists dataload;
create schema if not exists dataload.external_table;
use database dataload; 
use schema external_table;
```

## Create file format
```SQL
CREATE FILE FORMAT CSV_FF TYPE = 'CSV' COMPRESSION = 'AUTO' FIELD_DELIMITER = ',' RECORD_DELIMITER = '\n' SKIP_HEADER = 0 FIELD_OPTIONALLY_ENCLOSED_BY = 'NONE' TRIM_SPACE = FALSE ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE ESCAPE = 'NONE' ESCAPE_UNENCLOSED_FIELD = '\134' DATE_FORMAT = 'AUTO' TIMESTAMP_FORMAT = 'AUTO' NULL_IF = ('\\N');
```

## Use role accountadmin
```SQL
use role accountadmin;
```

## Create storage integration
```SQL
CREATE STORAGE INTEGRATION AZURE_STORAGE_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = AZURE
  ENABLED = TRUE
  AZURE_TENANT_ID = '<tenant_id>'
  STORAGE_ALLOWED_LOCATIONS = ('azure://<blob_account>.blob.core.windows.net/<container>/');
```

## Get consent URL
```SQL
desc storage integration AZURE_STORAGE_INT;
```
Go to AZURE_CONSENT_URL

Write down AZURE_MULTI_TENANT_APP_NAME

# In Azure

## Add role for storage account
Access Control (IAM) > Add role assignment

**Role:** Storage Blob Data Contributor

# In Snowflake
## Create a stage
```SQL
create or replace stage azure_stage
  storage_integration = AZURE_STORAGE_INT
  url = 'azure://<blob_account>.blob.core.windows.net/<container>/'
  file_format = CSV_FF;
```

## Use role sysadmin
```SQL
use role sysadmin;
```

## Create an external table
```SQL
create or replace external table
  TEST_TABLE
  LOCATION = @azure_stage/files/
  FILE_FORMAT = CSV_FF;
```

## Test the external table
```SQL
SELECT 
  VALUE:c1::INTEGER AS ID,
  VALUE:c2::STRING AS NAME
FROM 
  TEST_TABLE;
```
# In Azure
## Create Storage Queue 
```
<queue_account> 
<container> 
```

## Create eventgrid

Storage account > Queue service > Queues

# In Snowflake
## Create notification integration
```SQL
CREATE NOTIFICATION INTEGRATION AZURE_NOTIFICATION_INT
  ENABLED = true
  TYPE = QUEUE
  NOTIFICATION_PROVIDER = AZURE_STORAGE_QUEUE
  AZURE_STORAGE_QUEUE_PRIMARY_URI = 'https://<queue_account>.queue.core.windows.net/<container>'
  AZURE_TENANT_ID = '<tenant_id>'
```

## Get consent URLRL
```SQL
desc notification integration AZURE_NOTIFICATION_INT;
```
Go to AZURE_CONSENT_URL

Write down app name

# In Azure

## Give access
Queues > Access Control (IAM) > Add role assignment

**Role:** Storage Queue Data Contributor

## Create eventgrid subscription

# In Snowflake
## Create External table with notification
```SQL
CREATE OR REPLACE EXTERNAL TABLE
  TEST_TABLE
  LOCATION = @azure_stage/files/
  INTEGRATION = 'AZURE_NOTIFICATION_INT'
  AUTO_REFRESH = TRUE
  FILE_FORMAT = CSV_FF; 
```

## Test the external table
```SQL
SELECT 
  VALUE:c1::INTEGER AS ID,
  VALUE:c2::STRING AS NAME
FROM 
  TEST_TABLE;
```

# In Azure
Upload TEST_FILE_2.csv

# In Snowflake
## Test the external table
```SQL
SELECT 
  VALUE:c1::INTEGER AS ID,
  VALUE:c2::STRING AS NAME
FROM 
  TEST_TABLE;
```
