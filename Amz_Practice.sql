/* Author: Vinit R
Created:2020/10/05 
Desciption: Amz_Practice_Questions
Database: GCP Big Query
*/

-- Write a SQL to identify managers (Manager Name, NOT Manager ID) with the biggest team size

SELECT 	A.EMP_NAME AS MANAGER_NAME, COUNT(*)
FROM	`data-analysis-2020.Data_Analysis.Amazon_Employee` A,
         `data-analysis-2020.Data_Analysis.Amazon_Employee` B
WHERE 	A.EMP_ID=B.MANAGER_ID
GROUP BY	MANAGER_NAME
ORDER BY MANAGER_NAME ASC
LIMIT 1

-- Write SQL to identify customers (Customer ID) who placed more than 3 orders in the year 2014 and 2015 each. If a customer placed more than 3 
-- orders in the year 2014 but did not place more than 3 orders in 2015, that customer should not be included in the output

SELECT 	CUSTOMER_ID,
        SUM(ORDER_IN_2014) AS TWO_FOURTEEN,
        SUM(ORDER_IN_2015) AS TWO_FIFTEEN
FROM    (SELECT CUSTOMER_ID,
       	(CASE WHEN ORDER_DATE=2014 THEN COUNT(ORDER_ID) ELSE  NULL END)AS ORDER_IN_2014,
        (CASE WHEN ORDER_DATE=2015 THEN COUNT(ORDER_ID) ELSE  NULL END)AS ORDER_IN_2015
FROM 	(SELECT CUSTOMER_ID,ORDER_ID,
        EXTRACT(YEAR FROM ORDER_DATE) AS ORDER_DATE
FROM 	`data-analysis-2020.Data_Analysis.Amazon_Cust_Orders`) A
GROUP BY 1,ORDER_DATE) A
GROUP BY 1
HAVING  SUM(ORDER_IN_2014) >3 AND SUM(ORDER_IN_2015) >3
ORDER BY 1 DESC

-- Write a SQL to get the list of the customers(CUST ID)who have placed less than 2 orders OR have ordered for less than $100, 
-- so that company can send you a promotion code to them to increase adoption

SELECT 	A.CUST_ID, COUNT(ORDER_ID) AS ORDERS
FROM 	`data-analysis-2020.Data_Analysis.Amazon_Cust_Order_Am` A
RIGHT JOIN 	`data-analysis-2020.Data_Analysis.Amazon_Customers` B
ON 		A.CUST_ID=B.CUST_ID
GROUP BY 1
HAVING COUNT(ORDER_ID)<2 OR SUM(ORDER_AMOUNT) <100

-- Write a SQL to generate a monthly report showing total_account_created, total_number_of_order_placed, and total_order_amount

SELECT 	A.month_begin_date,B.Accounts_Created, C.Total_Orders_Placed, TotalAmount 
FROM 	`data-analysis-2020.Data_Analysis.Amaozon_Calendar` A
LEFT JOIN (SELECT EXTRACT(MONTH FROM b.ACCOUNT_CREATION_DATE) AS MONTH, COUNT(b.cust_id) AS Accounts_Created
FROM  	 `data-analysis-2020.Data_Analysis.Amazon_Customers` b 
GROUP BY 1) B
ON     (EXTRACT(MONTH FROM a.month_begin_date) = b.MONTH)
LEFT JOIN  	( SELECT EXTRACT(MONTH FROM c.order_DATE) as cust_M , COUNT(order_id) AS Total_Orders_Placed, SUM(C.order_amount) as TotalAmount
FROM  	`data-analysis-2020.Data_Analysis.Amazon_Cust_Order_Am` c
GROUP BY 1 ) C
ON ( EXTRACT(MONTH FROM a.month_begin_date)= c.cust_M)
ORDER BY 2 DESC

-- Given a phone log table with Caller_ID, Recipient_ID, and Call_Start_Time, Write a SQL identify callers who made their first call and the last 
-- to the same recipient on a given day

