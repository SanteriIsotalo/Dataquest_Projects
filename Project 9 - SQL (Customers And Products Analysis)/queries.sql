/* There are 8 tables in this project.
1. customers contains information about customers (names, addresses, city etc.)
2. employees contains information about employees (names, who they report to etc.)
3. offices contains information about offices (locations, zip codes etc.)
4. orderdetails contains information about orders (date, number, price etc.)
5. orders contains more information, like current status of order, customer, comments etc.
6. payments contains information about customers, payment dates, amounts
7. productlines contains descriptions about products and category for productLine
8. products contains information about products (price, quantity in stock, name, line etc.)
*/

-- Table descriptions
SELECT 'Customers' AS table_name, 
       13 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Customers
  
UNION ALL

SELECT 'Products' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Products

UNION ALL

SELECT 'ProductLines' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM ProductLines

UNION ALL

SELECT 'Orders' AS table_name, 
       7 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Orders

UNION ALL

SELECT 'OrderDetails' AS table_name, 
       5 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM OrderDetails

UNION ALL

SELECT 'Payments' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name, 
       8 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Offices;

-- Question 1: Which Products Should We Order More of or Less of?
-- Which products are low stock? What is the product performance?
-- low stock = SUM(quantityOrdered)/quantityInStock
  
SELECT productCode, 
       ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
                                             FROM products p
                                            WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10;

-- product performance = SUM(quantityOrdered * priceEach)
SELECT productCode, 
				SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 GROUP BY productCode 
 ORDER BY prod_perf DESC
 LIMIT 10;

-- products to refill
WITH 

low_stock_table AS (
SELECT productCode, 
       ROUND(SUM(quantityOrdered) * 1.0/(SELECT quantityInStock
                                           FROM products p
                                          WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10
),

products_to_restock AS (
SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 WHERE productCode IN (SELECT productCode
                         FROM low_stock_table)
 GROUP BY productCode 
 ORDER BY prod_perf DESC
 LIMIT 10
)
    
SELECT productName, productLine
  FROM products AS p
 WHERE productCode IN (SELECT productCode
                         FROM products_to_restock);
-- Question 2: How Should We Match Marketing and Communication Strategies to Customer Behavior?
-- products.productCode = orderdetails.productCode, od.orderNumber = orders.orderNumber
SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - buyPrice)) AS profit
   FROM products AS p
    JOIN orderdetails AS od
	     ON p.productCode = od.productCode
    JOIN orders AS o
	     ON od.orderNumber = o.orderNumber
GROUP BY o.customerNumber
ORDER BY profit DESC;

-- TOP 5 VIP customers
WITH 
top_5_vip AS (
SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - buyPrice)) AS profit
   FROM products AS p
    JOIN orderdetails AS od
	     ON p.productCode = od.productCode
    JOIN orders AS o
	     ON od.orderNumber = o.orderNumber
GROUP BY o.customerNumber
ORDER BY profit DESC
 LIMIT 5)

SELECT c.contactLastName, c.contactFirstName, c.city, c.country, t.profit
   FROM top_5_vip AS t
      JOIN customers AS c
	      ON t.customerNumber = c.customerNumber;

--  Question 3: How Much Can We Spend on Acquiring New Customers?
-- Customer Lifetime Value = Average of customer profits 
-- we can use the previous query to find out profits per customer
WITH 
profit_per_customer AS (
SELECT o.customerNumber, SUM(od.quantityOrdered * (od.priceEach - buyPrice)) AS profit
   FROM products AS p
    JOIN orderdetails AS od
	     ON p.productCode = od.productCode
    JOIN orders AS o
	     ON od.orderNumber = o.orderNumber
GROUP BY o.customerNumber
ORDER BY profit DESC)

SELECT AVG(profit) AS avg_profit
    FROM profit_per_customer

-- avg profit for customer is 39039.59, so we could spend close to that much to get new customers
  