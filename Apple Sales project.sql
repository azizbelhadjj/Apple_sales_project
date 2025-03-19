--- Apple Sales Project 1M rows Sales Datasets --- 
-- Verification
SELECT * FROM category;
SELECT * FROM products;
SELECT * FROM stores;
SELECT * FROM sales;
SELECT * FROM warranty;

-- Exploratory data analysis
SELECT DISTINCT repair_status FROM warranty;

-- Improving Query Performance 
CREATE INDEX sales_product_id ON sales(product_id);
CREATE INDEX sales_store_id ON sales(store_id);
CREATE INDEX sales_sale_date ON sales(sale_date);
-- et - 64. ms
-- pt -0.15 ms
-- et after index 5-10 ms
EXPLAIN ANALYSE
SELECT * FROM sales 
WHERE product_id = 'P-44';
-- et 101.94 ms 
-- pt 0.06 ms
-- et after index - 20.4 ms
EXPLAIN ANALYSE
SELECT * FROM sales
WHERE store_id = 'ST-10';

-- Business Problems 
-- Medium Problems
-- 1. Number of stores in each country
SELECT
	country,
	COUNT (*) AS num_stores
FROM stores 
GROUP BY 1
ORDER BY num_stores DESC;

-- 2. Calculate the total number of units sold by each store 
SELECT 
	store_name,
	country,
	SUM (quantity) AS total_units 
FROM sales AS s 
INNER JOIN stores AS st 
ON s.store_id = st.store_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- 3. How many sales occured in December 2023 
SELECT 
	COUNT (*) AS total_sales_dec_2023
FROM sales 
WHERE sale_date BETWEEN '2023-12-01' AND '2023-12-31';

-- 4. Determine how many stores that have never had a warranty claim 
SELECT 
	COUNT (store_id) AS total_stores 
FROM stores 
WHERE store_id NOT IN 
(
SELECT 
	DISTINCT store_id
FROM sales AS s 
INNER JOIN warranty AS w 
ON s.sale_id = w.sale_id
);

-- 5. Calculate the percentage of warranty claims marked as 'rejected'
SELECT 
	ROUND (rejected :: NUMERIC / total :: NUMERIC * 100, 2) || '%' AS percentage
FROM (
	SELECT 
	COUNT (*) AS total,
	(SELECT COUNT (*) FROM warranty WHERE repair_status = 'Rejected') AS rejected
	FROM warranty
	)
-- 6. Identify which store that had the highest total units sold last year 
SELECT 
	store_name
FROM (
	SELECT 
		store_name,
		SUM (quantity) AS total_quan
	FROM sales AS s 
	LEFT JOIN stores AS st 
	ON s.store_id = st.store_id 
	WHERE EXTRACT (YEAR FROM sale_date) = 2024 
	GROUP BY 1
	ORDER BY 2 DESC )
LIMIT 1; 

-- 7. Count the number of unique products sold in the last year 
SELECT 
	COUNT (DISTINCT product_id) AS unique_products_sold
FROM sales
WHERE EXTRACT (YEAR FROM sale_date) = 2024;

-- 8. Find the average price of products in each category
SELECT 
	c.category_name, 
	ROUND (AVG (p.price) :: NUMERIC, 2) AS avg_price
FROM category AS c 
LEFT JOIN products AS p 
ON c.category_id = p.category_id
GROUP BY 1
ORDER BY 2 DESC;

-- 9. How many warranty claims were filed in 2020
SELECT	
	COUNT(*) AS num_claims
FROM warranty 
WHERE EXTRACT (YEAR FROM claim_date) = 2020;

-- 10. For each store identify the best selling day based on highest quantity sold
SELECT 
	store_name,
	best_selling_day
FROM (
SELECT 
	st.store_name,
	TO_CHAR (s.sale_date, 'Day') AS best_selling_day,
	DENSE_RANK() OVER (PARTITION BY store_name ORDER BY SUM(quantity) DESC) AS rank_day
FROM sales AS s 
LEFT JOIN stores AS st 
ON s.store_id = st.store_id
GROUP BY 1,2
)
WHERE rank_day = 1 ; 

