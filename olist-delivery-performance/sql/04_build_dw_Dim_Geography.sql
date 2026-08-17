/* =============================================================
   Dim_Geography Build
   Source: stg.Customers
   Grain: one row per distinct zip/city/state combination.
   ============================================================= */

   USE OlistDB;
   GO

   Create table dw.Dim_Geography (
   Geography_sk			Int Primary Key Identity(1,1),
   ZipCode				Int Not Null,
   City					Nvarchar(50) Not Null,
   [State]				Nvarchar(50) Not Null
   );
   Go

  Insert into dw.Dim_Geography (ZipCode,City,[State])

  Select Distinct
	customer_zip_code_prefix,
	Customer_city,
	Customer_state
	
  From stg.Customers;
  Go


-- Sanity check
SELECT COUNT(*) FROM dw.Dim_Geography;
