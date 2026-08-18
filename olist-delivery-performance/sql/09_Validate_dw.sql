/*	=====================================================
	DW Validation Script
	Purpose	: Confirm star schema integrity before adding
			  FK constraints and indexes
	Expected: Zero orphans, nulls within documented bounds,
			  measures within possible ranges
	===================================================== */

Use OlistDB;
Go

-- Block 1: Row Count Reconciliation
-- Fact row count must match delivered order items from source
Select 'Fact_OrderItem'		As TableName, Count(*) As RowCounts From dw.Fact_OrderItem
Union All
Select 'Source (delivered)'	As TableName, Count(*)
From stg.OrderItem Oi
Left Join stg.Orders o On o.order_id = oi.order_id
Where o.order_status = 'delivered'
  And o.order_delivered_customer_date Is Not Null
  And o.order_delivered_carrier_date Is Not Null;
Go

-- Block 2: Referential Integrity
-- All FailCounts must be zero
Select 'Orphaned Product_SK'		As Check_Name, Count(*) As FailCount
From dw.Fact_OrderItem f
Left Join dw.Dim_Product p On p.Product_SK = f.Product_SK
Where f.Product_SK Is Not Null And p.Product_SK Is Null
Union All
Select 'Orphaned Customer_SK',		Count(*)
From dw.Fact_OrderItem f
Left Join dw.Dim_Customer c On c.Customer_SK = f.Customer_SK
Where f.Customer_SK Is Not Null And c.Customer_SK Is Null
Union All
Select 'Orphaned Seller_SK',		Count(*)
From dw.Fact_OrderItem f
Left Join dw.Dim_Seller s On s.Seller_SK = f.Seller_SK
Where f.Seller_SK Is Not Null And s.Seller_SK Is Null
Union All
Select 'Orphaned Purchase_Date_SK',	Count(*)
From dw.Fact_OrderItem f
Left Join dw.Dim_Date d On d.Date_SK = f.Purchase_Date_SK
Where f.Purchase_Date_SK Is Not Null And d.Date_SK Is Null;
Go

-- Block 3: Null Rates On Key Columns
-- Customer/Product/Seller/Date SKs must be zero
-- Customer_Geo and Seller_Geo nulls are expected and documented:
--   157 customer zips and 7 seller zips had no geolocation match
-- ReviewScore nulls expected: not every customer leaves a review
Select
	Count(*)													As TotalRows,
	Sum(Case When Customer_SK		Is Null Then 1 Else 0 End)	As Null_Customer_SK,
	Sum(Case When Product_SK		Is Null Then 1 Else 0 End)	As Null_Product_SK,
	Sum(Case When Seller_SK			Is Null Then 1 Else 0 End)	As Null_Seller_SK,
	Sum(Case When Purchase_Date_SK	Is Null Then 1 Else 0 End)	As Null_Date_SK,
	Sum(Case When Customer_Geo_SK	Is Null Then 1 Else 0 End)	As Null_Customer_Geo,
	Sum(Case When Seller_Geo_SK		Is Null Then 1 Else 0 End)	As Null_Seller_Geo,
	Sum(Case When AvgReviewScore	Is Null Then 1 Else 0 End)	As Null_ReviewScore
From dw.Fact_OrderItem;
Go

-- Block 4: Measure Sanity
-- Price must never be negative
-- Delay range expected roughly -200 to +200 days
-- Review score must stay between 1.00 and 5.00
-- Late order count expected around 8,700 (order items, not orders)
-- Missed SLA count expected around 10,000
Select
	Min(Price)									As Min_Price,
	Max(Price)									As Max_Price,
	Min(Delivery_Delay_Days)					As Min_Delay,
	Max(Delivery_Delay_Days)					As Max_Delay,
	Min(AvgReviewScore)							As Min_Review,
	Max(AvgReviewScore)							As Max_Review,
	Sum(Cast(Is_Late_Order As Int))				As Total_Late_Orders,
	Sum(Cast(Is_Late_Carrier_Handoff As Int))	As Total_Missed_SLA
From dw.Fact_OrderItem;
Go