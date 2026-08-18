
/*	====================================
	Dw.Dim_seller Build
	Source	: Stg.seller
	Grain	: One Row per seller
	==================================== */

Use OlistDB;
Go

Create table dw.Dim_Seller (
Seller_SK	Int Identity(1,1) Primary Key,
Seller_NK	Nvarchar(50) Not Null,
Geo_SK		Int Null
);
Go

Insert Into dw.Dim_Seller (Geo_Sk,Seller_NK)
Select 
	dg.Geography_SK,
	s.seller_id
from stg.Seller s
Left join dw.Dim_Geography dg on dg.ZipCode = s.seller_zip_code_prefix;
Go

--- Sanity Check
Select *
from dw.Dim_Seller
