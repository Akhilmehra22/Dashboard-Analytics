/*  =============================
    Create Indexes for performance
    ============================== */
use OlistDB;
Go

Create NonClustered Index IX_Fact_Product_SK
    On dw.Fact_OrderItem (Product_SK);
Go

Create NonClustered Index IX_Fact_Customer_SK
    On dw.Fact_OrderItem (Customer_SK);
Go
Create NonClustered Index IX_Fact_Seller_SK
    On dw.Fact_OrderItem (Seller_SK);
Go
Create NonClustered Index IX_Fact_Date_SK
    On dw.Fact_OrderItem (Purchase_Date_SK);
Go
Create NonClustered Index IX_Fact_Is_Late
    On dw.Fact_OrderItem (Is_Late_Order)
    Include (Delivery_Delay_Days, AvgReviewScore);
Go