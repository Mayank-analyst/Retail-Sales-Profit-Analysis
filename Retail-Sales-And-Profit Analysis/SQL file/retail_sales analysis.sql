CREATE DATABASE retail_db;
USE retail_db;

CREATE TABLE retail_sales (
  order_id VARCHAR(20),
  order_date DATE,
  ship_date DATE,
  customer_id VARCHAR(20),
  customer_name VARCHAR(100),
  segment VARCHAR(50),
  region VARCHAR(50),
  category VARCHAR(50),
  sub_category VARCHAR(50),
  product_name VARCHAR(150),
  sales DECIMAL(10,2),
  quantity INT,
  discount DECIMAL(4,2),
  profit DECIMAL(10,2)
);

SHOW VARIABLES LIKE 'secure_file_priv';

DROP TABLE IF EXISTS retail_sales;

CREATE TABLE retail_sales (
  row_id INT,
  order_id VARCHAR(25),
  order_date DATE,
  ship_date DATE,
  ship_mode VARCHAR(50),
  customer_id VARCHAR(25),
  customer_name VARCHAR(100),
  segment VARCHAR(50),
  country VARCHAR(50),
  city VARCHAR(50),
  state VARCHAR(50),
  postal_code VARCHAR(20),
  region VARCHAR(50),
  product_id VARCHAR(25),
  category VARCHAR(50),
  sub_category VARCHAR(50),
  product_name VARCHAR(150),
  sales DECIMAL(10,2),
  quantity INT,
  discount DECIMAL(4,2),
  profit DECIMAL(10,2)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/retail_cleaned.csv'
INTO TABLE retail_sales
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
  ESCAPED BY '"'
LINES
  TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  row_id,
  order_id,
  @order_date,
  @ship_date,
  ship_mode,
  customer_id,
  customer_name,
  segment,
  country,
  city,
  state,
  postal_code,
  region,
  product_id,
  category,
  sub_category,
  product_name,
  @sales,
  quantity,
  @discount,
  @profit
)
SET
  order_date = STR_TO_DATE(TRIM(@order_date), '%m/%d/%Y'),
  ship_date  = STR_TO_DATE(TRIM(@ship_date), '%m/%d/%Y'),
  sales      = CAST(REPLACE(TRIM(@sales), '$', '') AS DECIMAL(10,2)),
  discount   = CAST(REPLACE(TRIM(@discount), '%', '') AS DECIMAL(4,2)),
  profit     = CAST(REPLACE(TRIM(@profit), '$', '') AS DECIMAL(10,2));


SELECT COUNT(*) FROM retail_sales;



# Display whole table/dataset.alter

SELECT * FROM retail_sales;

# LEVEL 1- BASIC QUERIES

# 1. What is the total sales, total profit, and total quantity sold?

SELECT 
      SUM(sales) as Total_sales,
      SUM(profit) as Total_profit,
      SUM(quantity) as Total_quantity
FROM retail_sales;
       
# 2. How many unique orders and unique customers are there?

SELECT 
      COUNT(DISTINCT order_id) as Unique_orders,
      COUNT(DISTINCT customer_id) as Unique_Customers
FROM retail_sales;      

# 3. What are the top 10 products by total sales?

SELECT 
	  product_name,
      SUM(sales) as Total_sales
FROM retail_sales
GROUP BY product_name
ORDER BY SUM(sales)
DESC LIMIT 10;     

# 4. Which categories generate the highest profit?

SELECT 
      category,
      SUM(profit) as Total_profit
FROM retail_sales 
GROUP BY category
ORDER BY Total_profit
DESC LIMIT 1;
      

# 5. Show sales and profit by region.

SELECT 
      region,
      SUM(sales) as Total_sales,
      SUM(profit) as Total_profit
FROM retail_sales
GROUP BY region;


# LEVEL 2- BUSINESS QUESTIONS

# 6. What is the monthly sales trend?
     
SELECT 
      YEAR(order_date) AS year,
      MONTH(order_date) AS month,
      SUM(sales) AS total_sales
FROM retail_sales
GROUP BY year, month
ORDER BY year, month;


# 7. Which sub-categories are loss-making overall?

SELECT 
	  sub_category,
      SUM(profit) as Total_profit
FROM retail_sales
GROUP BY sub_category
HAVING Total_profit<0;     

# 8. What is the average discount given by each category?

SELECT 
      Category,
      AVG(discount) as average_discount
FROM retail_sales
GROUP BY Category;
      
# 9. Which states contribute the most to total revenue?(Top 10)

SELECT 
      state,
      SUM(sales) as Total_revenue
FROM retail_sales
GROUP BY state
ORDER BY Total_revenue
DESC LIMIT 10;      

# 10. Who are the top 5 customers by total profit?

SELECT 
      customer_name,
      SUM(profit) as Total_profit
FROM retail_sales
GROUP BY customer_name
ORDER BY Total_profit
DESC LIMIT 5;      

# LEVEL 3 — Advanced Business Insights

# 11. Which products have high sales but low profit?

SELECT
    product_name,
    SUM(sales)  AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit) / SUM(sales), 2) AS profit_margin
FROM retail_sales
GROUP BY product_name
HAVING 
    SUM(sales) > (
        SELECT AVG(sales) FROM retail_sales
    )
    AND (SUM(profit) / SUM(sales)) < 0.10
ORDER BY total_sales DESC;

# 12. Rank products by total sales within each category

SELECT
    category,
    product_name,
	total_sales,
    RANK() OVER (
        PARTITION BY category
        ORDER BY total_sales DESC
    ) AS sales_rank
FROM (
    SELECT
        category,
        product_name,
        SUM(sales) AS total_sales
    FROM retail_sales
    GROUP BY category, product_name
) t;

# 13. What is the cumulative sales over time?

SELECT
    order_date,
    SUM(daily_sales) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM (
    SELECT
        order_date,
        SUM(sales) AS daily_sales
    FROM retail_sales
    GROUP BY order_date
) t
ORDER BY order_date;


# 14. Top 3 Customers by Profit in Each Region

SELECT
    region,
    customer_name,
    total_profit,
    profit_rank
FROM (
    SELECT
        region,
        customer_name,
        SUM(profit) AS total_profit,
        RANK() OVER (
            PARTITION BY region
            ORDER BY SUM(profit) DESC
        ) AS profit_rank
    FROM retail_sales
    GROUP BY region, customer_name
) t
WHERE profit_rank <= 3
ORDER BY region, profit_rank;

# 15. Months Where Sales Increased vs Previous Month

SELECT
    year,
    month,
    monthly_sales,
    LAG(monthly_sales) OVER (
        ORDER BY year, month
    ) AS previous_month_sales,
    (monthly_sales - LAG(monthly_sales) OVER (
        ORDER BY year, month
    )) AS sales_change
FROM (
    SELECT
        YEAR(order_date)  AS year,
        MONTH(order_date) AS month,
        SUM(sales) AS monthly_sales
    FROM retail_sales
    GROUP BY YEAR(order_date), MONTH(order_date)
) t
ORDER BY year, month;


