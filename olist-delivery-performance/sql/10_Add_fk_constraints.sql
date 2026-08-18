/* =====================
    Create foreign Keys
    ==================== */
use OlistDB;
Go

Alter Table dw.Fact_OrderItem
    Add Constraint FK_Fact_Product	Foreign Key (Product_SK)		References dw.Dim_Product(Product_SK),
        Constraint FK_Fact_Customer	Foreign Key (Customer_SK)		References dw.Dim_Customer(Customer_SK),
        Constraint FK_Fact_Seller	Foreign Key (Seller_SK)			References dw.Dim_Seller(Seller_SK),
        Constraint FK_Fact_Date		Foreign Key (Purchase_Date_SK)	References dw.Dim_Date(Date_SK);
Go