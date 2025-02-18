# Project-Portfolio-Analyzing-and-Formatting-Superstore-Sales-Data

## Project Description
This project involves reformatting and analyzing Superstore sales data to answer critical business questions while addressing issues such as incorrect data types and missing values. The primary goal is to extract actionable insights that can inform business strategies and enhance overall performance.

The analysis will utilize a combination of Excel, SQL, and PowerBI, following a structured approach to ensure comprehensive and reliable results. The process will encompass six key parts of data analysis:

* [Defining the Problems](#1-defining-the-problems)
* [Data Preparation](#2-data-preparation)
* [Data Cleaning and Processing](#3-data-cleaning-and-processing)
* [Data Analysis](#4-data-analysis)
* [Data Visualization](#5-data-visualization)
* [Recommendations](#6-recommendations)

  
## 1. Defining the Problems
#### Which products, locations, and customer segments should the company focus on and which should it avoid to maximize profits?
What trends are emerging and what recommendations can be made based on the analysis findings?

## 2. Data Preparation
* Data source: Datacamp.com 
* Superstore data includes two tables: orders and products
* Orders table contains 50,906 rows and 22 columns, covering orders from 2011-2014
* Products table contains 10,292 rows and 5 columns, covering products in 3 categories: technology, furniture, and office supplies

## 3. Data Cleaning and Processing
#### Tools: Excel, MySQL
* Observation of data in Excel
* Checking for missing data using filters and conditional formatting
* Removing duplicates
* Formatting columns (dates, numbers, currency)
* Filling in missing data in MySQL

  ```sql CREATE TEMPORARY TABLE calculated_quantities AS
WITH missing_values AS (
  SELECT product_id, 
         discount, 
         region,
         sales
  FROM orders 
  WHERE quantity IS NULL   -- Finding data with NULL quantity
),
unite_price AS (
  SELECT 
    o.product_id,
    o.discount, 
    o.market, 
    o.region, 
    o.sales, 
    o.quantity, 
    o.sales / o.quantity AS unite_price 
  FROM orders AS o
  RIGHT JOIN missing_values AS m 
  ON o.product_id = m.product_id 
  AND o.discount = m.discount 
  WHERE o.quantity IS NOT NULL  -- Finding data with not NULL quantity
)
SELECT 
  m.product_id, 
  m.discount, 
  m.region,
  m.sales, 
  ROUND((m.sales/u.unite_price), 0) AS calculated_quantity   -- Calculating quantity
FROM missing_values AS m 
INNER JOIN unite_price AS u 
ON m.product_id = u.product_id 
AND m.discount = u.discount;

-- Updating table with calculated quantity 

UPDATE orders
JOIN calculated_quantities
ON orders.product_id = calculated_quantities.product_id
AND orders.discount = calculated_quantities.discount
AND orders.sales = calculated_quantities.sales
SET orders.quantity = calculated_quantities.calculated_quantity
WHERE orders.quantity IS NULL;

## 4. Data Analysis
#### Methods: SQL for exploratory data analysis

### Main Questions:

#### Total Sales and Profits:
1. Total sales and profits per year
2. Total sales and profits per quarter

#### Geographic Analysis:
3. Highest sales and profits by region
4. Highest sales and profits by state and city
   
#### Product Analysis:
5. Most profitable categories and subcategories
6. Most profitable products
7. Gross margin analysis: calculating gross margin for different product categories
8. Price variability analysis: how price variability affects sales and profits

#### Customer Analysis:
9. Customer segments
10. Total number of customers
11. Customer retention analysis: repeat purchases and retention rates. Loyalty program

#### Sales Analysis:
12. Relationship between discounts and sales
13. Basket analysis: average order value and number of products per order

#### Delivery Time Analysis:
14. Delivery time of products (quantity and %)
15. Average delivery time
16. Differences in delivery time based on location
17. Deviation analysis
18. Type of products vs. delivery time

## 5. Data Visualization
#### Tool: PowerBI
Interactive dashboard in PowerBI based on collected data

## 6. Recommendations

#### Findings and Recommendations:

* Profits and sales are gradually improving, with Q4 being a key period
* Best performing regions are West and East; focus should be on these regions
* California, New York, and Washington are the most profitable states, while Texas, Ohio, and Pennsylvania incur losses
* Technology and Office Supplies are the best categories, while Furniture needs improvement
* Among subcategories, Copiers and Paper yield the highest profits, while Tables and Bookcases yield the highest losses
* Consumer segment yields the highest profits
* Loyalty program should reward the most loyal customers, even if they incur losses