SELECT DISTINCT caller_id, first_recipient, CALL_START_TIME
FROM (SELECT phonelog.*,  first_VALUE(recipient_id) over (partition by caller_id, date(call_start_time) ORDER BY call_start_time) AS first_recipient,
             first_value(recipient_id) over (partition by caller_id, date(call_start_time) ORDER BY  call_start_time DESC) AS last_recipient
      FROM `data-analysis-2020.Data_Analysis.Amazon_Phone_Log` phonelog
     ) phonelog
WHERE first_recipient_id = last_recipient_id
GROUP BY 1,2,3

-- What percentage of active accounts are delinquent for the first time?

SELECT (100*
(SELECT COUNT (Account_id) AS Total
 FROM (SELECT A.account_id 
FROM 	`data-analysis-2020.Data_Analysis.Lavish_Questions` A
JOIN	(SELECT Account_id,MIN(Ds) AS DS
FROM	`data-analysis-2020.Data_Analysis.Lavish_Questions`
group by 1) B 
ON A.Account_id=B.Account_id AND A.DS=B.DS
WHERE 	A.account_id NOT IN (SELECT account_id
FROM	 `data-analysis-2020.Data_Analysis.Lavish_Questions` 
WHERE CASE WHEN Status = 'Closed' THEN 0 ELSE 1 END = 0) AND A.status= 'Delinquent'))/(SELECT COUNT(account_id) AS ACC  FROM (SELECT distinct Account_id
FROM 		`data-analysis-2020.Data_Analysis.Lavish_Questions`)))AS total_delin_first 


-- Write a SQL to get all products that got sold both the days and the number of times the product is sold

SELECT Product_ID,COUNT(*) AS Total
FROM `data-analysis-2020.Data_Analysis.Amazon_Order_Table`
GROUP BY Product_ID
HAVING COUNT(DISTINCT Order_day)=2

-- Get me products that were ordered on July 2 but not on July 1

SELECT Product_ID 
FROM `data-analysis-2020.Data_Analysis.Amazon_Order_Table`
WHERE Order_Day ='2011-07-02' AND Product_ID NOT IN (SELECT Product_ID 
FROM `data-analysis-2020.Data_Analysis.Amazon_Order_Table`
WHERE Order_Day ='2011-07-01')

SELECT DISTINCT A.Product_ID
FROM `data-analysis-2020.Data_Analysis.Amazon_Order_Table` A
LEFT JOIN ( SELECT DISTINCT Product_ID
FROM `data-analysis-2020.Data_Analysis.Amazon_Order_Table` 
WHERE Order_Day = '2011-07-01') B
ON A.Product_ID=B.Product_ID
WHERE B.Product_ID IS NULL AND A.Order_Day = '2011-07-02'
 
-- Get me highest sold products (qty*price) on both days

WITH RESULT AS (
SELECT Order_Day,Product_ID,SUM(Quantity*Price) AS Sold_Amount,
DENSE_RANK () OVER (PARTITION BY Order_Day ORDER BY SUM(Quantity*Price) DESC) DENSERANK
FROM `data-analysis-2020.Data_Analysis.Amazon_Order_Table`
GROUP BY 1,2)
SELECT Order_Day,Product_ID,Sold_Amount
FROM RESULT 
WHERE DENSERANK=1

-- Get me all products day vis, that was ordered more than once

SELECT Order_Day, Product_ID FROM (SELECT Order_Day,Product_ID, COUNT(*) As Total_Orders
FROM `data-analysis-2020.Data_Analysis.Amazon_Order_Table`
GROUP BY 1,2
HAVING COUNT(*)>=2) A

SELECT Order_day,Product_ID
FROM `data-analysis-2020.Data_Analysis.Amazon_Order_Table`
GROUP BY 1,2 
HAVING COUNT(Product_ID) > 1

-- Write a SQL that will give the top product by sales each of the product groups and additionally gather GV, Inventory, and Ad spend measures also for the products

