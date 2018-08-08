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
	CAST(CONVERT(VARCHAR, [Date],112) AS INT) AS DateId,
	[Date],
	YEAR([DATE]) AS [Year],
	DATEPART(QUARTER, [Date]) AS [Quarter],
	DATEPART(MONTH, [Date]) AS [Month],
	DATEPART(WEEK, [Date]) AS [Week],
	CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, [Date]), 0) AS DATE) AS FirstDayOfMonth,
	DATENAME(dw,[Date]) AS [WeekDay],
	(DATEPART(dw,[Date])+ 5) % 7 + 1 AS DayInWeek 
FROM 
	DimDate 
ORDER BY
	[DATE] ASC
OPTION (MAXRECURSION 10000);
