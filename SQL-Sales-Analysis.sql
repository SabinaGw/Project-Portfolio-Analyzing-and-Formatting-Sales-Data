-- Analyzing-and-Formatting-Sales-Data

-- The primary goal is to extract actionable insights that can inform business strategies and enhance overall performance

-- Filling in missing quantity data

CREATE TEMPORARY TABLE calculated_quantities AS
WITH missing_values AS (
  SELECT 
    product_id, 
    discount, 
    region,
    sales
  FROM orders 
  WHERE quantity IS NULL  -- Find rows with NULL quantity
),
unit_price AS (
  SELECT 
    o.product_id,
    o.discount, 
    o.region, 
    o.sales, 
    o.quantity, 
    o.sales / o.quantity AS unit_price 
  FROM orders AS o
  RIGHT JOIN missing_values AS m 
  ON o.product_id = m.product_id 
  AND o.discount = m.discount 
  WHERE o.quantity IS NOT NULL  -- Find rows with non-NULL quantity
)
SELECT 
  m.product_id, 
  m.discount, 
  m.region,
  m.sales, 
  ROUND((m.sales / u.unit_price), 0) AS calculated_quantity  -- Calculate missing quantity
FROM missing_values AS m 
INNER JOIN unit_price AS u 
ON m.product_id = u.product_id 
AND m.discount = u.discount;


-- Update table with calculated quantities

UPDATE orders
JOIN calculated_quantities
ON orders.product_id = calculated_quantities.product_id
AND orders.discount = calculated_quantities.discount
AND orders.sales = calculated_quantities.sales
SET orders.quantity = calculated_quantities.calculated_quantity
WHERE orders.quantity IS NULL;

-- Data Analysis. Main Questions:

-- 1. Total sales and profits for each year

SELECT 
    YEAR(order_date) AS total_year, 
    ROUND(SUM(sales), 2) AS total_revenue, 
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY total_year
ORDER BY total_year DESC;

-- 2. Total sales and profits per quarter

SELECT 
    YEAR(o.order_date) AS revenue_year,
    QUARTER(o.order_date) AS revenue_quarter,
    ROUND(SUM(o.sales), 2) AS total_sales
FROM orders AS o
LEFT JOIN products AS p
ON o.product_id = p.product_id
GROUP BY revenue_year, revenue_quarter
ORDER BY revenue_year DESC, revenue_quarter DESC;

-- Best performing quarters from 2011-2014

WITH cte AS (
  SELECT 
    QUARTER(o.order_date) AS revenue_quarter,
    ROUND(SUM(o.sales), 2) AS total_sales
  FROM orders AS o
  LEFT JOIN products AS p
  ON o.product_id = p.product_id
  GROUP BY revenue_quarter
  ORDER BY revenue_quarter DESC
)
SELECT 
  CASE 
    WHEN revenue_quarter = 1 THEN 'Q1'
    WHEN revenue_quarter = 2 THEN 'Q2'
    WHEN revenue_quarter = 3 THEN 'Q3'
    ELSE 'Q4'
  END AS quarters,
  total_sales
FROM cte
ORDER BY revenue_quarter DESC;

-- 3. Which region generates the highest sales and profits?

-- Total sales, profits, and profit margins by region

SELECT 
  region, 
  ROUND(SUM(sales - discount), 2) AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND((SUM(profit) / SUM(sales - discount)) * 100, 2) AS profit_margin
FROM orders
GROUP BY region
ORDER BY total_sales DESC;

-- Average Order Value (AOV) and Average Number of Products per Order by region

SELECT
  region,
  ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS average_order_value,
  ROUND(SUM(quantity) / COUNT(DISTINCT order_id), 2) AS average_products_per_order
FROM orders
GROUP BY region
ORDER BY average_order_value DESC;

-- 4. Which country and city bring in the highest sales and profits?

-- Top 10 countries' total sales and profits with their profit margins

