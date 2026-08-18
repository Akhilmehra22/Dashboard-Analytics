/*	==============================================
	Dim_Geography Build
	Source	: stg.Geolocation
	Grain	: One row per zip code prefix
	City and state sourced from geolocation mapping
	============================================== */

Use OlistDB;
Go

Drop Table If Exists dw.Dim_Geography;
Go

Create Table dw.Dim_Geography (
	Geography_SK	Int Identity(1,1) Primary Key,
	ZipCode			Int Not Null,
	City			NVarchar(100) Null,
	[State]			NVarchar(10) Null,
	Latitude		Decimal(9,6) Null,
	Longitude		Decimal(9,6) Null
);
Go

;With Geo_Ranked As (
	Select
		geolocation_zip_code_prefix		As ZipCode,
		geolocation_city				As City,
		geolocation_state				As [State],
		Avg(geolocation_lat) Over (Partition By geolocation_zip_code_prefix) As Latitude,
		Avg(geolocation_lng) Over (Partition By geolocation_zip_code_prefix) As Longitude,
		Row_Number() Over (
			Partition By geolocation_zip_code_prefix
			Order By (Select Null)
		) As Rn
	From stg.Geolocation
)
Insert Into dw.Dim_Geography (ZipCode, City, [State], Latitude, Longitude)
Select ZipCode, City, [State], Latitude, Longitude
From Geo_Ranked
Where Rn = 1;
Go

-- Sanity check
Select ZipCode, Count(*)
From dw.Dim_Geography
Group By ZipCode
Having Count(*) > 1;
Go

Select Count(*) As TotalRows From dw.Dim_Geography;
Go