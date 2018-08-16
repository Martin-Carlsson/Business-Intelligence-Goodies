--DROP TABLE [dbo].[dimDate];

DECLARE @FirstDate DATE = '20160101';
DECLARE @LastDate DATE = '20170101';

WITH DimDate
AS
(
	SELECT 
		@FirstDate AS [Date]

	UNION ALL

	SELECT 
		DATEADD(DAY,1, [Date] )  
	FROM 
		DimDate
	WHERE 
		[Date] < @LastDate
)
SELECT 
	[Date] AS [Dato],
	YEAR([DATE]) AS [Aar],
	DATEPART(QUARTER, [Date]) AS [Kvartal],
	CASE DATENAME(M,[Date])
		WHEN 'January' THEN 'Januar'
		WHEN 'February' THEN 'Februar'
		WHEN 'March' THEN 'Marts'
		WHEN 'April' THEN 'April'
		WHEN 'May' THEN 'Maj'
		WHEN 'June' THEN 'Juni'
		WHEN 'July' THEN 'Juli'
		WHEN 'August' THEN 'August'
		WHEN 'September' THEN 'September'
		WHEN 'October' THEN 'Oktober'
		WHEN 'November' THEN 'November'
		WHEN 'December' THEN 'December'
	END AS [Maaned],
	DATEPART(MONTH, [Date]) AS [MaanedNummer],
	DATEPART(WEEK, [Date]) AS [Uge],
	DATEPART(DAY, [Date]) AS [Dag],
	CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, [Date]), 0) AS DATE) AS FørsteDagIMaaned,
	DATENAME(dw,[Date]) AS [UgeDag],
	(DATEPART(dw,[Date])+ 5) % 7 + 1 AS [UgeDagNummer] 
	--INTO [dbo].[dimDate]
FROM 
	DimDate 
OPTION (MAXRECURSION 10000);
