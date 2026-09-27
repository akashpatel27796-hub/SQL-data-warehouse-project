/*

Product Report

Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue

*/
IF OBJECT_ID ('gold.product_report' , 'V') IS NOT NULL
    DROP VIEW gold.product_report;

GO

CREATE VIEW gold.product_report AS 

WITH base_query AS
(-- Retriving essential columns from product tables:
    SELECT
        s.order_number,
        s.order_date,
        s.customer_key,
        s.sales_amount,
        s.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM 
        gold.fact_sales s
    LEFT JOIN gold.dim_products p
    ON s.product_key = p.product_key
    WHERE order_date IS NOT NULL
),
product_aggregrations AS
(
-- Product Aggregations: Summarizes key metrics at the product level:
    SELECT 
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        MAX(order_date) AS last_order_date,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan,
        COUNT(DISTINCT order_number) AS total_orders,
        COUNT(DISTINCT customer_key) AS total_customers,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        ROUND(AVG(CAST(sales_amount AS FLOAT)/ COALESCE(quantity, 0)), 2) AS Avg_salling_price
    FROM 
        base_query
    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)

-- Combines all product results into one output:

SELECT
      product_key,
      product_name,
      category,
      subcategory,
      cost,
      last_order_date,
      DATEDIFF(month, last_order_date, GETDATE()) as recency,
      CASE
            WHEN total_sales > 50000 THEN 'High-Performers'
            WHEN total_sales <= 10000 THEN 'Mid-Range'
            ELSE 'Low-Performers'
      END AS product_category,
      lifespan,
      total_orders,
      total_customers,
      total_sales,
      total_quantity,
      Avg_salling_price,
      -- Average Order Revenue (AOR)
      CASE 
            WHEN total_orders = 0 THEN 0
            ELSE total_sales / total_orders
      END AS average_order_revenue,
      -- Average monthly Revenue
      CASE 
            WHEN lifespan = 0 THEN 0
            ELSE total_sales / lifespan
      END AS avg_monthly_revenue
FROM 
    product_aggregrations;
