USE classicmodels;

/* Q1. SELECT clause with WHERE, AND, DISTINCT, Wild Card (LIKE)
           a.	Fetch the employee number, first name and last name of those employees who are working as Sales Rep reporting to
                 employee with employeenumber 1102 (Refer employee table)  */


select *from employees;
select employeenumber,firstname,lastname, jobtitle 
           from employees where jobtitle="sales rep" 
            and reportsto=(select employeenumber from employees where employeenumber=1102); 




       /*b.	Show the unique productline values containing the word cars at the end from the products table. */

select*from productlines;
select productline from productlines where productline like'%cars';

/* ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
Q2. CASE STATEMENTS for Segmentation .
                     a. Using a CASE statement, segment customers into three categories based on their country*/
                     
select*from customers;
     Select  customerNumber, customerName, 
     case when country in("usa","canada") then "North america"
     Else
     "other country"
     end as customersegment
     from customers;
     
     
/* ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Q3. Group By with Aggregation functions and Having clause, Date and Time functions

                  a.  Using the OrderDetails table, identify the top 10 products (by productCode) with the highest total order quantity across all orders. */
                  
select*from orderdetails;
select productcode,quantityordered from orderdetails order by quantityOrdered desc limit 10;

     
			/*b. Company wants to analyse payment frequency by month. Extract the month name from the payment date to count the total number of payments 
               for each month and include only those months with a payment count exceeding 20. Sort the results by total number of payments in descending order.*/
               
select *from payments;
SELECT  MONTHNAME(paymentDate) AS month, COUNT(*) AS total_payments FROM Payments
GROUP BY  MONTHNAME(paymentDate) HAVING  total_payments > 20 ORDER BY  total_payments DESC;

/* ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Q4. CONSTRAINTS: Primary, key, foreign key, Unique, check, not null, default
               a 	Create a table named Customers to store customer information. */
   
   
create database customers_orders;
create table customer_s
(
customer_id int primary key ,
first_name varchar(50) not null,
last_name varchar(50) not null,
email varchar(255) unique,
phone_number varchar(20)
);

/* b.	Create a table named Orders to store information about customer orders. */

create table order_s1
(
order_id  int primary key ,
customer_id int ,
orderdate date,
total_amount decimal(10,2),
foreign key(customer_id) references customer_s(customer_id),
check(total_amount>0)
);

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Q5 JOINS
         a. List the top 5 countries (by order count) that Classic Models ships to.*/
         
select *from customers;
select *from orders;

select country,ordernumber from customers 
	inner join orders on customers.customerNumber=orders.customerNumber 
   order by orderNumber DESC limit 5;

/* -----------------------------------------------------------------------------------------------------------------------------------------------------------
Q6. SELF JOIN
           a. Create a table project with below fields. */
           
CREATE TABLE PROJECT (
EMPLOYEEID INT PRIMARY KEY auto_increment,
FULL_NAME VARCHAR(100) NOT NULL,
GENDER ENUM('MALE','FEMALE'),
MANAGERID int
);
INSERT INTO PROJECT VALUES(1,'PRANAYA','MALE',3),
						(2,'PRIYANKA','FEMALE',1),
						(3,'PREETY','FEMALE',null),
                        (4,'ANURAG','MALE',1),
                        (5,'SAMBIT','MALE',1),
                        (6,'RAJESH','MALE',3),
                        (7,'HINA','FEMALE',3);
                        
SELECT*FROM PROJECT;
SELECT E1.FULL_NAME,M1.FULL_NAME AS 'MANAGERS NAME'
FROM PROJECT E1 JOIN PROJECT M1
ON E1.EMPLOYEEID=M1.MANAGERID;      \

/* -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Q7. DDL Commands: Create, Alter, Rename
			a. Create table facility. Add the below fields into it.
			●	Facility_ID
			●	Name
			●	State
			●	Country */
            
            
CREATE TABLE FACILITY
(
FACILITYID int,
NAME_  VARCHAR(100) ,
STATE VARCHAR(100),
COUNTRY VARCHAR(100)
);
ALTER TABLE FACILITY
MODIFY FACILITYID INT PRIMARY KEY AUTO_INCREMENT;
ALTER table FACILITY 
ADD CITY varchar(100) NOT NULL;


/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------
Q8. Views in SQL
						a. Create a view named product_category_sales that provides insights into sales performance by product category */
                                 
 create view product_category_sales as
 select productLine,orderdetails.quantityOrdered*orderdetails.priceEach as total_sales,count(quantityOrdered) 
 from products,orderdetails;
 SELECT*FROM product_category_VIEW;

/* --------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Q9. Stored Procedures in SQL with parameters
         a. Create a stored procedure Get_country_payments which takes in year and country as inputs and gives year wise, country wise total amount as an output.
	       Format the total amount to nearest thousand unit (K) */
           
           
