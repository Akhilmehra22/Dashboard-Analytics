/* =================================================
	Dim_Customer Build
	Source: Stg.Customers
	Grain: One customer per row
	================================================ */
Use OlistDB;
Go

Create table dw.Dim_Customer (
Customer_SK Int Identity(1,1) Primary Key,
Customer_NK NVarchar(50) Not Null
);
Go 

Insert Into dw.Dim_Customer (Customer_NK)
Select distinct customer_unique_id
from stg.Customers;
Go
