# 🛒 Retail Sales Analysis — SQL Project

A comprehensive SQL-based data analysis project exploring retail transaction data. Covers everything from database setup to advanced analytical queries using CTEs, window functions, and aggregations.

---

## 📁 Project Structure

```
retail-sales-sql/
│
├── SQL_PROJECT.sql	            # Main SQL script (schema, cleaning, analysis)
├── Sales_Data_main.csv  		# Raw dataset (500 transactions)
└── README.md                   # Project documentation
```

---

## 📂 Dataset

**File:** `Sales_Data_main.csv`

| Property         		| Details                              					|
|-----------------------|-------------------------------------------------------|
| **Records**      		| 500 transactions                   					|
| **Columns**      		| 12                                 		  			|
| **Date Range**   		| 01 Jan 2024 — 31 Dec 2024            					|
| **Categories**   		| Clothing, Grocery, Electronics, Home, Toys.     		|	
| **Payment Method**	| Payment_Method, Net Banking, UPI, Cash, Credit Card.	|
| **Region**			| North, East, South, West.
| **Encoding**     		| UTF-8                                					|	

---

## 🗄️ Database Schema

**Table:** `retail_sales`

| Column           		| Type         		| Description                        |
|-----------------------|-------------------|------------------------------------|
| `Sale_ID` 	   		| Varchar(10)(PK)   | Unique transaction identifier      |
| `sale_date`      		| DATE         		| Date of the sale                   |
| `Customer_ID`    		| Varchar(10)       | Unique customer identifier         |
| `Product_ID`     		| Varchar(10)       | Unique product identifier          |
| `Product_Category`	| VARCHAR(20)  		| Product category                   |
| `Store_ID`            | Varchar(10)       | Unique store identifier            |
| `Region`       		| VARCHAR(10)  		|  region of country              	 |
| `Quantity_Sold`       | INT          		| Units sold                         |
| `Unit_Price` 			| FLOAT        		| Price per unit                     |
| `Payment_Method`      | Varchar(20)       | Method of payment                  |
| `Returned`     		| Varchar(5)        | Product return information         |
| `Total_Sale_Amount`  	| Float				| Total revenue per transection 	 |

---

## **🧹 Data Cleaning**
### **STEPS**
- Open CSV file and select all.
- In **DATA** tab select **"From Table/Range"** and open pewer query(un select "my table has headers").
- IN **"Add column"** tab right click **"Index column"** then **"From 0"**.
- Click **"Custom column"** name = "Bundle" and paste below formulae to give each 12 rows similar number.
	```powerquery
	= Number.IntegerDivide([Index], 12)
	```
- Then again from **"Custom column"** name = "Position" and paste below formulae to give position to every row of a bundle.
	```pwerquery
	"= Number.Mod([Index], 12)
	```
- Then from **Home** tab click **"Group by"** and select "Bundle" , name = "BundleData" and operation = "All rows", it creates each bundle in a list.
- Then from **"Add column"** click **"Custom column"** and name = "FieldNames" and run the formulae to extract headers from BundleData 
	```powerquery
	= [BundleData][Column1]
	```
- Then again for first sale of every bundle add a column using **"Custom column"**,
	```powerquery
	= [BundleData][Column2]
	```
	And repeat it for column 3-6 for separating each sale data from bundle
- Then add column named **"record.Sale1"** to combine headers eith sale data using formulae
	```powerquery
	= Record.FromList([Sale1], [FieldNames])
	```
	And repeat it fo sale 2-5 to do the same,
- Then duplicate the query four times and remove every colunmn from first query except **"record.Sale1"** and repeat it in remaining 4 queries for record.Sale2-5.
- Expand all the queries and while expaning click unclick "use query name as prefix"
- From **Fie** tab click click "Close & load" and there will be 5 worksheets of 100 rows and 12 columns.
- Now create a worksheet in named "Master" and in A1 cell paste the function,
	```Excel
	=VSTACK(
    Table1,
    Table1(2),
    Table1(3),
    Table1(4),
    Table1(5))
	```
- Then save it in **xlxs** format to save all the queries and save te master sheet in **CSV UTF-8** format to load in Pgadmin .
---
## 🔍 Data Exploration

Quick overview queries to understand the dataset:

- **Total number of sales**
```sql
SELECT COUNT(*) as total_sale FROM public.sales_data;
```
- **Count of unique customers**
```sql
SELECT COUNT(DISTINCT customer_id) as unique_customers FROM public.sales_data;
```
- **List of distinct product categories** (Clothing, Beauty, Electronics)
```sql
SELECT DISTINCT product_category as unique_categories FROM public.sales_data;
```