SELECT 
  country, 
  ROUND(SUM(sales), 2) AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin
FROM orders
GROUP BY country
ORDER BY total_profit DESC
LIMIT 10;

-- Bottom 10 countries' total sales and profits

SELECT 
  country, 
  ROUND(SUM(sales), 2) AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin
FROM orders
GROUP BY country
ORDER BY total_profit ASC
LIMIT 10;

-- Top 10 cities' total sales and profits with their profit margins

SELECT 
  city,
  ROUND(SUM(sales), 2) AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin
FROM orders
GROUP BY city
ORDER BY total_profit DESC
LIMIT 10;

-- Bottom 10 cities' total sales and profits with their profit margins

SELECT 
  city,
  ROUND(SUM(sales), 2) AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit,
  ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin
FROM orders
GROUP BY city
ORDER BY total_profit ASC
LIMIT 10;

-- 5. What is the relationship between discount and sales, and what is the total discount per category?

-- Discount vs Avg Sales

SELECT 
  discount, 
  ROUND(AVG(sales), 2) AS avg_sales
FROM orders
GROUP BY discount
ORDER BY discount;

-- Correlation

WITH stats AS (
    SELECT 
        discount,
        AVG(sales) AS avg_sales,
        COUNT(*) AS n,
        SUM(discount) AS sum_x,
        SUM(AVG(sales)) OVER() AS sum_y,
        SUM(discount * AVG(sales)) OVER() AS sum_xy,
        SUM(discount * discount) AS sum_xx,
        SUM(AVG(sales) * AVG(sales)) OVER() AS sum_yy
    FROM orders
    GROUP BY discount
)
SELECT 
    (SUM(n) * SUM(sum_xy) - SUM(sum_x) * SUM(sum_y)) / 
    SQRT((SUM(n) * SUM(sum_xx) - SUM(sum_x) * SUM(sum_x)) * 
         (SUM(n) * SUM(sum_yy) - SUM(sum_y) * SUM(sum_y))) AS correlation_coefficient
FROM stats;


-- Most discounted categories

SELECT 
  p.category, 
  SUM(o.discount) AS total_discount
FROM orders AS o 
LEFT JOIN products AS p
ON o.product_id = p.product_id
GROUP BY category
ORDER BY total_discount DESC;

-- Most discounted subcategories

SELECT 
  p.sub_category, 
  SUM(o.discount) AS total_discount
FROM orders AS o 
LEFT JOIN products AS p
ON o.product_id = p.product_id
GROUP BY p.sub_category
ORDER BY total_discount DESC;

-- 6. Which category generates the highest sales and profits in each region and country?

-- Categories with their total sales, profits, and profit margins

SELECT 
  p.category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit,
  ROUND(SUM(o.profit) / SUM(o.sales) * 100, 2) AS profit_margin
FROM orders AS o 
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_profit DESC;

-- Highest total sales and profits per category in each region

SELECT 
  o.region,
  p.category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o 
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY o.region, p.category
ORDER BY total_profit DESC;

-- Highest total sales and profits per category in each country

SELECT 
  o.country,
  p.category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o 
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY o.country, p.category
ORDER BY total_profit DESC
LIMIT 20;

-- Lowest total sales and profits per category in each country

SELECT 
  o.country,
  p.category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o 
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY o.country, p.category
ORDER BY total_profit ASC
LIMIT 20;

-- 7. Which subcategory generates the highest sales and profits in each region and country?

-- Subcategories with their total sales, profits, and profit margins

SELECT 
  p.sub_category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit,
  ROUND(SUM(o.profit) / SUM(o.sales) * 100, 2) AS profit_margin
FROM orders AS o 
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY p.sub_category
ORDER BY total_profit DESC;

-- Subcategories with the highest total sales and profits in each region

SELECT 
  o.region,
  p.sub_category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY p.sub_category, o.region
ORDER BY total_profit DESC
LIMIT 20;

