-- Analysis - I

-- 1.To simplify its financial reports, Amazon India needs to standardize payment values.
-- Round the average payment values to integer (no decimal) for each payment type and display the results sorted in ascending order.
SELECT payment_type, round(avg(payment_value),0) as rounded_avg_payment
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY rounded_avg_payment;

-- 2.To refine its payment strategy, Amazon India wants to know the distribution of orders by payment type. 
-- Calculate the percentage of total orders for each payment type, rounded to one decimal place, and display them in descending order
SELECT payment_type, round((count(*) * 100) / sum(count(*)) over(),1) as percentage_orders
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY percentage_orders desc;

-- 3.Amazon India seeks to create targeted promotions for products within specific price ranges.
-- Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name. Display these products, sorted by price in descending order.
SELECT o.product_id , o.price
FROM amazon_brazil.order_items o
INNER JOIN amazon_brazil.product p
ON o.product_id = p.product_id AND p.product_category_name like '%smart%'
WHERE o.price BETWEEN 100 AND 500
ORDER BY o.price desc;

-- 4.To identify seasonal sales patterns, Amazon India needs to focus on the most successful months.
-- Determine the top 3 months with the highest total sales value, rounded to the nearest integer.
SELECT to_char(o.order_purchase_timestamp,'MM') as month ,  sum(oi.price) as total_sales
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi
ON o.order_id = oi.order_id
GROUP BY month
ORDER BY total_sales desc
LIMIT 3;

-- 5.Amazon India is interested in product categories with significant price variations.
-- Find categories where the difference between the maximum and minimum product prices is greater than 500 BRL.
SELECT p.product_category_name , max(oi.price) - min(oi.price) as price_difference
FROM amazon_brazil.product p
JOIN amazon_brazil.order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_category_name
HAVING  max(oi.price) - min(oi.price) > 500
ORDER BY price_difference desc;

-- 6.To enhance the customer experience, Amazon India wants to find which payment types have the most consistent transaction amounts.
-- Identify the payment types with the least variance in transaction amounts, sorting by the smallest standard deviation first.
SELECT payment_type, round(STDDEV(payment_value),2) as std_deviation
FROM amazon_brazil.payments
GROUP BY payment_type
ORDER BY std_deviation asc;

-- 7.Amazon India wants to identify products that may have incomplete name in order to fix it from their end.
-- Retrieve the list of products where the product category name is missing or contains only a single character.
SELECT product_id , product_category_name 
FROM amazon_brazil.product
WHERE product_category_name IS NULL
OR LENGTH(product_category_name) = 1;


-- Analysis - II

-- 1.Amazon India wants to understand which payment types are most popular across different order value segments (e.g., low, medium, high).
-- Segment order values into three ranges: orders less than 200 BRL, between 200 and 1000 BRL, and over 1000 BRL. 
-- Calculate the count of each payment type within these ranges and display the results in descending order of count
WITH order_value AS (
SELECT oi.order_id , sum(oi.price + oi.freight_value) as order_value
FROM amazon_brazil.order_items oi
GROUP BY oi.order_id
),
Segment_table AS(
SELECT ov.order_id , 
CASE 
	WHEN ov.order_value < 200 THEN 'Low'
	WHEN ov.order_value BETWEEN 200 AND 1000 THEN 'Medium'
	ELSE 'High'
END AS order_value_segment
FROM order_value ov
)
SELECT st.order_value_segment , p.payment_type , count(p.payment_type) as count
FROM segment_table st
JOIN amazon_brazil.payments p
ON st.order_id = p.order_id
GROUP BY st.order_value_segment,p.payment_type
ORDER BY count desc;

-- 2.Amazon India wants to analyse the price range and average price for each product category.
-- Calculate the minimum, maximum, and average price for each category, and list them in descending order by the average price.
SELECT p.product_category_name, min(oi.price) as min_price, max(oi.price) as max_price , round(avg(oi.price),2) as avg_price
FROM amazon_brazil.product p
LEFT JOIN amazon_brazil.order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY avg_price desc;

