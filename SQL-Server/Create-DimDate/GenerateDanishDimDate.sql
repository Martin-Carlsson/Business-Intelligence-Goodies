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
	YEAR([Date]) * 10000 + MONTH([Date]) * 100 + DAY([Date]) AS DatoInteger,
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
	CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, [Date]), 0) AS DATE) AS FoersteDagIMaaned,
	EOMONTH([Date]) AS SidsteDagIMaaned,
	DATEFROMPARTS(YEAR([Date]), 1, 1) AS FoersteDagIAar,
	DATEFROMPARTS(YEAR([Date]), 12, 31) AS SidsteDagIAar,
	CASE DATEPART(dw,[Date])
		WHEN 1 THEN 'Søndag'
		WHEN 2 THEN 'Mandag'
		WHEN 3 THEN 'Tirsdag'
		WHEN 4 THEN 'Onsdag'
		WHEN 5 THEN 'Torsdag'
		WHEN 6 THEN 'Fredag'
		WHEN 7 THEN 'Lørdag'
	END AS [UgeDag],
	(DATEPART(dw,[Date])+ 5) % 7 + 1 AS [UgeDagNummer]
	--INTO [dbo].[dimDate]
FROM 
	DimDate 
OPTION (MAXRECURSION 32767);
