CREATE DATABASE E_Commerce_Data;

USE E_Commerce_Data;


UPDATE [dbo].[prod_dimen] SET  Prod_id = 'Prod_16' WHERE Prod_id = ' RULERS AND TRIMMERS,Prod_16'

--change column data type from varchar to date

UPDATE [dbo].[orders_dimen] SET Order_Date = CONVERT(DATE, Order_Date, 105);

ALTER TABLE [dbo].[orders_dimen]
ALTER COLUMN Order_Date DATE NOT NULL;


UPDATE [dbo].[shipping_dimen] SET Ship_Date = CONVERT(DATE, Ship_Date, 105);

ALTER TABLE [dbo].[shipping_dimen]
ALTER COLUMN ship_Date DATE NOT NULL;


UPDATE [dbo].[Combined_Table] SET Sales = CONVERT(float, Sales), Discount = CONVERT(float, Discount), Profit = CONVERT(float, Profit), 
Shipping_Cost = CONVERT(float, Shipping_Cost),  Order_Quantity = CONVERT(int, Order_Quantity);


ALTER TABLE [dbo].[Combined_Table]
ALTER COLUMN Sales float NOT NULL;

ALTER TABLE [dbo].[Combined_Table]
ALTER COLUMN Discount float NOT NULL;

ALTER TABLE [dbo].[Combined_Table]
ALTER COLUMN Profit float NOT NULL;

ALTER TABLE [dbo].[Combined_Table]
ALTER COLUMN Shipping_Cost float NOT NULL;

ALTER TABLE [dbo].[Combined_Table]
ALTER COLUMN Order_Quantity int NOT NULL;



--1. Join all the tables and create a new table with all of the columns, called combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen,shipping_dimen)


SELECT old_table.* INTO Combined_Table
FROM (SELECT od.Ord_id, od.Order_Date, od.Order_Priority, cd.Cust_id, cd.Customer_Name, cd.Province, cd.Region, cd.Customer_Segment, sd.Ship_id, sd.Ship_Date,
sd.Ship_Mode, pd.Prod_id, pd.Product_Category, pd.Product_Sub_Category, mf.Sales, mf.Discount, mf.Order_Quantity, mf.Profit, mf.Shipping_Cost, mf.Product_Base_Margin
FROM [dbo].[market_fact] mf JOIN [dbo].[orders_dimen] od
ON mf.Ord_id = od.Ord_id JOIN [dbo].[cust_dimen] cd
ON mf.Cust_id = cd.Cust_id JOIN [dbo].[shipping_dimen] sd
ON mf.Ship_id = sd.Ship_id JOIN [dbo].[prod_dimen] pd
ON mf.Prod_id = pd.Prod_id) AS old_table;


--2. Find the top 3 customers who have the maximum count of orders.

SELECT TOP 3 Cust_id, Customer_Name, Count(Distinct Ord_id) number_of_Orders
FROM [dbo].[Combined_Table]
GROUP BY Cust_id, Customer_Name
ORDER BY number_of_Orders DESC;

--3.Create a new column at combined_table as DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.

ALTER TABLE Combined_Table
ADD DaysTakenForDelivery INT;

UPDATE Combined_Table SET DaysTakenForDelivery = DATEDIFF(day, Order_Date, Ship_Date);


--4. Find the customer whose order took the maximum time to get delivered.

SELECT MAX(DaysTakenForDelivery)
FROM [dbo].[Combined_Table]

SELECT TOP 1 Cust_id, Customer_Name, order_date, Ship_Date, DaysTakenForDelivery
FROM [dbo].[Combined_Table]
WHERE DaysTakenForDelivery =  (SELECT MAX(DaysTakenForDelivery)
								FROM [dbo].[Combined_Table])
ORDER BY DaysTakenForDelivery DESC;

--5.Retrieve total sales made by each product from the data (use Window function)


SELECT DISTINCT Prod_id,  SUM(Sales) OVER(PARTITION BY Prod_id ) Retrive_total_sales
FROM [dbo].[Combined_Table];


--6. Retrieve total profit made from each product from the data (use windows function)

SELECT Distinct Prod_id,  SUM(Sales) OVER(PARTITION BY Prod_id ) Retrive_total_profit
FROM [dbo].[Combined_Table];

--7. Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011


select * from [dbo].[Combined_Table] ORDER BY Order_Date


SELECT count(distinct Cust_id) Total_customer_January
FROM [dbo].[Combined_Table]
WHERE month(Order_Date) = 1 and year(Order_Date) = 2011;


SELECT month(Order_Date) [Month], count(Distinct Cust_id) monthBymonth
FROM [dbo].[Combined_Table]
WHERE Cust_id IN (SELECT distinct Cust_id Total_customer_January
				FROM [dbo].[Combined_Table]
				WHERE month(Order_Date) = 1 and year(Order_Date) = 2011) and  year(Order_Date)=2011 
GROUP BY month(Order_Date);

--1. Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred over multiple years since whenever
--business started operations.



CREATE VIEW Count_Visit_in_Month AS
SELECT Cust_id, CONVERT(date, SUBSTRING(convert(varchar, Order_Date), 1, 7) + '-' + '1') [date], count(distinct Ord_id) count_of_visit
FROM [dbo].[Combined_Table]
GROUP BY Cust_id, CONVERT(date, SUBSTRING(convert(varchar, Order_Date), 1, 7) + '-' + '1');


--2. Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.

CREATE VIEW Lapse_Time_Visit AS
SELECT Cust_id, Count_of_visit, [date], lead([date]) OVER (PARTITION BY Cust_id ORDER BY [date]) next_visit_date
FROM Count_Visit_in_Month;


--3. Calculate the time gaps between visits.


CREATE VIEW Time_Gap_Visit AS
SELECT * , DATEDIFF(month, [date], next_visit_date) time_gap
FROM Lapse_Time_Visit;


-- 4. Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.

CREATE VIEW Customer_Type AS
SELECT DISTINCT cust_id, avg_time_gap,
CASE
		WHEN avg_time_gap <= 1 THEN 'retained'
		WHEN avg_time_gap > 1 THEN 'irregular'
		WHEN avg_time_gap is null THEN 'churn'
		ELSE 'unknown data'
		END Customer_Type
FROM (SELECT Cust_id, avg(time_gap) avg_time_gap FROM Time_Gap_Visit GROUP BY Cust_id) b;


--5. Calculate the retention month wise.


create view retention_vw as 

select distinct next_visit_date as Retention_month, --Cust_id, 

sum(time_gap) over (partition by next_visit_date) as Retention_Sum_monthly

from Time_Gap_Visit
where time_gap<=1
order by Retention_Sum_monthly desc;

select *
from Time_Gap_Visit
where Cust_id = 'Cust_1184'