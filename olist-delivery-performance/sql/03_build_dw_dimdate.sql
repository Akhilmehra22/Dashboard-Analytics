/* =============================================================
   DW SCHEMA + DIMDATE BUILD
   Source: none, this is a generated date spine, not derived
   from stg tables.
   ============================================================= */
 
USE OlistDB;
GO
 
CREATE SCHEMA dw;
GO
 
CREATE TABLE dw.DimDate (
    date_sk         INT PRIMARY KEY,
    full_date       DATE NOT NULL,
    year            INT NOT NULL,
    quarter         INT NOT NULL,
    month           INT NOT NULL,
    month_name      NVARCHAR(20) NOT NULL,
    day             INT NOT NULL,
    day_name        NVARCHAR(20) NOT NULL,
    day_of_week     INT NOT NULL,
    is_weekend      BIT NOT NULL
);
GO
 
/* Spine covers the real min/max order date range (2016-09-04 to
   2018-10-17), padded a few days on each side so no purchase
   date falls right at the boundary. */

;WITH date_spine AS (
    SELECT CAST('2016-09-01' AS DATE) AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date)
    FROM date_spine
    WHERE full_date < '2018-10-31'
)
INSERT INTO dw.DimDate (date_sk, full_date, year, quarter, month, month_name, day, day_name, day_of_week, is_weekend)
SELECT
    CONVERT(INT, FORMAT(full_date, 'yyyyMMdd')),
    full_date,
    YEAR(full_date),
    DATEPART(QUARTER, full_date),
    MONTH(full_date),
    DATENAME(MONTH, full_date),
    DAY(full_date),
    DATENAME(WEEKDAY, full_date),
    DATEPART(WEEKDAY, full_date),
    CASE WHEN DATEPART(WEEKDAY, full_date) IN (1,7) THEN 1 ELSE 0 END
FROM date_spine
OPTION (MAXRECURSION 1200);
GO
 

 --Sanity check
SELECT COUNT(*) AS row_count, MIN(full_date) AS earliest, MAX(full_date) AS latest
FROM dw.DimDate;
GO