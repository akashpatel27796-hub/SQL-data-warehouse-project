/*
PART TO WHOLE ANALYSIS

Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.

*/

-- Which categories contribute the most to the overall sales

WITH category_sales AS 
(
SELECT
	p.category category,
	SUM(s.sales_amount) AS Total_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY p.category
)

SELECT 
	category,
	Total_sales,
	SUM(Total_sales) OVER() Overall_sales,
	ROUND((CAST(Total_sales AS FLOAT)/ SUM(Total_sales) OVER()) * 100, 2) AS percent_of_total
FROM category_sales
ORDER BY Total_sales;

/*
PART TO WHOLE ANALYSIS

Which categories contribute the most to the overall orders

*/

WITH category_orders AS
(
SELECT
	category,
	SUM(quantity) as total_order
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY category
)

SELECT 
	category,
	total_order,
	SUM(total_order) OVER() AS overall_order,
	ROUND((CAST(total_order  AS FLOAT)/ SUM(total_order) OVER()) * 100, 2) AS percent_of_total
FROM category_orders
ORDER BY total_order DESC;

