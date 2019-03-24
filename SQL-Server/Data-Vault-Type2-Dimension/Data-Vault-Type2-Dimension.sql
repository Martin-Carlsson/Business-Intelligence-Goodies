--Demo for creating Type 2 dimensions from raw Data Vault

--Create database
USE master;
DROP DATABASE IF EXISTS DataVault;
CREATE DATABASE DataVault;
GO
USE DataVault;

GO

-- Add schemas
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Hub') EXEC('CREATE SCHEMA [Hub]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Sat') EXEC('CREATE SCHEMA [Sat]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Link') EXEC('CREATE SCHEMA [Link]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Newest') EXEC('CREATE SCHEMA [Newest]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Dim') EXEC('CREATE SCHEMA [Dim]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Fact') EXEC('CREATE SCHEMA [Fact]');
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'S') EXEC('CREATE SCHEMA [S]');

--Newest is a schema used for satalites and links that are filtered to only show the newest (or current) data
--S is a schema used for setup objects

GO

--Add hash function
CREATE OR ALTER FUNCTION [S].[Hash]
(
	@Key NVARCHAR(MAX)
)
RETURNS BINARY(32)
AS
BEGIN
	DECLARE @HashKey BINARY(32)

	IF @Key IS NULL
		SET @HashKey = HASHBYTES('SHA2_256','');
	ELSE 
		SET @HashKey = HASHBYTES('SHA2_256',LTRIM(RTRIM(UPPER(@Key))));

	RETURN @HashKey;
END;

GO

--Create Hub.Customer
CREATE OR ALTER VIEW Hub.Customer AS (
	SELECT 
		[S].[Hash]('1') AS CustomerHashKey,
		1 AS CustomerNumber
	UNION ALL
	SELECT 
		[S].[Hash]('2') AS CustomerHashKey,
		2 AS CustomerNumber
	UNION ALL
	SELECT 
		[S].[Hash]('3') AS CustomerHashKey,
		3 AS CustomerNumber
);

GO

SELECT '' AS 'Hub.Customer', * FROM Hub.Customer;

GO

--Create Sat.Customer
--Note the correction of the misspelling of Carlsson
CREATE OR ALTER VIEW Sat.Customer AS (
	SELECT 
		[S].[Hash]('1') AS CustomerHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		1 AS CustomerNumber,
		'Martin Karlsson' AS CustomerName
	UNION ALL
	SELECT
		[S].[Hash]('1') AS CustomerHashKey,
		CAST('2019-01-02' AS DATE) AS LoadDate,
		1 AS CustomerNumber,
		'Martin Carlsson' AS CustomerName
	UNION ALL
	SELECT 
		[S].[Hash]('2') AS CustomerHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		2 AS CustomerNumber,
		'Leonard Cohen' AS CustomerName
	UNION ALL
	SELECT
		[S].[Hash]('3') AS CustomerHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		3 AS CustomerNumber,
		'Nick Cave' AS CustomerName

);

GO

SELECT '' AS 'Sat.Customer', * FROM Sat.Customer;

GO

--Create Newest.SatCustomer
--Creating a view that only contains the newest (current) data
CREATE OR ALTER VIEW Newest.SatCustomer AS (
	SELECT 
		[Raw].* 
	FROM 
		Sat.Customer AS [Raw],
		(SELECT CustomerHashKey, MAX(LoadDate) AS LoadDate FROM Sat.[Customer] GROUP BY CustomerHashKey) AS New
	WHERE 
		[Raw].CustomerHashKey = New.CustomerHashKey
		AND [Raw].[LoadDate] = New.[LoadDate]
);

GO

SELECT '' AS 'Newest.SatCustomer', * FROM Newest.SatCustomer;

GO

--Create Dim.CustomerNameType1
--After creating the newest schema, it is easy to create a type 1 dimension
CREATE OR ALTER VIEW Dim.CustomerNameType1 AS (
	SELECT 
		CustomerHashKey,
		CustomerNumber,
		CustomerName
	FROM
		Newest.SatCustomer
);

GO

SELECT '' AS 'Dim.CustomerNameType1', * FROM Dim.CustomerNameType1;

GO
--Creating Hub.City
CREATE OR ALTER VIEW Hub.City AS (
	SELECT
		[S].[Hash]('1') AS CityHashKey,
		1 AS CityNumber
	UNION ALL
	SELECT
		[S].[Hash]('2') AS CityHashKey,
		2 AS CityNumber
);

GO

SELECT '' AS 'Hub.City', * FROM Hub.City;

GO