---
#
## 📊 Analysis Queries

### 💰 Revenue & Profitability Analysis
#### Evaluating revenue generation patterns across regions, product categories, stores, and payment methods to identify key profit drivers.
- Highest revenue region.
```sql
SELECT
	region,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue,
	ROUND(AVG(total_sale_amount)::numeric,2) AS avg_rev
FROM public.sales_data 
WHERE returned = 'No'
GROUP BY 1
ORDER BY 2 DESC;
```
- Highest average revenue category.
```sql
SELECT
	product_category,
	ROUND(AVG(total_sale_amount)::numeric,2) AS avg_revenue_per_category
FROM public.sales_data
GROUP BY 1
ORDER BY 2 DESC;
```
- Revenue contribution by category.
```sql
WITH cat_share AS
	(
	SELECT
		product_category,
		ROUND(SUM(total_sale_amount)::numeric,2) as total_renue_per_category,
		ROUND(SUM(SUM(total_sale_amount))OVER()::numeric,2) AS total_revenue
	FROM public.sales_data
	WHERE returned='No'
	GROUP BY 1
	)
SELECT
	*,
	ROUND(((total_renue_per_category/total_revenue)*100)::numeric,2) AS percentile_share
FROM cat_share;
```
- Revenue per sale by store,
```sql
SELECT
	store_id,
	ROUND(AVG(total_sale_amount)::numeric,2) AS revenue_per_sale
FROM public.sales_data
WHERE returned='No'
GROUP BY store_id
ORDER BY revenue_per_sale DESC;
```
### 📦 Product Performance Analysis
#### Assessing product and category performance to identify best-selling items, pricing trends, and revenue concentration.
- Top 5 products by quantity sold.
```sql
SELECT 
	product_id,
	SUM(quantity_sold) AS total_quantity_sale,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
GROUP BY product_id
ORDER BY total_quantity_sale DESC
LIMIT 5;
```
- Average unit price by category.
```sql
SELECT
	product_category,
	ROUND(AVG(unit_price)::numeric,2) AS average_unit_price
FROM public.sales_data
GROUP BY product_category;
```
- Category performance by quarter.
```sql
SELECT
	EXTRACT(QUARTER FROM sale_date) AS quarter,
	product_category,
	COUNT(sale_id) AS number_of_sale,
	SUM(quantity_sold) AS total_quantity,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
GROUP BY 1,2
ORDER BY  1 ASC,total_revenue DESC;
```
- Pareto Analysis (80/20 Rule).
```sql
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
	ROUND((cumulative_revenue/total_revenue)*100,2) AS cumulative_rev_pct
FROM pareto;
```
### 🔄 Returns & Revenue Loss Analysis
#### Investigating return behavior and its impact on business performance, customer satisfaction, and revenue retention.
- Categories with highest return percentage.
```sql
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
```
- Revenue lost due to returns.
	- Per Product.
	```sql
	SELECT
		product_id,
		COUNT(sale_id) AS number_of_returns,
		ROUND(SUM(total_sale_amount)::numeric,2) AS lost_revenue
	FROM public.sales_data
	WHERE returned='Yes'
	GROUP BY product_id
	Order by lost_revenue DESC;
	```
	- Per Region.
	```sql
		region,
		COUNT(sale_id) AS number_of_returns,
		ROUND(SUM(total_sale_amount)::numeric,2) AS lost_revenue
	FROM public.sales_data
	WHERE returned='Yes'
	GROUP BY region
	Order by lost_revenue DESC;
	```
	- Per Product category.
	```sql
	SELECT
		product_category,
		COUNT(sale_id) AS number_of_returns,
		ROUND(SUM(total_sale_amount)::numeric,2) AS lost_revenue
	FROM public.sales_data
	WHERE returned='Yes'
	GROUP BY product_category
	Order by lost_revenue DESC;
	```
