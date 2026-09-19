/*

Create Database and Schemas

This script creates a new database named 'datawarehouse' after checking if it already exists.
If database exists in the system, it is dropped and recreated. 
Moreover, this script sets up three schemas within the database: 'bronze', 'silver', and 'gold'

WARNING:
	Running this script will drop the entire 'datawarehouse' database if it exists.
	All the data in database will permanemtly deleted. 
	Proceed with caution and ensure you have proper backups before running this script.

*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'datawarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
