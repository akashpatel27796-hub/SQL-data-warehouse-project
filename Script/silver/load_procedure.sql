/*
Stored Procedure: Load Silver Layer from Bronze Layer

Script Purpose:
	This stored procedure perform the ETL (Extract, Transform, Load) process to 
	populate the 'silver' schema tables from bronze schema.
	Action Performed:
		- Truncates silver tables.
		- Insert transformed and cleaned data from bronze tables.

Usage Guidance:
	EXEC silver.load_silver

*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

	TRUNCATE TABLE silver.crm_cust_info;

	INSERT INTO silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date)

	SELECT
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname, -- Removed Unncessary spaces from the name
		CASE 
			WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			ELSE 'n/a'
		END AS cst_marital_status, -- Normalise marital status to redable format
		CASE
			WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			ELSE 'n/a'
		END AS cst_gndr, -- Normalise gender values to redable format
		cst_create_date
	FROM 
	(
	SELECT 
		*,
		ROW_NUMBER () OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS ranking
	FROM 
		bronze.crm_cust_info
	WHERE 
		cst_id IS NOT NULL
	) t
	WHERE ranking = 1; -- removing the duplicate and updating the latest data to the silver layer


	TRUNCATE TABLE silver.crm_prd_info;

	INSERT INTO silver.crm_prd_info (
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
	)

	SELECT
		prd_id,
		REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Extrating Category ID
		SUBSTRING(prd_key, 7, len(prd_key)) AS prd_key, -- Extrating Product Key
		prd_nm,
		COALESCE(prd_cost, 0) AS prd_cost, -- Handling nulls in Int dataset
		CASE UPPER(TRIM(prd_line))
			WHEN 'M' THEN 'Mountain'
			WHEN 'R' THEN 'Road'
			WHEN 'S' THEN 'Other Sales'
			WHEN 'T' THEN 'Touring'
			ELSE 'n/a'
		END AS prd_line, -- Mapping product line codes to descriptive values
		CAST(prd_start_dt AS DATE) prd_start_dt,
		CAST(
			LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 
			AS DATE) 
		AS prd_end_dt -- Calculate end date as one day before the next start date
	FROM 
		bronze.crm_prd_info;


	TRUNCATE TABLE silver.crm_sales_details ;

	INSERT INTO silver.crm_sales_details (
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)
	select sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE 
			WHEN sls_order_dt = 0 OR LEN(sls_order_dt)  != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE) 
		END AS sls_order_dt,
		CASE 
			WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt)  != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE) 
		END As sls_ship_dt,
		 CASE 
			WHEN sls_due_dt = 0 OR LEN(sls_due_dt)  != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE) 
		END AS sls_due_dt,
		CASE 
			WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
				THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
		END AS sls_sales, -- Recalculate sales of original value is missing or negative 
		sls_quantity,
		CASE 
			WHEN sls_price IS NULL OR sls_price <=0 
				THEN sls_sales / NULLIF(sls_quantity, 0)
			ELSE sls_price
		END AS sls_price -- Derive price if original price is invalid
	from bronze.crm_sales_details;

	TRUNCATE TABLE silver.erp_cust_az12;

	INSERT INTO silver.erp_cust_az12 (
		cid,
		bdate,
		gen
	)

	SELECT 
		CASE 
			WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove NAS prefix from the ID 
			ELSE cid
		END AS cid,
		CASE 
			WHEN bdate > GETDATE() THEN NULL -- SET future bdate to NULL
			ELSE bdate
		END AS bdate,
		CASE 
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		ELSE 'n/a'
	END AS gen -- Normalise gender values and handle unknown cases
	FROM bronze.erp_cust_az12;

	TRUNCATE TABLE silver.erp_loc_a101;

	INSERT INTO silver.erp_loc_a101 (
		cid,
		cntry
	)

	SELECT 
		REPLACE(cid, '-', '') AS cid,
		CASE 
			WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
			WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
			ELSE TRIM(cntry)
		END AS cntry -- Normalise and Handle missing or blank country codes
	FROM 
		bronze.erp_loc_a101;

	TRUNCATE TABLE silver.erp_px_cat_g1v2;

	INSERT INTO silver.erp_px_cat_g1v2 (
		id,
		cat,
		subcat,
		maintenance
	)

	SELECT 
		id,
		cat,
		subcat,
		maintenance
	FROM 
		bronze.erp_px_cat_g1v2;
END