### 👥 Customer Behavior Analysis.
#### Understanding customer purchasing patterns, spending habits, and transaction characteristics to identify high-value customers.
- Highest-spending customers.
```sql
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
		ORDER BY total_purchase DESC
	)
SELECT
	*
FROM customer
WHERE total_purchase IS NOT NULL;
```
- Average basket size per region.
```sql
SELECT
	region,
	ROUND(AVG(quantity_sold)::numeric,2) AS avg_bucket_size
FROM public.sales_data
WHERE returned='No'
GROUP BY region;
```
- Customer return rate
```sql
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
	);
```
- Patment method preference by customers
```sql
SELECT 
	customer_id,
	payment_method,
	COUNT(*) AS number_of_payment
FROM public.sales_data
WHERE returned='No'
GROUP BY customer_id,payment_method
ORDER BY customer_id ASC;
```
### 🏪 Store Performance Analysis.
#### Measuring operational efficiency and sales effectiveness across store locations.
- Lowest revenue but highest sales volume store.
```sql
SELECT
	store_id,
	COUNT(*) AS number_of_sale,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
GROUP BY store_id
ORDER BY total_revenue ASC, number_of_sale DESC;
```
- Highest revenue per sale store.
```sql
SELECT
	store_id,
	ROUND(AVG(total_sale_amount)::numeric,2) AS revenue_per_sale
FROM public.sales_data
WHERE returned='No'
GROUP BY store_id
ORDER BY revenue_per_sale DESC;
```
- Return rate of stores.
```sql
SELECT
	store_id,
	COUNT(*) AS total_orders,
	COUNT(CASE WHEN returned='Yes' THEN 1 END) AS returned_order,
	ROUND((COUNT(CASE WHEN returned='Yes' THEN 1 END)::numeric/COUNT(*)::numeric)*100,2) AS return_rate
FROM public.sales_data
GROUP BY store_id
ORDER BY store_id;
```
- Revenue growth per month of stores.
```sql
SELECT
	store_id,
	TO_CHAR(sale_date,'MONTH') AS month,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
GROUP BY store_id ,month 
ORDER BY store_id ASC,month;
```
### 📈 Sales Trend & Seasonal Analysis.
#### Analyzing sales performance over time to identify growth patterns, seasonality, and peak demand periods.
- Highest-performing quarter.
```sql
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
```
- Monthly sales trend analysis.
```sql
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
FROM month_trend_2;
```
- Weekday vs weekend sales.
```sql
SELECT
	TO_CHAR(sale_date,'DAY') AS week_day,
	COUNT(sale_id) number_of_sales,
	SUM(quantity_sold) AS qantity_sold,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
GROUP BY week_day
ORDER BY total_revenue DESC;
```
### 💳 Payment Method Analysis.
#### Examining customer payment preferences and their influence on revenue generation across regions.
- Revenue impact by payment method.
```sql
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
ORDER BY return_rate ASC;
```
- Preferred payment method by region.
```sql
SELECT
	region,
	payment_method,
	COUNT(sale_id) AS number_of_sales,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
GROUP BY region,payment_method
ORDER BY region,number_of_sales DESC;
```
- Revenue contribution by payment method.
```sql
SELECT
	payment_method,
	COUNT(sale_id) AS number_of_sale,
	SUM(quantity_sold) AS total_quantity,
	ROUND(SUM(total_sale_amount)::numeric,2) AS total_revenue
FROM public.sales_data
WHERE returned='No'
Group by payment_method
ORDER BY total_revenue DESC;
```
### 📊 Executive Summary.
#### A high-level overview of key business metrics, sales performance, customer behavior, and operational insights.

---

## 🛠️ Tools & Concepts Used

- **Excel**(Data cleaning)
- **PostgreSQL** (compatible syntax)
- Common Table Expressions (CTEs)
- Window Functions (`RANK`, `LAG`, `SUM OVER`, `AVG OVER`)
- Aggregate Functions (`SUM`, `COUNT`, `AVG`)
- Date & Time Functions (`EXTRACT`, `TO_CHAR`)
- Conditional Logic (`CASE WHEN`)
- `NULLIF` for safe division
- **POWER BI**(Data visualiz)

---

## 🚀 Getting Started

1. **Create the database**
   ```sql
   CREATE DATABASE sql_project;
   ```

2. **Run the script** — Execute `SQL_PROJECT.sql` in your PostgreSQL client (e.g., pgAdmin or psql).

3. **Import your data** — Load `Sales_Data.csv` into the `sales_data` table using pgAdmin's import tool or the psql `\COPY` command:
   ```sql
   \COPY Sales_data FROM 'Sales_Data.csv' DELIMITER ',' CSV HEADER;
   ```

4. **Explore the analysis queries** — Each query is clearly commented with its purpose.

---

## 👤 Author

**Md Atif Ibna Latif**
<br>
SQL Data Analyst |Business Analysis |Retail Domain
- **LinkedIn**: [Connect with me professionally](www.linkedin.com/in/md-atif-ibna-latif)
---
- **Watch the full walkthrough on Youtube:[link](https://youtu.be/oYYFdg1HSU0?si=7sz8DTrHVFm8hay3)

## 📄 License

This project is for educational and portfolio purposes.
