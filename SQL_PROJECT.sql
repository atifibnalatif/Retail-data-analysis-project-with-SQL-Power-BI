-- SQL Retail Sales Analysis 
CREATE DATABASE sql_project_p2;

--================================================================================
-- Create TABLE
--================================================================================
CREATE TABLE Sales_data 
	(
		Sale_ID	Varchar(10),
		Sale_Date Date,
		Customer_ID	Varchar(10),
		Product_ID	Varchar(10),
		Product_Category	Varchar(20),
		Store_ID Varchar(10),
		Region	Varchar(10),
		Quantity_Sold	Int,
		Unit_Price	Float,
		Payment_Method	Varchar(20),
		Returned	Varchar(5),
		Total_Sale_Amount Float
	)
--================================================================================
--Importing data
--================================================================================
COPY Sales_data
FROM 'F:\DS360\SQL files\Sales_Data.csv'
DELIMITER ','
CSV HEADER;
-------------------------------------
SELECT 
*
FROM public.sales_data;
--================================================================================
-- Data Exploration
--================================================================================

-- How many sales do we have?
SELECT COUNT(*) as total_sale FROM public.sales_data;

-- How many uniuque customers do we have ?
SELECT COUNT(DISTINCT customer_id) as unique_customers FROM public.sales_data;

--Which categories do we have?
SELECT DISTINCT product_category as unique_categories FROM public.sales_data;

--============================================================================================
-- Data Analysis 
--============================================================================================
--1. Which region has the highest total revenue?
CREATE VIEW vw_regiol_sale AS
	(
	SELECT
		region,
		ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue,
		ROUND(AVG(total_sale_amount)::numeric,2) AS avg_revenue
	FROM public.sales_data 
	WHERE returned = 'No'
	GROUP BY 1
	ORDER BY 2 DESC
	)

--2. Which product category generates the highest revenue on average per sale?
SELECT
	product_category,
	ROUND(AVG(total_sale_amount)::numeric,2) AS avg_revenue_per_category
FROM public.sales_data
GROUP BY 1
ORDER BY 2 DESC;

--3. What is the return rate per product category?
CREATE VIEW vw_return AS
	(
	WITH return_case AS
		(
			SELECT
				product_category,
				COUNT(Case WHEN returned='Yes' THEN 1 END) As returned_order,
				COUNT(product_category) AS total_order
			FROM public.sales_data
			GROUP BY 1
		)
	SELECT 
		product_category,
		ROUND((returned_order::numeric/total_order::numeric)*100,2) AS return_rate
	FROM return_case
	ORDER BY return_rate DESC
	);

--4. Identify the top 5 products with the highest total sales by quantity.
SELECT 
	product_id,
	SUM(quantity_sold) AS total_quantity_sale,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
GROUP BY product_id
ORDER BY total_quantity_sale DESC
LIMIT 5;

--5. Which store has the lowest revenue but highest number of sales?
SELECT
	store_id,
	COUNT(*) AS number_of_sale,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
GROUP BY store_id
ORDER BY total_revenue ASC, number_of_sale DESC;

--6. How do different payment methods impact total revenue?
CREATE VIEW vw_payment AS
	(
	WITH pay_method AS
		(
		SELECT 
			payment_method,
			COUNT(*) AS total_order,
			COUNT(CASE WHEN returned='Yes'THEN 1 END) as returned_order,
			COUNT(CASE WHEN returned='No'THEN 1 END) as confirmed_number,
			ROUND(SUM(CASE WHEN returned='No'THEN total_sale_amount END)::numeric,2) AS revenue_per_method
		FROM public.sales_data
		GROUP BY 1
	 	)
	SELECT
		*,
		ROUND((returned_order::numeric/total_order::numeric)*100,2) AS return_rate
	FROM pay_method
	ORDER BY return_rate ASC
	);

--7. Which customers have made the most purchases in terms of total amount spent?
WITH customer AS
	(
		SELECT
			customer_id,
			COUNT(*) AS total_order,
			COUNT(CASE WHEN returned='Yes'THEN 1 END) as returned_order,
			COUNT(CASE WHEN returned='No'THEN 1 END) as confirmed_number,
			ROUND(SUM(CASE WHEN returned='No'THEN total_sale_amount END)::numeric,2) AS total_purchase
		FROM public.sales_data
		GROUP BY 1
	)
SELECT
	*
FROM customer
WHERE total_purchase IS NOT NULL
ORDER BY total_purchase DESC;

--8. Which quarter sees the highest sales?
WITH quarter_analysis AS
	(
		SELECT
			*,
			EXTRACT(QUARTER FROM sale_date) AS quarter
		FROM public.sales_data
	)
