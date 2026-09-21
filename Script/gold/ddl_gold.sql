/*

DDL Script: Create Gold layer Views

Script Purpose:
	This script create the views for gold layer in the data warehouse.
	The gold layer represents the final dimension and fact tables for star schema.

	Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

*/

IF OBJECT_ID ('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS

SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- Surrogate key to create primary key for the table
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	cl.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE 
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is a master for gender Information
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM 
	silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 cl
ON		  ci.cst_key = cl.cid;

GO

IF OBJECT_ID ('gold.dim_products', 'V') IS NOT NULL 
	DROP VIEW gold.dim_products;
GO


CREATE VIEW gold.dim_products AS

	SELECT 
		ROW_NUMBER() OVER(ORDER BY prd_start_dt, prd_key ) AS product_key,
		pn.prd_id AS product_id,
		pn.prd_key AS product_number,
		pn.prd_nm AS product_name,
		pn.cat_id AS category_id,
		pc.cat AS category,
		pc.subcat AS subcategory,
		pc.maintenance,
		pn.prd_cost AS cost,
		pn.prd_line AS product_line,
		pn.prd_start_dt AS start_date
	FROM 
		silver.crm_prd_info pn
	LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON		  pn.cat_id = pc.id
	WHERE pn.prd_end_dt IS NULL; -- Filter out all historical data
GO

IF OBJECT_ID ('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO


CREATE VIEW gold.fact_sales AS

	SELECT 
		sd.sls_ord_num AS order_number,
		pr.product_key,
		cu.customer_key,
		sd.sls_order_dt AS order_date,
		sd.sls_ship_dt AS ship_date,
		sd.sls_due_dt AS due_date,
		sd.sls_sales AS sales_amount,
		sd.sls_quantity AS quantity,
		sd.sls_price AS price
	FROM silver.crm_sales_details sd
	LEFT JOIN gold.dim_products pr				-- connecting surrogate product key to fact table
	ON		  sd.sls_prd_key = pr.product_number
	LEFT JOIN gold.dim_customers cu				-- connecting surrogate customer key to fact table
	ON		  	sd.sls_cust_id = cu.customer_id;
GO