--Creating Sat.City
--Note that Aarhus changed its spelling back in 2010/2011
CREATE OR ALTER VIEW Sat.City AS (
	SELECT 
		[S].[Hash]('1') AS CityHashKey,
		CAST('2010-12-31' AS DATE) AS LoadDate,
		1 AS CityNumber,
		'Århus' AS CityName,
		'Midtjylland' AS RegionName
	UNION ALL
	SELECT
		[S].[Hash]('1') AS CityHashKey,
		CAST('2011-01-01' AS DATE) AS LoadDate,
		1 AS CityNumber,
		'Aarhus' AS CityName,
		'Midtjylland' AS RegionName
	UNION ALL
	SELECT 
		[S].[Hash]('2') AS CityHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		2 AS CityNumber,
		'Valby' AS CityName,
		'Hovedstaden' AS RegionName
);

GO

SELECT '' AS 'Sat.City', * FROM Sat.City;

GO

--Creating Newest.SatCity
CREATE OR ALTER VIEW Newest.SatCity AS (
	SELECT 
		[Raw].* 
	FROM 
		Sat.City AS [Raw],
		(SELECT CityHashKey, MAX(LoadDate) AS LoadDate FROM Sat.[City] GROUP BY CityHashKey) AS New
	WHERE 
		[Raw].CityHashKey = New.CityHashKey
		AND [Raw].[LoadDate] = New.[LoadDate]
);

GO

SELECT '' AS 'Newest.SatCity', * FROM Newest.SatCity;

GO

--Create Link.CustomerCity
--Note that Customner 1 moves from Aarhus to Valby
CREATE OR ALTER VIEW Link.CustomerCity AS (
	SELECT
		[S].[Hash]('1' + '1') AS CustomerCityHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
        [S].[Hash]('1') AS CustomerHashKey,
        [S].[Hash]('1') AS CityHashKey
    UNION ALL
    SELECT
		[S].[Hash]('1' + '2') AS CustomerCityHashKey,
		CAST('2019-02-01' AS DATE) AS LoadDate,
        [S].[Hash]('1') AS CustomerHashKey,
        [S].[Hash]('2') AS CityHashKey
    UNION ALL
    SELECT
		[S].[Hash]('2' + '1') AS CustomerCityHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
        [S].[Hash]('2') AS CustomerHashKey,
        [S].[Hash]('1') AS CityHashKey
    UNION ALL
    SELECT
		[S].[Hash]('3' + '2') AS CustomerCityHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
        [S].[Hash]('3') AS CustomerHashKey,
        [S].[Hash]('2') AS CityHashKey
);

GO

SELECT '' AS 'Link.CustomerCity', * FROM Link.CustomerCity;

GO

--Creating Newest.LinkCustomerCity
--Note, that this assumes a one-to-many relationship between city and customer 
--That is, a customer can only live in one city at a time, but multiple customers can live in the same city
CREATE OR ALTER VIEW Newest.LinkCustomerCity AS (
	SELECT 
		[Raw].* 
	FROM 
		Link.CustomerCity AS [Raw],
		(SELECT CustomerHashKey, MAX(LoadDate) AS LoadDate FROM Link.CustomerCity GROUP BY CustomerHashKey) AS New
	WHERE 
		[Raw].CustomerHashKey = New.CustomerHashKey
		AND [Raw].[LoadDate] = New.[LoadDate]
);

GO

SELECT '' AS 'Newest.LinkCustomerCity', * FROM Newest.LinkCustomerCity;

GO

--Create Dim.CustomerWithCityType1
CREATE OR ALTER VIEW Dim.CustomerWithCityType1 AS (
    SELECT
        LCC.CustomerHashKey AS HashKey,
        Customer.CustomerNumber,
        Customer.CustomerName,
        City.CityName,
        City.CityNumber
    FROM
        Newest.LinkCustomerCity LCC
        INNER JOIN Newest.SatCustomer Customer ON LCC.CustomerHashKey = Customer.CustomerHashKey
        INNER JOIN Newest.SatCity City ON LCC.CityHashKey = City.CityHashKey
);

GO

SELECT  '' AS 'Dim.CustomerWithCityType1', * FROM Dim.CustomerWithCityType1;

GO

--Create Hub.SalesTransaction 
--To create a dimension with Type 2, we also need a fact table
--The fact will be created on the basis of a Hub.SalesTransaction, Sat.SalesTransaction, and Link.SalesTransactionCustomer
--Note, this is a demonstration of Type 2 dimensions, in some (most) situations a transaction would be modeled as a link
CREATE OR ALTER VIEW Hub.SalesTransaction AS (
	SELECT 
		[S].[Hash]('1') AS TransactionHashKey,
		1 AS TransactionNumber
	UNION ALL
	SELECT 
		[S].[Hash]('2') AS TransactionHashKey,
		2 AS TransactionNumber
	UNION ALL
	SELECT 
		[S].[Hash]('3') AS TransactionHashKey,
		3 AS TransactionNumber
    UNION ALL
    	SELECT 
		[S].[Hash]('4') AS TransactionHashKey,
		4 AS TransactionNumber
	UNION ALL
	SELECT 
		[S].[Hash]('5') AS TransactionHashKey,
		5 AS TransactionNumber
	UNION ALL
	SELECT 
		[S].[Hash]('6') AS TransactionHashKey,
		6 AS TransactionNumber
);