SELECT
	quarter,
	COUNT(sale_id) AS sale_number,
	ROUND(SUM(CASE WHEN returned='No'THEN total_sale_amount END)::numeric,2) AS total_revenue
FROM quarter_analysis
GROUP BY 1
ORDER BY total_revenue DESC;

--9. What is the average unit price per product category?
SELECT
	product_category,
	ROUND(AVG(unit_price)::numeric,2) AS average_unit_price
FROM public.sales_data
GROUP BY product_category;

--10. Which product categories have the highest return percentage?
WITH categories AS
	(
	SELECT 
		product_category,
		COUNT(*) AS total_order,
		COUNT(CASE WHEN returned='Yes'THEN 1 END) as returned_order,
		COUNT(CASE WHEN returned='No'THEN 1 END) as confirmed_number,
		ROUND(SUM(CASE WHEN returned='No'THEN total_sale_amount END)::numeric,2) AS revenue_per_category
	FROM public.sales_data
	GROUP BY 1
 	)
SELECT
	*,
	ROUND((returned_order::numeric/total_order::numeric)*100,2) AS return_rate
FROM categories
ORDER BY return_rate DESC;

--11.Monthly Sales Trend Analysis-How do sales change month by month throughout the year?
CREATE VIEW vw_growth AS
	(
	WITH month_trend AS 
	(
		SELECT
				EXTRACT(MONTH FROM sale_date) AS month,
				COUNT(sale_id) AS number_of_order,
				SUM(quantity_sold) AS total_quantity,
				ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
			FROM public.sales_data
			WHERE returned='No'
			GROUP BY 1
		),
	month_trend_2 AS
		(
		SELECT
			*,
			total_revenue - LAG(total_revenue) OVER (ORDER BY month) AS revenue_increase
		FROM month_trend
		)
	SELECT 
		*,
		ROUND(((revenue_increase/LAG(total_revenue) OVER (ORDER BY month))*100)::numeric,2) AS growth_rate
	FROM month_trend_2
	);
--12.How much revenue is lost because of returned products?
	--12.1 Per Product.
	CREATE VIEW vw_loss_product AS
		(
		SELECT
			product_id,
			COUNT(sale_id) AS number_of_returns,
			ROUND(SUM(total_sale_amount)::numeric,2) AS lost_revenue
		FROM public.sales_data
		WHERE returned='Yes'
		GROUP BY product_id
		Order by lost_revenue DESC
		);
	--12.2 Per Region.
CREATE VIEW vw_loss_region AS
	(
	SELECT
		region,
		COUNT(sale_id) AS number_of_returns,
		ROUND(SUM(total_sale_amount)::numeric,2) AS lost_revenue
	FROM public.sales_data
	WHERE returned='Yes'
	GROUP BY region
	Order by lost_revenue DESC
	);
	--12.3 Per Product category.
CREATE VIEW vw_loss_product_cat AS
	(
	SELECT
		product_category,
		COUNT(sale_id) AS number_of_returns,
		ROUND(SUM(total_sale_amount)::numeric,2) AS lost_revenue
	FROM public.sales_data
	WHERE returned='Yes'
	GROUP BY product_category
	Order by lost_revenue DESC
	);
	
--13.How many items are sold per transaction on average?
SELECT
	region,
	ROUND(AVG(quantity_sold)::numeric,2) AS avg_bucket_size
FROM public.sales_data
WHERE returned='No'
GROUP BY region;

--14.What percentage of total revenue comes from each category?
WITH cat_share AS
	(
	SELECT
		product_category,
		ROUND(SUM(total_sale_amount)::numeric,2) as total_revenue_per_category,
		ROUND(SUM(SUM(total_sale_amount))OVER()::numeric,2) AS total_revenue
	FROM public.sales_data
	WHERE returned='No'
	GROUP BY 1
	)
SELECT
	*,
	ROUND(((total_revenue_per_category/total_revenue)*100)::numeric,2) AS percentile_share
FROM cat_share;

--15.Are sales higher on weekdays or weekends?
SELECT
	TO_CHAR(sale_date,'DAY') AS week_day,
	COUNT(sale_id) number_of_sales,
	SUM(quantity_sold) AS qantity_sold,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
GROUP BY week_day
ORDER BY total_revenue DESC;

--16.Which store generates the highest revenue per sale?
SELECT
	store_id,
	ROUND(AVG(total_sale_amount)::numeric,2) AS revenue_per_sale
FROM public.sales_data
WHERE returned='No'
GROUP BY store_id
ORDER BY revenue_per_sale DESC;

