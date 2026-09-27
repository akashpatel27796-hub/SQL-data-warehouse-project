/*
	Change Over Time Analysis:

	Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()

*/

-- Analyse sales over time

SELECT 
	year(order_date) order_year,
	month(order_date) order_month,
	SUM(sales_amount) total_sales,
	COUNT(DISTINCT customer_key) total_customers
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY year(order_date), month(order_date)
ORDER BY year(order_date), month(order_date)
