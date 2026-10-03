-- =====================================================================
-- Superstore Sales & Profitability Analysis — SQL queries
-- Author: Prathamesh Tirshu
-- Database: SQLite (sql/superstore.db, created by sql/load_to_sqlite.py)
-- Table: orders  (one row per order line)
-- =====================================================================

-- Q1. Overall business KPIs
SELECT COUNT(DISTINCT order_id)                       AS total_orders,
       COUNT(DISTINCT customer_name)                  AS total_customers,
       ROUND(SUM(sales), 0)                           AS total_sales,
       ROUND(SUM(profit), 0)                          AS total_profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 2)     AS profit_margin_pct,
       ROUND(SUM(sales) / COUNT(DISTINCT order_id), 0) AS avg_order_value
FROM orders;

-- Q2. Sales and profit by year, with year-over-year sales growth (window function LAG)
WITH yearly AS (
    SELECT strftime('%Y', order_date) AS year,
           SUM(sales)  AS sales,
           SUM(profit) AS profit
    FROM orders
    GROUP BY year
)
SELECT year,
       ROUND(sales, 0)  AS sales,
       ROUND(profit, 0) AS profit,
       ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY year)) / LAG(sales) OVER (ORDER BY year), 1) AS sales_growth_pct
FROM yearly
ORDER BY year;

-- Q3. Profitability by product category and sub-category
SELECT product_category,
       product_sub_category,
       ROUND(SUM(sales), 0)                       AS sales,
       ROUND(SUM(profit), 0)                      AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
FROM orders
GROUP BY product_category, product_sub_category
ORDER BY profit ASC;

-- Q4. Sales and profit by region, ranked (window function RANK)
SELECT region,
       ROUND(SUM(sales), 0)  AS sales,
       ROUND(SUM(profit), 0) AS profit,
       RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
FROM orders
GROUP BY region
ORDER BY profit_rank;

-- Q5. Impact of discount level on profit (CASE WHEN banding)
SELECT CASE
           WHEN discount = 0     THEN '0%'
           WHEN discount <= 0.03 THEN '1-3%'
           WHEN discount <= 0.06 THEN '4-6%'
           ELSE '7%+'
       END AS discount_band,
       COUNT(*)                                   AS order_lines,
       ROUND(AVG(profit), 1)                      AS avg_profit_per_line,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct,
       ROUND(100.0 * AVG(CASE WHEN profit < 0 THEN 1.0 ELSE 0 END), 1) AS pct_loss_making_lines
FROM orders
GROUP BY discount_band
ORDER BY MIN(discount);

-- Q6. Top 10 customers by sales, with their share of total sales
SELECT customer_name,
       customer_segment,
       ROUND(SUM(sales), 0) AS sales,
       ROUND(100.0 * SUM(sales) / (SELECT SUM(sales) FROM orders), 2) AS share_of_total_pct
FROM orders
GROUP BY customer_name, customer_segment
ORDER BY sales DESC
LIMIT 10;

-- Q7. Ten most loss-making products
SELECT product_name,
       product_sub_category,
       COUNT(*)              AS order_lines,
       ROUND(SUM(sales), 0)  AS sales,
       ROUND(SUM(profit), 0) AS profit
FROM orders
GROUP BY product_name, product_sub_category
HAVING SUM(profit) < 0
ORDER BY profit ASC
LIMIT 10;

-- Q8. Shipping performance: average days to ship and shipping cost by ship mode and order priority
SELECT ship_mode,
       order_priority,
       COUNT(*)                                                     AS order_lines,
       ROUND(AVG(julianday(ship_date) - julianday(order_date)), 2) AS avg_days_to_ship,
       ROUND(AVG(shipping_cost), 2)                                 AS avg_shipping_cost
FROM orders
GROUP BY ship_mode, order_priority
ORDER BY ship_mode, avg_days_to_ship;

-- Q9. Customer segment performance
SELECT customer_segment,
       COUNT(DISTINCT customer_name)                   AS customers,
       ROUND(SUM(sales), 0)                            AS sales,
       ROUND(SUM(profit), 0)                           AS profit,
       ROUND(SUM(sales) / COUNT(DISTINCT customer_name), 0) AS sales_per_customer
FROM orders
GROUP BY customer_segment
ORDER BY sales DESC;

-- Q10. Best-selling sub-category in each region (CTE + ROW_NUMBER)
WITH ranked AS (
    SELECT region,
           product_sub_category,
           SUM(sales) AS sales,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sales) DESC) AS rn
    FROM orders
    GROUP BY region, product_sub_category
)
SELECT region, product_sub_category, ROUND(sales, 0) AS sales
FROM ranked
WHERE rn = 1
ORDER BY sales DESC;