--17.Which payment method is preferred in each region?
SELECT
	region,
	payment_method,
	COUNT(sale_id) AS number_of_sales,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
GROUP BY region,payment_method
ORDER BY region,number_of_sales DESC;

--18.Which payment method contributes the most revenue?
SELECT
	payment_method,
	COUNT(sale_id) AS number_of_sale,
	SUM(quantity_sold) AS total_quantity,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
Group by payment_method
ORDER BY total_revenue DESC;

--19.Which categories perform best during different quarters?
SELECT
	EXTRACT(QUARTER FROM sale_date) AS quarter,
	product_category,
	COUNT(sale_id) AS number_of_sale,
	SUM(quantity_sold) AS total_quantity,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
GROUP BY 1,2
ORDER BY  1 ASC,total_revenue DESC;

--20. Pareto Analysis (80/20 Rule)-Do 20% of products generate 80% of revenue?
CREATE VIEW VW_pareto AS
	(
	WITH product AS
		(
		SELECT
			product_id,
			ROUND(SUM(total_sale_amount)::numeric,2) AS revenue_per_product
		FROM public.sales_data
		WHERE returned='No'
		GROUP BY product_id
		),
	pareto AS
		(
		SELECT
			ROW_NUMBER() OVER (ORDER BY revenue_per_product DESC) AS rn,
			*,
			SUM(revenue_per_product)OVER(ORDER BY revenue_per_product DESC) AS cumulative_revenue,
			ROUND((SUM(revenue_per_product)OVER())::numeric,2) AS total_revenue
		FROM product
		)
	SELECT
		*,
		ROUND(((rn::numeric/COUNT(*)OVER()::numeric)*100),2) as top_product_pct,
		ROUND((cumulative_revenue/total_revenue)*100,2) AS cumulative_rev_pct,
		80 AS pareto_line
	FROM pareto
	);
--21.Are high spending customers also high returners?
CREATE VIEW vw_customer_spend AS
	(
	With customer AS
		(
		SELECT 
			customer_id,
			COALESCE(ROUND(SUM(CASE WHEN returned='No' THEN total_sale_amount END)::numeric,2),0) AS total_spending,
			COUNT(sale_id) AS total_order,
			COUNT(CASE WHEN returned='Yes' THEN sale_id END) AS returned_order
		FROM public.sales_data
		GROUP BY customer_id
		),
	returned AS
		(
		SELECT 
			*,
			ROUND((returned_order::numeric/total_order::numeric)*100,2) AS return_rate
		FROM customer
		ORDER BY return_rate DESC
		)
	SELECT
		*,
		CASE WHEN total_spending>=1000 AND return_rate>=50 THEN 'High Spender High Returner'
			 WHEN total_spending>=1000 AND return_rate<50 THEN 'High Spender Low Returner'
			 WHEN total_spending<1000 AND return_rate>=50 THEN 'Low Spender High Returner'
			 ELSE 'Low Spender Low Returner'
		END AS customer_type
	FROM returned
	)
--22.Which payment method does each customer prefer?
SELECT 
	customer_id,
	payment_method,
	COUNT(*) AS number_of_payment
FROM public.sales_data
WHERE returned='No'
GROUP BY customer_id,payment_method
ORDER BY customer_id ASC;
--23. Which store has the highest return rate?
CREATE VIEW store AS
	(
	SELECT
		store_id,
		COUNT(*) AS total_orders,
		COUNT(CASE WHEN returned='Yes' THEN 1 END) AS returned_order,
		ROUND((COUNT(CASE WHEN returned='Yes' THEN 1 END)::numeric/COUNT(*)::numeric)*100,2) AS return_rate
	FROM public.sales_data
	GROUP BY store_id
	ORDER BY store_id
	);
--24.Which stores show consistent revenue growth month over month?
SELECT
	store_id,
	TO_CHAR(sale_date,'MONTH') AS month,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
GROUP BY store_id ,month 
ORDER BY store_id ASC,month;
--25.What is the growth rate of revenue per month fore each payment method?
WITH growth_method AS
	(
	SELECT 
		payment_method,
		EXTRACT(MONTH FROM sale_date) AS month_number,
		TO_CHAR(sale_date,'MONTH') AS month,
		ROUND(SUM(total_sale_amount)::numeric,2) AS total_sale
	FROM public.sales_data
	GROUP BY 1,2,3
	ORDER BY 1 ASC,2 ASC
	)
SELECT
	*,
	ROUND((((total_sale-LAG(total_sale)OVER(PARTITION BY payment_method ORDER BY month_number ASC))/LAG(total_sale)OVER(PARTITION BY payment_method ORDER BY month_number ASC))*100),2) AS growth_rate
FROM growth_method