SELECT Product_ID,Product_Group,Sales_Amount,Glance_Views,On_Hand_Quantity
FROM (SELECT A.Product_ID,A.Product_Group,A.Product_Name,B.Sales_Amount,C.Glance_Views,D.On_Hand_Quantity,
RANK () OVER (PARTITION BY A.Product_Group ORDER BY B.Sales_Amount DESC) AS RNK,
IFNULL(C.Glance_Views,0),IFNULL(D.On_Hand_Quantity,0),IFNULL(E.Glance_Views,0)
FROM `data-analysis-2020.Data_Analysis.Product_Dimension_Table` A
JOIN `data-analysis-2020.Data_Analysis.Sales_Fact_Table` B 
ON A.Product_Id = B.Product_Id
LEFT JOIN `data-analysis-2020.Data_Analysis.Glance_View_Fact_Table` C
ON  B.Product_Id = C.Product_Id
LEFT JOIN `data-analysis-2020.Data_Analysis.Inventory_Fact_Table` D
ON C.Product_Id = D.Product_Id
LEFT JOIN `data-analysis-2020.Data_Analysis.Ad_Spend_Fact_Table` E
ON  D.Product_Id = E.Product_Id) Z
WHERE RNK=1

-- Write a SQL to give all products that have glance views but no sales

SELECT PRODUCT_ID 
FROM `data-analysis-2020.Data_Analysis.Glance_View_Fact_Table`
WHERE PRODUCT_ID NOT IN ( SELECT PRODUCT_ID FROM `data-analysis-2020.Data_Analysis.Sales_Fact_Table`)

-- Write a SQL to give the sales of Electronics as a percentage of Books

SELECT E_SALES/B_SALES*100 
FROM (SELECT P.PRODUCT_GROUP,SUM(S.SALES_Amount) AS E_SALES
FROM `data-analysis-2020.Data_Analysis.Product_Dimension_Table` P
INNER JOIN `data-analysis-2020.Data_Analysis.Sales_Fact_Table` S 
ON P.PRODUCT_ID = S.PRODUCT_ID
WHERE P.PRODUCT_GROUP = 'Electronics'
GROUP BY P.PRODUCT_GROUP) E,
(SELECT P.PRODUCT_GROUP,sum(S.SALES_Amount) AS B_SALES
FROM `data-analysis-2020.Data_Analysis.Product_Dimension_Table` P
INNER JOIN  `data-analysis-2020.Data_Analysis.Sales_Fact_Table` S 
ON P.PRODUCT_ID=S.PRODUCT_ID
WHERE P.PRODUCT_GROUP = 'Book'
GROUP BY P.PRODUCT_GROUP) B
WHERE 1=1

-- Consider a phone log table - it records all phone numbers that we dial in a given day 
-- Please provide an SQL query to display the source_phone_number and a flag where a flag needs to be set to Y if first called the number and
-- last called number are the same and N if the first called number and last called number are different

WITH First_Call AS (
SELECT S.source_phone_number , destination_phone_number first_called_number 
FROM `data-analysis-2020.Data_Analysis.Subjective` S
INNER JOIN (
SELECT source_phone_number, MAX(call_start_datetime) last_call_time, MIN(call_start_datetime) first_call_time 
FROM  `data-analysis-2020.Data_Analysis.Subjective` 
GROUP BY source_phone_number) First_Call 
ON S.call_start_datetime = first_call.first_call_time AND  S.source_phone_number = first_call.source_phone_number ) ,
Last_Call 
AS (SELECT S.source_phone_number , destination_phone_number last_called_number 
FROM `data-analysis-2020.Data_Analysis.Subjective` S
INNER JOIN (
SELECT source_phone_number, MAX(call_start_datetime) Last_Call_Time, MIN(call_start_datetime) First_Call_Time 
FROM `data-analysis-2020.Data_Analysis.Subjective` 
GROUP BY source_phone_number) Last_Call 
ON S.call_start_datetime = last_call.last_call_time AND S.source_phone_number = last_call.source_phone_number)
SELECT First_Call.source_phone_number , IF (first_called_number = last_called_number , 'Y' , 'N')
FROM First_Call , Last_call
WHERE first_call.source_phone_number = last_call.source_phone_number
