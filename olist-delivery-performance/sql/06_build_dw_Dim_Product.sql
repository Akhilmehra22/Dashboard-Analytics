
/*	==============================================
	Dim_Product Build
	Source	: Stg.Products, stg.ProductTranslation
	Grain	: One product per row
	============================================== */


use OlistDB;
Go


Create table dw.Dim_Product (
Product_SK			Int Identity(1,1) Primary Key,
Product_NK			Nvarchar(50) Not Null,
ProductCategory		Nvarchar(50),
ProductPhotosQty	Int,
ProductWeight_g		Int,
productLength_cm	Int,
ProductHeight_cm	Int,
ProductWidth_cm		Int
);
Go

Insert into dw.Dim_Product (Product_NK,ProductCategory,ProductPhotosQty,ProductWeight_g,productLength_cm,ProductHeight_cm,ProductWidth_cm)

Select 
p.product_id,
pt.productCategoryTranslation,
p.product_photos_qty,
p.product_weight_g,
p.product_length_cm,
p.product_height_cm,
p.product_width_cm
From stg.Products p
Left Join stg.producttranslation pt on pt.ProductCategoryName = p.product_category_name; 
Go


-- Sanity check
Select *
from dw.Dim_Product