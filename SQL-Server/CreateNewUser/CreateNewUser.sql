-- In master database

CREATE LOGIN <login_name> 
WITH PASSWORD = '<password>' 

-- In target database

CREATE USER <user_name>
FOR LOGIN <login_name> 
WITH DEFAULT_SCHEMA = dbo; 

GO

ALTER ROLE db_datareader ADD MEMBER <user_name>; 
ALTER ROLE db_datawriter ADD MEMBER <user_name>; 

-- Note, <login_name> will be the new username