GO

SELECT '' AS 'Hub.Transaction', * FROM Hub.SalesTransaction;

GO

CREATE OR ALTER VIEW Sat.SalesTransaction AS (
	SELECT 
		[S].[Hash]('1') AS SalesTransactionHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		1 AS SalesTransactionNumber,
        12 AS Quantity,
		10.1 AS Price
	UNION ALL
	SELECT 
		[S].[Hash]('2') AS SalesTransactionHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		2 AS SalesTransactionNumber,
        14 AS Quantity,
		9.9 AS Price
	UNION ALL
	SELECT 
		[S].[Hash]('3') AS SalesTransactionHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		3 AS SalesTransactionNumber,
        17 AS Quantity,
		15.0 AS Price
	UNION ALL
	SELECT 
		[S].[Hash]('4') AS SalesTransactionHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		4 AS SalesTransactionNumber,
        2 AS Quantity,
		1.1 AS Price
	UNION ALL
	SELECT 
		[S].[Hash]('5') AS SalesTransactionHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		5 AS SalesTransactionNumber,
        2 AS Quantity,
		5.2 AS Price
	UNION ALL
	SELECT 
		[S].[Hash]('6') AS SalesTransactionHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
		6 AS SalesTransactionNumber,
        1 AS Quantity,
		1.0 AS Price
);

GO

SELECT '' AS 'Sat.SalesTransaction', * FROM Sat.SalesTransaction;

GO

--Create Link.SalesTransactionCustomer
--One row per sales
CREATE OR ALTER VIEW Link.SalesTransactionCustomer AS (
	SELECT
		[S].[Hash]('1' + '1') AS SalesTransactionCustomerHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
        [S].[Hash]('1') AS SalesTransactionHashKey,
        [S].[Hash]('1') AS CustomerHashKey
    UNION ALL
	SELECT
		[S].[Hash]('2' + '1') AS SalesTransactionCustomerHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
        [S].[Hash]('2') AS SalesTransactionHashKey,
        [S].[Hash]('1') AS CustomerHashKey
    UNION ALL
	SELECT
		[S].[Hash]('3' + '2') AS SalesTransactionCustomerHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
        [S].[Hash]('3') AS SalesTransactionHashKey,
        [S].[Hash]('2') AS CustomerHashKey
    UNION ALL
	SELECT
		[S].[Hash]('4' + '3') AS SalesTransactionCustomerHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
        [S].[Hash]('4') AS SalesTransactionHashKey,
        [S].[Hash]('3') AS CustomerHashKey
    UNION ALL
	SELECT
		[S].[Hash]('5' + '2') AS SalesTransactionCustomerHashKey,
		CAST('2019-01-01' AS DATE) AS LoadDate,
        [S].[Hash]('5') AS SalesTransactionHashKey,
        [S].[Hash]('2') AS CustomerHashKey
    UNION ALL
	SELECT
		[S].[Hash]('6' + '1') AS SalesTransactionCustomerHashKey,
		CAST('2019-03-01' AS DATE) AS LoadDate,
        [S].[Hash]('6') AS SalesTransactionHashKey,
        [S].[Hash]('1') AS CustomerHashKey
);

GO

SELECT '' AS 'Link.SalesTransactionCustomer', * FROM Link.SalesTransactionCustomer;

GO

--Creating Fact.SalesWithType1Dimension
CREATE OR ALTER VIEW Fact.SalesWithType1Dimension AS (
    SELECT 
        SST.SalesTransactionNumber,
        LSTC.CustomerHashKey AS CustomerWithCityType1HashKey,
        SST.Quantity,
        SST.Price
    FROM
        Link.SalesTransactionCustomer LSTC
        INNER JOIN Sat.SalesTransaction SST ON LSTC.SalesTransactionHashKey = SST.SalesTransactionHashKey
    );

GO

SELECT ''AS 'Fact.SalesWithType1Dimension ', * FROM Fact.SalesWithType1Dimension 

GO

--As you can see Dim.CustomerWithCityType1 fits snugly with Fact.SalesWithType1Dimension
SELECT 
    Sales.SalesTransactionNumber,
    Customer.CustomerName,
    Customer.CityName,
    Sales.Quantity,
    Sales.Price
