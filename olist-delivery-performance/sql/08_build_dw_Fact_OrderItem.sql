
/*	=====================================================
	Dw.Fact_OrderItem Build
	Source	: stg.orders , stg.orderItem
	Grain	: One Row per order Item of Delivered Orders
	===================================================== */
Use OlistDB;
Go


Create Table dw.Fact_OrderItem (
	OrderItem_SK				Int Identity(1,1) Primary Key,
	Order_NK					NVarchar(50) Not Null,
	OrderItem_NK				Int Not Null,
	Product_SK					Int,
	Customer_SK					Int,
	Seller_SK					Int,
	Purchase_Date_SK			Int,
	Seller_Geo_SK				Int,
	Customer_Geo_SK				Int,
	Price						Money,
	FreightValue				Money,
	Shipping_Limit_Date			Datetime,
	Customer_Delivered_Date		DateTime,
	Carrier_Received_date		DateTime,	-- Order_delivered_carrier_date
	Estimated_delivery			DateTime,
	Is_Late_Order				Bit,		-- Order_estimated_delivery < order_delivered_customer_date
	Delivery_Delay_Days			Int,		-- Order_estimated_delivery - order_delivered_customer_date
	Carrier_Handoff_Days		Int,		-- order purchase - order_delivered_carrier_date
	Carrier_Transit_days		Int,		-- Order_delivered_carrier_date - Order_delivered_Date
	Is_Late_Carrier_handoff		Bit,		-- Carrier_delivered_date > shipping_Limit_date
	AvgReviewScore				Decimal(10,2)
	);
	Go

	Insert Into Dw.Fact_OrderItem (
	Order_NK,
	OrderItem_NK,
	Product_SK,
	Customer_SK,
	Seller_SK,
	Purchase_Date_SK,
	Seller_Geo_SK,
	Customer_Geo_SK,
	Price,
	FreightValue,
	Shipping_Limit_Date,
	Customer_Delivered_Date,
	Carrier_Received_date,
	Estimated_delivery,
	Is_Late_Order,
	Delivery_Delay_Days,
	Carrier_Handoff_Days,
	Carrier_Transit_days,
	Is_Late_Carrier_handoff,
	AvgReviewScore 
	)

Select
	oi.order_id,
	oi.order_item_id,
	p.Product_SK,
	c.Customer_SK,
	s.Seller_SK,
	d.Date_SK,
	s.Geo_SK,
	cg.Geography_SK,
	oi.price,
	oi.freight_value,
	Cast(oi.shipping_limit_date As DateTime),
	Cast(o.order_delivered_customer_date As DateTime),
	Cast(o.order_delivered_carrier_date As DateTime),
	Cast(o.order_estimated_delivery_date As DateTime),
	Case When o.order_delivered_customer_date > o.order_estimated_delivery_date Then 1 Else 0 End,
	DateDiff(Day, Cast(o.order_estimated_delivery_date As Date), Cast(o.order_delivered_customer_date As Date)),
	DateDiff(Day, Cast(o.order_purchase_timestamp As Date), Cast(o.order_delivered_carrier_date As Date)),
	DateDiff(Day, Cast(o.order_delivered_carrier_date As Date), Cast(o.order_delivered_customer_date As Date)),
	Case When o.order_delivered_carrier_date > oi.shipping_limit_date Then 1 Else 0 End,
	r.score

From stg.OrderItem Oi
Left Join stg.Orders		o	On o.order_id			= oi.order_id
Left Join stg.Customers		cs	On cs.customer_id		= o.customer_id
Left Join dw.Dim_Product	p	On p.Product_NK			= oi.product_id
Left Join dw.Dim_Customer	c	On c.Customer_NK		= cs.customer_unique_id
Left Join dw.Dim_Seller		s	On s.Seller_NK			= oi.seller_id
Left Join dw.Dim_Date		d	On d.FullDate			= Cast(o.order_purchase_timestamp As Date)
Left Join dw.Dim_Geography	cg	On cg.ZipCode			= cs.customer_zip_code_prefix
Left Join (	Select 
				order_id, Avg(review_score * 1.0) As score
			From stg.OrderReview
			Group By order_id ) r On r.order_id = o.order_id

Where o.order_status = 'delivered'
  And o.order_delivered_customer_date Is Not Null
  And o.order_delivered_carrier_date Is Not Null;
Go

-- Sanity Check
Select Count(*) From dw.Fact_OrderItem;
select count(*) From stg.OrderItem oi left join stg.Orders o on o.order_id = oi.order_id

Where o.order_status = 'delivered'
  And o.order_delivered_customer_date Is Not Null
  And o.order_delivered_carrier_date Is Not Null