-- Medium to hard questions 
-- 1. Identify the least sold product in each country in each year based on total units sold 
SELECT
	country,
	year,
	product_name
FROM (
	SELECT 
		p.product_name,
		st.country,
		EXTRACT (YEAR FROM s.sale_date) AS year,
		RANK() OVER (PARTITION BY  st.country, EXTRACT(YEAR FROM s.sale_date) ORDER BY SUM (s.quantity) ASC) AS rank
	FROM sales AS s 
	LEFT JOIN products AS p 
	ON s.product_id = p.product_id
	LEFT JOIN stores AS st
	ON s.store_id = st.store_id
	GROUP BY 1,2,3
)
WHERE rank = 1;

-- 2. Calculate how many warranty claims were filed within 180 days of product sale 
SELECT 
	COUNT (*) AS total_claims 
FROM warranty AS w 
INNER JOIN sales AS s 
ON w.sale_id = s.sale_id AND w.claim_date <= s.sale_date + INTERVAL '180 days';

-- 3. Determine how many warranty claims were filed for products launched in the last two years 
SELECT 
	p.product_name,
	COUNT (w.*) AS total_claims 
FROM warranty AS w 
INNER JOIN sales AS s 
ON w.sale_id = s.sale_id
INNER JOIN products AS p 
ON p.product_id = s.product_id 
WHERE launch_date :: DATE >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 1;

-- 4. List the months in the last 3 years where sales exceeded 5,000 units in the USA 
SELECT 
	Month
FROM (
	SELECT 
	TO_CHAR(s.sale_date, 'MM-YYYY') AS month, 
	SUM (s.quantity)
	FROM sales AS s 
	LEFT JOIN stores AS st
	ON s.store_id = st.store_id
	WHERE (st.country = 'United States') AND (s.sale_date >= CURRENT_DATE - INTERVAL '3 years')
	GROUP BY 1
	HAVING 	SUM (s.quantity) > 5000
)
-- Identify the product category with the most warranty claims filed in the last 2 years
SELECT 
	category_name
FROM (
	SELECT 
	category_name,
	COUNT (claim_id) AS num_claims
	FROM warranty AS w 
	LEFT JOIN sales AS s 
	ON w.sale_id = s.sale_id
	JOIN products AS p 
	ON s.product_id = p.product_id
	JOIN category AS c 
	ON c.category_id = p.category_id
	WHERE claim_date >= CURRENT_DATE - INTERVAL '2 years'
	GROUP BY 1
	ORDER BY num_claims DESC
	LIMIT 1
)

-- Complex Questions 
-- 1.Determine the percentage chance of receiving warranty claims after each purchase for each country 
WITH sub AS (
	SELECT 
		st.country,
		SUM (s.quantity) AS total_units_sold,
		COUNT (w.claim_id) AS total_claims
	FROM sales AS s 
	LEFT JOIN stores AS st 
	ON s.store_id = st.store_id
	LEFT JOIN warranty AS w 
	ON s.sale_id = w.sale_id 
	GROUP BY 1
)
SELECT 
	country,
	total_units_sold,
	total_claims,
	ROUND (total_claims :: NUMERIC / total_units :: NUMERIC * 100, 2) || '%' AS chance_of_claim
FROM sub;

-- 2.Analyse the year-by-year growth ratio for each store
WITH sub AS (
SELECT 
	st.store_name, 
	TO_CHAR (s.sale_date, 'YY') AS year,
	SUM (s.quantity*p.price) AS sales_this_year,
	LEAD (TO_CHAR (s.sale_date, 'YY'),1) OVER (PARTITION BY store_name ORDER BY TO_CHAR (sale_date, 'YY')) AS next_year,
	LEAD (SUM(s.quantity*p.price), 1) OVER (PARTITION BY store_name ORDER BY TO_CHAR (sale_date, 'YY')) AS sales_next_year
FROM sales AS s 
LEFT JOIN stores AS st 
ON s.store_id = st.store_id 
LEFT JOIN products AS p 
ON s.product_id = p.product_id
GROUP BY 1,2
ORDER BY 1, 2) 
SELECT 
	store_name,
	CONCAT (year, '-', next_year) AS Period,
	ROUND ((sales_next_year - sales_this_year) :: NUMERIC / sales_this_year :: NUMERIC * 100, 2) || '%' AS growth_rate
