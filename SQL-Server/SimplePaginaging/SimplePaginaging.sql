--Select top 100-200
--For a better option, see: https://stackoverflow.com/questions/109232/what-is-the-best-way-to-paginate-results-in-sql-server
SELECT * FROM (SELECT TOP 200 * FROM [AdventureWorksLT2012].[SalesLT].[Product] ORDER BY [ProductID]) t
EXCEPT
SELECT * FROM (SELECT TOP 100 * FROM [AdventureWorksLT2012].[SalesLT].[Product] ORDER BY [ProductID]) t
