-- Monthly Sales and Profit Trend
SELECT 
    DATE_FORMAT(order_date, '%M %Y') AS month_label,
    DATE_FORMAT(order_date, '%Y-%m-01') AS month_date,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY month_label, month_date
ORDER BY month_date;

-- Top 10 Customers by Profit
WITH cp AS 
(
    SELECT 
        c.customer_id,
        c.customer_name,
        ROUND(SUM(o.profit), 2) AS total_profit,
        RANK() OVER (ORDER BY SUM(o.profit) DESC) AS rk
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT 
    customer_name,
    total_profit
FROM cp
WHERE rk <= 10;

-- Best Sub-Category by Region (One per Region)
WITH subcat_sales AS (
    SELECT 
        l.region,
        p.sub_category,
        SUM(o.sales) AS total_sales,
        RANK() OVER (PARTITION BY l.region ORDER BY SUM(o.sales) DESC) AS rnk
    FROM orders o
    JOIN location l ON o.postal_code = l.postal_code
    JOIN products p ON o.product_id = p.product_id
    GROUP BY l.region, p.sub_category
)
SELECT 
    region,
    sub_category,
    ROUND(total_sales, 2) AS top_sales
FROM subcat_sales
WHERE rnk = 1;

-- Year-over-Year Sales Growth 
WITH yearly_sales AS (
    SELECT 
        YEAR(order_date) AS year,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY YEAR(order_date)
),
growth_calc AS (
    SELECT 
        year,
        total_sales,
        LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales
    FROM yearly_sales
)
SELECT 
    year,
    total_sales,
    ROUND(((total_sales - prev_year_sales) / prev_year_sales) * 100, 2) AS yoy_growth_pct
FROM growth_calc
WHERE prev_year_sales IS NOT NULL;

--  Customer Loyalty Tiering 
WITH order_counts AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT 
    c.customer_id, customer_name,
    CASE 
        WHEN total_orders >= 10 THEN 'Platinum'
        WHEN total_orders >= 5 THEN 'Gold'
        WHEN total_orders >= 2 THEN 'Silver'
    END AS loyalty_tier
FROM order_counts o 
join customers c on o.customer_id = c.customer_id
WHERE total_orders >= 2;

-- 3-Month Rolling Average Sales 
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m-01') AS month_start,
        ROUND(SUM(sales),2) AS total_sales
    FROM orders
    GROUP BY month_start
)
SELECT 
    month_start,
    total_sales,
    ROUND(AVG(total_sales) OVER (
        ORDER BY month_start 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3_month_avg
FROM monthly_sales;

-- Profit Per Unit by Sub-Category
SELECT 
    p.sub_category,
    ROUND(SUM(o.profit) / NULLIF(SUM(o.quantity), 0), 2) AS profit_per_unit
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.sub_category
HAVING profit_per_unit > 0
ORDER BY profit_per_unit DESC;