FROM
    Fact.SalesWithType1Dimension Sales
    INNER JOIN Dim.CustomerWithCityType1 Customer ON Sales.CustomerWithCityType1HashKey = Customer.HashKey;

GO

--Finally to the type 2 :)
--In this part we will treat customer name and city spelling as a type 1, and in what city the customer lived as a type 2
--Say, the business does not care about the history of a customers name or a city name - but the business wants to know in what city the customer lived, when he made the purchase


--Create Link.CustomerCityWithLoadEnd
--We first need to define a loadend date for our Link.CustomerCity
CREATE OR ALTER VIEW Link.CustomerCityWithLoadEnd AS (
    SELECT 
        *,
        COALESCE(LEAD(LoadDate) OVER (PARTITION BY CustomerHashKey ORDER BY LoadDate), '9999-12-31') AS LoadEndDate
    FROM 
        Link.CustomerCity
);

GO

SELECT '' AS 'Link.CustomerCityWithLoadEnd', * FROM Link.CustomerCityWithLoadEnd;

GO

--The fact needs to incorporate the correct load date
--Remember that customer 1 moved on 2019-02-01
--We see here that customer 1 uses LoadDate 2019-01-01 in SalesTransaction 1 and 2
--And customer 1 uses LoadDate 2019-02-01 in SalesTransaction 6
SELECT 
	SST.SalesTransactionNumber,
	HC.CustomerNumber,
	LC.LoadDate,
	SST.Quantity,
	SST.Price
FROM
	Link.SalesTransactionCustomer LSTC
	INNER JOIN Sat.SalesTransaction SST ON LSTC.SalesTransactionHashKey = SST.SalesTransactionHashKey
	INNER JOIN Hub.Customer HC ON LSTC.CustomerHashKey = HC.CustomerHashKey
	INNER JOIN Link.CustomerCityWithLoadEnd LC ON LSTC.CustomerHashKey = LC.CustomerHashKey
		AND LSTC.LoadDate BETWEEN LC.LoadDate AND LC.LoadEndDate;

GO

--Create Fact.SalesWithType2Dimension
--The CustomerNumber and LoadDate should be part of the key
--Note the difference between in CustomerWithCityType2HashKey between SalesTransactionNumber (1, 2) and 6 even though it is the same customer 
CREATE OR ALTER VIEW Fact.SalesWithType2Dimension AS (
	SELECT 
		SST.SalesTransactionNumber,
		S.[Hash](CONVERT(NVARCHAR, HC.CustomerNumber) + CONVERT(NVARCHAR, LC.LoadDate)) AS CustomerWithCityType2HashKey,
		SST.Quantity,
		SST.Price
	FROM
		Link.SalesTransactionCustomer LSTC
		INNER JOIN Sat.SalesTransaction SST ON LSTC.SalesTransactionHashKey = SST.SalesTransactionHashKey
		INNER JOIN Hub.Customer HC ON LSTC.CustomerHashKey = HC.CustomerHashKey
		INNER JOIN Link.CustomerCityWithLoadEnd LC ON LSTC.CustomerHashKey = LC.CustomerHashKey
			AND LSTC.LoadDate BETWEEN LC.LoadDate AND LC.LoadEndDate
);

GO

SELECT '' AS 'Fact.SalesWithType2Dimension', * FROM Fact.SalesWithType2Dimension;

GO

--Create Dim.CustomerWithCityType2
CREATE OR ALTER VIEW Dim.CustomerWithCityType2 AS (
    SELECT
		S.[Hash](CONVERT(NVARCHAR, Customer.CustomerNumber) + CONVERT(NVARCHAR, LCC.LoadDate)) AS HashKey,
        Customer.CustomerName,
		Customer.CustomerNumber,
        City.CityName,
        City.CityNumber
    FROM
        Link.CustomerCity LCC
        INNER JOIN Newest.SatCustomer Customer ON LCC.CustomerHashKey = Customer.CustomerHashKey
        INNER JOIN Newest.SatCity City ON LCC.CityHashKey = City.CityHashKey
);

GO

SELECT '' AS 'Dim.CustomerWithCityType2', * FROM Dim.CustomerWithCityType2 

GO

--As we can see, Customer "Martin Carlsson" lived in Aarhus in SalesTransactionNumber 1 and 2, but had moved to Valby at SalesTransactionNumber 6
SELECT 
    Sales.SalesTransactionNumber,
	Customer.CustomerNumber,
    Customer.CustomerName,
	Customer.CityNumber,
    Customer.CityName,
    Sales.Quantity,
    Sales.Price
FROM
    Fact.SalesWithType2Dimension Sales
    INNER JOIN Dim.CustomerWithCityType2 Customer ON Sales.CustomerWithCityType2HashKey = Customer.HashKey
ORDER BY
	Sales.SalesTransactionNumber;