-- 3.Amazon India wants to identify the customers who have placed multiple orders over time.
-- Find all customers with more than one order, and display their customer unique IDs along with the total number of orders they have placed.
SELECT c.customer_unique_id, count(o.order_id) as total_orders
FROM amazon_brazil.customer c
JOIN amazon_brazil.orders o
ON c.customer_id = o.customer_id 
GROUP BY c.customer_unique_id
HAVING count(o.order_id) > 1
ORDER BY total_orders desc;

-- 4.Amazon India wants to categorize customers into different types 
-- ('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) based on their purchase history.
-- Use a temporary table to define these categories and join it with the customers table to update and display the customer types.
WITH categorize_customer AS (
SELECT c.customer_unique_id, count(o.order_id) as total_orders
FROM amazon_brazil.customer c
JOIN amazon_brazil.orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
)
SELECT cc.customer_unique_id,
CASE
	WHEN cc.total_orders = 1 THEN 'New'
	WHEN cc.total_orders BETWEEN 2 AND 4 THEN 'Returning'
	ELSE 'Loyal'
END AS customer_type
FROM categorize_customer cc;


-- 5.Amazon India wants to know which product categories generate the most revenue.
-- Use joins between the tables to calculate the total revenue for each product category. Display the top 5 categories.
SELECT p.product_category_name , sum(oi.price + oi.freight_value) as total_revenue
FROM amazon_brazil.product p
JOIN amazon_brazil.order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue desc
LIMIT 5;


-- Analysis - III

-- 1.The marketing team wants to compare the total sales between different seasons. 
-- Use a subquery to calculate total sales for each season (Spring, Summer, Autumn, Winter) based on order purchase dates, and display the results. 
-- Spring is in the months of March, April and May. Summer is from June to August and Autumn is between September and November and rest months are Winter. 
SELECT season , sum(total_sales) as total_sales 
FROM (
	SELECT 
		CASE
			WHEN EXTRACT(Month FROM o.order_purchase_timestamp) IN (3,4,5) THEN 'Spring'
			WHEN EXTRACT(Month FROM o.order_purchase_timestamp) IN (6,7,8) THEN 'Summer'
			WHEN EXTRACT(Month FROM o.order_purchase_timestamp) IN (9,10,11) THEN 'Autumn'
			ELSE 'Winter'
		END AS season , oi.price as total_sales
		FROM amazon_brazil.orders o
		JOIN amazon_brazil.order_items oi
		ON o.order_id = oi.order_id
) AS Season_sales
GROUP BY season
ORDER BY total_sales desc;

-- 2.The inventory team is interested in identifying products that have sales volumes above the overall average. 
-- Write a query that uses a subquery to filter products with a total quantity sold above the average quantity.
SELECT product_id , sum(order_item_id) as total_quantity_sold
FROM amazon_brazil.order_items
GROUP BY product_id
HAVING sum(order_item_id) > (SELECT avg(total_quantity) 
		FROM (
		SELECT sum(order_item_id) as total_quantity
		FROM amazon_brazil.order_items
		GROUP BY product_id
		))
ORDER BY total_quantity_sold desc;

-- 3.To understand seasonal sales patterns, the finance team is analysing the monthly revenue trends over the past year (year 2018).
-- Run a query to calculate total revenue generated each month and identify periods of peak and low sales. 
-- Export the data to Excel and create a graph to visually represent revenue changes across the months. 
SELECT to_char(o.order_purchase_timestamp,'YYYY-MM') as month , sum(oi.price + oi.freight_value) as total_revenue
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi
ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
GROUP BY to_char(o.order_purchase_timestamp,'YYYY-MM')
ORDER BY month;

-- 4.A loyalty program is being designed  for Amazon India.
-- Create a segmentation based on purchase frequency: ‘Occasional’ for customers with 1-2 orders, ‘Regular’ for 3-5 orders, and ‘Loyal’ for more than 5 orders. 
-- Use a CTE to classify customers and their count and generate a chart in Excel to show the proportion of each segment.
WITH customer_segment AS (
	SELECT customer_id, count(order_id) as order_count,
		CASE
			WHEN COUNT(order_id) <= 2 THEN 'Occasional'
			WHEN COUNT(order_id) BETWEEN 3 AND 5 THEN 'Regular'
			ELSE 'Loyal'
		END AS customer_type
	FROM amazon_brazil.orders o
	GROUP BY customer_id
)
SELECT customer_type, count(*) as count
FROM customer_segment 
GROUP BY customer_type
ORDER BY count desc;

-- 5.Amazon wants to identify high-value customers to target for an exclusive rewards program.
-- You are required to rank customers based on their average order value (avg_order_value) to find the top 20 customers.
WITH high_value_customers AS (
SELECT o.customer_id , round(avg(oi.price + oi.freight_value),2) as avg_order_value , dense_rank() over(order by avg(oi.price + oi.freight_value) desc) as customer_rank
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi
ON o.order_id = oi.order_id
GROUP BY customer_id )
SELECT * FROM high_value_customers
WHERE customer_rank <=20
ORDER BY avg_order_value desc;

-- 6.Amazon wants to analyze sales growth trends for its key products over their lifecycle. 
-- Calculate monthly cumulative sales for each product from the date of its first sale. 
-- Use a recursive CTE to compute the cumulative sales (total_sales) for each product month by month.
WITH RECURSIVE sales_data AS (
    SELECT
        oi.product_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS sale_month,
        SUM(oi.price) AS monthly_sales
    FROM amazon_brazil.order_items oi
    JOIN amazon_brazil.orders o ON oi.order_id = o.order_id
    GROUP BY oi.product_id, sale_month
),
recursive_sales AS (
    SELECT
        s.product_id,
        s.sale_month,
        s.monthly_sales AS total_sales
    FROM sales_data s
    WHERE s.sale_month = (
        SELECT MIN(s2.sale_month) 
        FROM sales_data s2 
        WHERE s2.product_id = s.product_id) 
    UNION ALL
    SELECT
        s.product_id,
        s.sale_month,
        rs.total_sales + s.monthly_sales
    FROM sales_data s
    JOIN recursive_sales rs 
        ON s.product_id = rs.product_id
        AND s.sale_month = rs.sale_month + INTERVAL '1 month'
)
SELECT product_id, sale_month, total_sales
FROM recursive_sales
ORDER BY product_id, sale_month;

-- 7.To understand how different payment methods affect monthly sales growth, Amazon wants to compute the total sales for each payment method and 
-- calculate the month-over-month growth rate for the past year (year 2018).
-- Write query to first calculate total monthly sales for each payment method, then compute the percentage change from the previous month.
WITH MonthlySales AS (
    -- Step 1: Calculate total monthly sales for each payment method
    SELECT 
        p.payment_type,
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS sale_month,
        SUM(p.payment_value) AS monthly_total
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.payments p ON o.order_id = p.order_id
    WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018  -- Filter 2018
    GROUP BY p.payment_type, sale_month
),
SalesWithChange AS (
    -- Step 2: Compute month-over-month growth
    SELECT 
        ms.payment_type,
        ms.sale_month,
        ms.monthly_total,
        LAG(ms.monthly_total) OVER (PARTITION BY ms.payment_type ORDER BY ms.sale_month) AS prev_month_sales,
        ROUND(
            ((ms.monthly_total - LAG(ms.monthly_total) OVER (PARTITION BY ms.payment_type ORDER BY ms.sale_month)) 
            / NULLIF(LAG(ms.monthly_total) OVER (PARTITION BY ms.payment_type ORDER BY ms.sale_month), 0)) * 100, 2
        ) AS monthly_change
    FROM MonthlySales ms
)
SELECT payment_type, sale_month, monthly_total, COALESCE(monthly_change, 0) AS monthly_change
FROM SalesWithChange
ORDER BY payment_type, sale_month;