DELIMITER //

CREATE PROCEDURE Get_country_payments(
    IN input_year INT,
    IN input_country VARCHAR(255),
    OUT output_year INT,
    OUT output_country VARCHAR(255),
    OUT total_amount_formatted VARCHAR(50)
)
BEGIN
    DECLARE total_amount DECIMAL(15, 2);

    SELECT ROUND(SUM(p.amount), -3), input_year, input_country
    INTO total_amount, output_year, output_country
    FROM Payments p
    JOIN Customers c ON p.customerNumber = c.customerNumber
    WHERE YEAR(p.paymentDate) = input_year
      AND c.country = input_country;

    SET total_amount_formatted = CONCAT(total_amount / 1000, 'K');
END //
DELIMITER ;

CALL Get_country_payments(2023, 'USA', @output_year, @output_country, @formatted_amount);




 
/* --------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
Q10. Window functions - Rank, dense_rank, lead and lag
				a) Using customers and orders tables, rank the customers based on their order frequency */
                
                
 SELECT
    c.customerNumber,
    c.customerName,
    COUNT(o.orderNumber) AS order_count,
    RANK() OVER (ORDER BY COUNT(o.orderNumber) DESC) AS order_frequency_rank
FROM
    customers c
LEFT JOIN
    orders o ON c.customerNumber = o.customerNumber
GROUP BY
    c.customerNumber,
    c.customerName
ORDER BY
    order_frequency_rank;
    
 /*b) Calculate year wise, month name wise count of orders and year over year (YoY) percentage change. Format the YoY values in no decimals and show in % sign.*/
 
 WITH order_summary AS (
    SELECT
        YEAR(orderDate) AS order_year,
        MONTHNAME(orderDate) AS order_month,
        COUNT(*) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY YEAR(orderDate) ORDER BY MONTH(orderDate)) AS month_order_rank
    FROM
        Orders
    GROUP BY
        order_year, order_month
),
yearly_summary AS (
    SELECT
        order_year,
        order_month,
        total_orders,
        LAG(total_orders) OVER (PARTITION BY order_year ORDER BY month_order_rank) AS prev_year_total_orders
    FROM
        order_summary
)
SELECT
    order_year AS `YEAR`,
    order_month AS `MONTH`,
    total_orders AS `TOTAL ORDERS`,
    CONCAT(FORMAT(IFNULL(((total_orders - prev_year_total_orders) / NULLIF(prev_year_total_orders, 0)) * 100, 0), 0), '%') AS `%YOY CHANGES`
FROM
    yearly_summary
ORDER BY
    order_year, month_order_rank;
     
     
/*  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Q11.Subqueries and their applications
		a. Find out how many product lines are there for which the buy price value is greater than the average of buy price value. Show the output as product line and 
          its count. */
          
SELECT
    productLine,
    COUNT(*) AS line_count
FROM
    Products
WHERE
    buyPrice > (SELECT AVG(buyPrice) FROM Products)
GROUP BY
    productLine;
    
/* --------------------------------------------------------------------------------------------------------------------------------------------------------------------
Q12. ERROR HANDLING in SQL
				Create the table Emp_EH. Below are its fields.
				●	EmpID (Primary Key)
				●	EmpName
				●	EmailAddress */
   
  CREATE TABLE Emp_EH (
    EmpID INT PRIMARY KEY,
    EmpName VARCHAR(255),
    EmailAddress VARCHAR(255)
);

DELIMITER //
CREATE PROCEDURE Insert_Emp_EH (
    IN p_EmpID INT,
    IN p_EmpName VARCHAR(255),
    IN p_EmailAddress VARCHAR(255)
)
BEGIN
    DECLARE continue_handler INT DEFAULT 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET continue_handler = 0;
        SELECT 'Error occurred' AS Message;
    END;

    START TRANSACTION;

    INSERT INTO Emp_EH (EmpID, EmpName, EmailAddress)
    VALUES (p_EmpID, p_EmpName, p_EmailAddress);

    IF continue_handler = 1 THEN
        COMMIT;
        SELECT 'Insert successful' AS Message;
    END IF;
END //

DELIMITER ;

CALL Insert_Emp_EH(1, 'John Doe', 'john.doe@example.com'); 
    
/* ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Q13. TRIGGERS
			Create the table Emp_BIT. Add below fields in it.
			●	Name
			●	Occupation
			●	Working_date
			●	Working_hours */
 
DELIMITER //
CREATE TRIGGER before_insert_emp_bit
BEFORE INSERT ON Emp_BIT
FOR EACH ROW
BEGIN
    IF NEW.Working_hours < 0 THEN
        SET NEW.Working_hours = -NEW.Working_hours;
    END IF;
END //
DELIMITER ;
INSERT INTO Emp_bit VALUES ('Alice', 'Engineer', '2020-10-05', -8);








     



