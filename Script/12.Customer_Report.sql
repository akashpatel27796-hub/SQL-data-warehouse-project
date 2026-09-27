/*
Customer Report

Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend

*/

IF OBJECT_ID ('gold.customer_report', 'V') IS NOT NULL 
	DROP VIEW gold.customer_report;

GO

CREATE VIEW gold.customer_report AS

WITH base_query AS
(
-- Retriving essential columns from customer tables
	SELECT
		s.order_number,
		s.product_key,
		s.order_date,
		s.sales_amount,
		s.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		DATEDIFF(year, c.birthdate, GETDATE()) AS age
	FROM
		gold.fact_sales s
	LEFT JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
	WHERE order_date IS NOT NULL
),
customer_aggregation AS
(
-- Customer Aggregation: summerizes key matrices at the customer level 
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM 
	base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
) 
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE
		WHEN age < 20 THEN 'Under 20'
		WHEN age BETWEEN 20 AND 35 THEN '20 - 35'
		WHEN age BETWEEN 36 AND 49 THEN '36 - 49'
		ELSE 'Above 50'
	END AS age_group,
	CASE
		WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		WHEN lifespan > 12 AND total_sales <= 5000 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment,
	last_order_date,
	DATEDIFF(month, last_order_date, GETDATE()) As recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
	-- calculate average order value (AOV)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_value,
	-- calculate average monthly spend
	CASE 
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
	END AS avg_monthly_spend
FROM customer_aggregation;
