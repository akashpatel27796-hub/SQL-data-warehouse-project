/*
DATA SEGMENTATION ANALYSIS

Purpose:
	- To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL functions used:
	- CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.

segment products into cost range and 
count howmany products falls into each segment

*/

SELECT 
	cost_range,
	COUNT(product_id) AS total_products
FROM
(
SELECT
	product_id,
	product_name,
	cost,
	CASE
		WHEN cost < 100 THEN 'Below 100'
		WHEN cost BETWEEN 100 AND 499 THEN '100-499'
		WHEN cost BETWEEN 500 AND 999 THEN '500 - 999'
		ELSE 'Above 1000'
	END AS cost_range
FROM gold.dim_products
) t
GROUP BY cost_range
ORDER BY total_products DESC;


/*
Group customers into three segments based on their spending behaviour:
 VIP: customers with atleast 12 months of history and spending more than 5,000
 Regular: customers with atleast 12 months of history but spending 5,000 or less
 New: customers with life span of less than 12 months
 AND find the total number of customers for each group

*/

WITH customer_spending AS
	(
	SELECT
		c.customer_key,
		SUM(sales_amount) as total_spending,
		MIN(order_date) AS first_order,
		MAX(order_date) as last_order,
		DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan 

	FROM gold.fact_sales s
	LEFT JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
	GROUP BY 
		c.customer_key
	)
SELECT
	customer_segment,
	count(customer_key) AS total_customer
FROM
	(
	SELECT 
		customer_key,
		CASE
			WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
			WHEN lifespan > 12 AND total_spending <= 5000 THEN 'Regular'
			ELSE 'New'
		END AS customer_segment
	FROM customer_spending
	) t
GROUP BY customer_segment
ORDER BY total_customer DESC;