-- Subcategories with the lowest total sales and profits in each region

SELECT 
  o.region,
  p.sub_category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY p.sub_category, o.region
ORDER BY total_profit ASC
LIMIT 25;

-- Highest total sales and profits per subcategory in each country

SELECT 
  o.country,
  p.sub_category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY p.sub_category, o.country
ORDER BY total_profit DESC
LIMIT 20;

-- Lowest total sales and profits per subcategory in each country

SELECT 
  o.country,
  p.sub_category,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY p.sub_category, o.country
ORDER BY total_profit ASC
LIMIT 20;

-- 8. What are the most and least profitable products?

-- Top 10 most profitable products

SELECT 
  p.product_name,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC
LIMIT 10;

-- Top 10 least profitable products

SELECT 
  p.product_name,
  ROUND(SUM(o.sales), 2) AS total_sales,
  ROUND(SUM(o.profit), 2) AS total_profit
FROM orders AS o
LEFT JOIN products AS p 
ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_profit ASC
LIMIT 10;

-- 9. Which segment contributes the most to our profits and sales?

-- Segments ordered by total profits

SELECT 
  segment, 
  ROUND(SUM(sales), 2) AS total_sales, 
  ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY segment
ORDER BY total_profit DESC;

-- 10. How many unique customers do we have in total, and how many are there per region and country?

-- Total number of customers

SELECT 
  COUNT(DISTINCT customer_id) AS total_customers
FROM orders;

-- Total customers per region

SELECT 
  region, 
  COUNT(DISTINCT customer_id) AS total_customers
FROM orders
GROUP BY region
ORDER BY total_customers DESC;

-- Top 10 countries with the most customers

SELECT 
  country, 
  COUNT(DISTINCT customer_id) AS total_customers
FROM orders
GROUP BY country
ORDER BY total_customers DESC
LIMIT 10;

-- Top 10 countries with the fewest customers

SELECT 
  country, 
  COUNT(DISTINCT customer_id) AS total_customers
FROM orders
GROUP BY country
ORDER BY total_customers ASC
LIMIT 10;

-- 11. Which customers bring the most profit? 

-- Identify repeat purchases by customers

SELECT count(*) FROM(
SELECT 
  customer_id,
  COUNT(*) AS purchase_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY purchase_count DESC) returning_customers;

-- Top 10 customers who generated the most sales compared to total profits

SELECT 
  customer_id, 
  ROUND(SUM(sales), 2) AS total_sales,
  ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 20;

-- 12. What is the average delivery time per class and in total?

-- Average delivery time

SELECT 
  AVG(DATEDIFF(ship_date, order_date)) AS delivery_time
FROM orders;

-- Calculate delivery time and percentage of total orders

WITH delivery AS (
  SELECT 
    order_id,
    order_date,
    ship_date,
    DATEDIFF(ship_date, order_date) AS delivery_time,
    quantity
  FROM orders
),
total_orders AS (
  SELECT COUNT(order_id) AS total_order_count FROM delivery
)
SELECT 
  delivery_time, 
  COUNT(order_id) AS order_count,
  ROUND((COUNT(order_id) / (SELECT total_order_count FROM total_orders)) * 100, 2) AS percentage_of_total
FROM delivery
GROUP BY delivery_time
ORDER BY delivery_time DESC;

-- Avg delivery time and standard deviation per region

SELECT 
  region,
  AVG(DATEDIFF(ship_date, order_date)) AS average_delivery_time,
  STDDEV(DATEDIFF(ship_date, order_date)) AS stddev_delivery_time
FROM orders
GROUP BY region
ORDER BY average_delivery_time ASC;

-- Avg delivery time per shipping mode

SELECT 
  ship_mode,
  AVG(DATEDIFF(ship_date, order_date)) AS avg_delivery_time
FROM orders
GROUP BY ship_mode
ORDER BY avg_delivery_time DESC;