FROM sub 
WHERE sales_next_year IS NOT NULL; 

-- 3. Calculate the correlation between the product price and warranty claims for products sold in the past 5 years, segmented by price range
SELECT 
	CASE WIDTH_BUCKET (p.price, 231, 1965, 4)
		WHEN 1 THEN 'Very Low'
		WHEN 2 THEN 'Low'
		WHEN 3 THEN 'Medium'
		WHEN 4 THEN 'High'
		WHEN 5 THEN 'Very High'
	END AS price_segment,
	COUNT (w.claim_id) AS num_claims
FROM warranty AS w 
LEFT JOIN sales AS s 
ON w.sale_id = s.sale_id 
LEFT JOIN products AS p 
ON p.product_id = s.product_id 
WHERE s.sale_date >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY 1;

-- Identify the store with the highest percentage of "Completed" claims relative to total claims
SELECT 
	store_name,
	percentage_of_claims
FROM
	(SELECT 
		st.store_name,
		COUNT (claim_id) AS completed_claims,
		ROUND (COUNT (claim_id) :: NUMERIC / (SELECT COUNT (w1.claim_id) 
											   FROM warranty AS w1
											   LEFT JOIN sales AS s1
											   ON w1.sale_id = s1.sale_id
											   LEFT JOIN stores AS st1 
											   ON st1.store_id = s1.store_id
											   WHERE st1.store_name = st.store_name) :: NUMERIC * 100, 2) || '%' AS percentage_of_claims
	FROM warranty AS w 
	LEFT JOIN sales AS s
	ON w.sale_id = s.sale_id
	LEFT JOIN stores AS st 
	ON st.store_id = s.store_id
	WHERE w.repair_status = 'Completed'
	GROUP BY st.store_name
	ORDER BY 3 DESC) AS sub
LIMIT 1;

-- Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.
SELECT 
	store_name,
	TO_CHAR (date, 'YYYY-MM') AS date,
	SUM (total_sales) OVER (PARTITION BY store_name ORDER BY date)
FROM
	(SELECT 
		store_name,
		DATE_TRUNC ('month', sale_date) :: DATE AS date,
		SUM (quantity * price) AS total_sales
	FROM sales AS s 
	LEFT JOIN stores AS st 
	ON s.store_id = st.store_id
	LEFT JOIN products AS p 
	ON p.product_id = s.product_id
	WHERE sale_date >= CURRENT_DATE - INTERVAL '5 years'
	GROUP BY 1,2);

-- Analyze product sales trends over time, segmented over key periods, from launch to 6 months, 6-12 months, 12-18 months and beyond 18months
SELECT 
    product_name,
    CASE 
        WHEN sale_date < launch_date + INTERVAL '6 months' THEN 'Launch to 6 months'
        WHEN sale_date >= launch_date + INTERVAL '6 months' AND sale_date < launch_date + INTERVAL '12 months' THEN '6-12 Months'
        WHEN sale_date >= launch_date + INTERVAL '12 months' AND sale_date < launch_date + INTERVAL '18 months' THEN '12-18 Months'
        WHEN sale_date >= launch_date + INTERVAL '18 months' THEN '18 Months +' 
    END AS sale_launch_category,
    SUM(price * quantity) AS revenue_per_product,

    CASE 
        WHEN sale_date < launch_date + INTERVAL '6 months' THEN 1
        WHEN sale_date >= launch_date + INTERVAL '6 months' AND sale_date < launch_date + INTERVAL '12 months' THEN 2
        WHEN sale_date >= launch_date + INTERVAL '12 months' AND sale_date < launch_date + INTERVAL '18 months' THEN 3
        WHEN sale_date >= launch_date + INTERVAL '18 months' THEN 4
    END AS order_value
FROM sales AS s 
LEFT JOIN products AS p 
ON s.product_id = p.product_id 
GROUP BY 1, 2, 4 
ORDER BY 1, 4;



