-- Creating tables with the help of ERD given
CREATE TABLE MEMBERS (
customer_id VARCHAR(1) PRIMARY KEY,
join_date DATE
);
CREATE TABLE MENU (
product_id INTEGER PRIMARY KEY,
product_name VARCHAR(5),
price INTEGER
);
CREATE TABLE SALES (
customer_id VARCHAR(1),
order_date DATE,
product_id INTEGER
);

-- Adding Foreign Key constraints to the respective columns

ALTER TABLE SALES ADD( 
CONSTRAINT R_SALES_CUSTOMER_ID FOREIGN KEY(customer_id) references members(customer_id),
CONSTRAINT R_SALES_PRODUCT_ID FOREIGN KEY(product_id) references menu(product_id));

-- Inserting the sample data that Danny has provided

INSERT ALL
INTO MEMBERS VALUES ('A',to_date('2021-01-07','YYYY-MM-DD'))
INTO MEMBERS VALUES ('B',to_date('2021-01-09','YYYY-MM-DD'))
INTO MEMBERS VALUES ('C',to_date('2021-01-07','YYYY-MM-DD'))
select * from DUAL;

INSERT ALL
INTO MENU VALUES (1,'sushi',10)
INTO MENU VALUES (2,'curry',15)
INTO MENU VALUES (3,'ramen',12)
select * from dual;

INSERT ALL
INTO SALES VALUES ('A',to_date('2021-01-01','YYYY-MM-DD'),1)
INTO SALES VALUES ('A',to_date('2021-01-01','YYYY-MM-DD'),2)
INTO SALES VALUES ('A',to_date('2021-01-07','YYYY-MM-DD'),2)
INTO SALES VALUES ('A',to_date('2021-01-10','YYYY-MM-DD'),3)
INTO SALES VALUES ('A',to_date('2021-01-11','YYYY-MM-DD'),3)
INTO SALES VALUES ('A',to_date('2021-01-11','YYYY-MM-DD'),3)
INTO SALES VALUES ('B',to_date('2021-01-01','YYYY-MM-DD'),2)
INTO SALES VALUES ('B',to_date('2021-01-02','YYYY-MM-DD'),2)
INTO SALES VALUES ('B',to_date('2021-01-04','YYYY-MM-DD'),1)
INTO SALES VALUES ('B',to_date('2021-01-11','YYYY-MM-DD'),1)
INTO SALES VALUES ('B',to_date('2021-01-16','YYYY-MM-DD'),3)
INTO SALES VALUES ('B',to_date('2021-02-01','YYYY-MM-DD'),3)
INTO SALES VALUES ('C',to_date('2021-01-01','YYYY-MM-DD'),3)
INTO SALES VALUES ('C',to_date('2021-01-01','YYYY-MM-DD'),3)
INTO SALES VALUES ('C',to_date('2021-01-07','YYYY-MM-DD'),3)
select * from DUAL;

-- Q1 : What is the total amount each customer spent at the restaurant?
select customer_id,SUM(price) as TOTAL_SPENT 
from sales s inner join menu m on 
s.product_id=m.product_id 
group by customer_id;

-- Q2 : How many days has each customer visited the restaurant? 
select customer_id,count(order_date) as no_of_days_visited from 
(select customer_id,order_date,count(*) from sales group by customer_id,order_date)
A group by customer_id order by customer_id;

-- Q3 : What was the first item from the menu purchased by each customer? 
select customer_id,m.product_name as product_name from
(select customer_id,order_date,product_id,
rank() over (partition by customer_id order by order_date) 
as RANK from sales) A inner join menu m 
on A.product_id=m.product_id where rank=1;

-- Q4 : What is the most purchased item on the menu and how many times was it purchased by all customers? 
select * from (
select product_name,count(s.product_id) as no_of_times_ordered 
from sales s inner join menu m on s.product_id=m.product_id 
group by product_name order by no_of_times_ordered DESC) A where rownum=1;

-- Q5 : Which item was the most popular for each customer? 
WITH ORDER_SET AS (
select customer_id,product_name,count(s.product_id) as no_of_times_ordered
from sales s inner join menu m on s.product_id=m.product_id 
group by customer_id,product_name order by customer_id ASC,
no_of_times_ordered DESC
), POPULAR_SET AS ( 
select customer_id,product_name,no_of_times_ordered,
rank() over (partition by customer_id order by no_of_times_ordered DESC)
as RANK from ORDER_SET)
select customer_id,product_name,no_of_times_ordered from POPULAR_SET where
RANK = 1;

-- Q6 : Which item was purchased first by the customer after they became a member? 
select customer_id,product_name as FIRST_PRODUCT_AFTER_MEMBER from
(select s.customer_id as customer_id,mu.product_name as product_name,
order_date, rank() over (partition by s.customer_id order by
order_date) as RANK from members m 
inner join sales s on m.customer_id=s.customer_id
inner join menu mu on s.product_id=mu.product_id
where order_date>join_date order by customer_id,order_date) A where RANK = 1;

-- Q7 : Which item was purchased just before the customer became a member?
select customer_id,product_name as FIRST_PRODUCT_BEFORE_MEMBER from
(select s.customer_id as customer_id,mu.product_name as product_name,
order_date, rank() over (partition by s.customer_id order by
order_date DESC) as RANK from members m 
inner join sales s on m.customer_id=s.customer_id
inner join menu mu on s.product_id=mu.product_id
where order_date<join_date order by customer_id,order_date DESC) A where RANK = 1;

-- Q8 : What is the total items and amount spent for each member before they became a member?
select s.customer_id,count(s.product_id) as total_items,
sum(m.price) as amount_spent from members m inner join sales s
on m.customer_id=s.customer_id inner join menu m on s.product_id = m.product_id
where order_date<join_date group by s.customer_id order by s.customer_id;

-- Q9 : If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id,
SUM(CASE WHEN product_name='sushi' THEN amount_spent*2*10 ELSE amount_spent*10 END) AS POINTS
FROM (select s.customer_id,m.product_name,sum(m.price) as amount_spent
from sales s inner join menu m on s.product_id = m.product_id
group by s.customer_id,m.product_name order by s.customer_id) A group by customer_id order by customer_id;

-- Q10 : In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select customer_id,
SUM(CASE WHEN (join_date<=order_date and join_date+7>=order_date) 
THEN amount_spent*2*10 ELSE amount_spent*10 END) AS POINTS FROM (
select s.customer_id,m.product_name,join_date,order_date,sum(m.price) as amount_spent
from sales s inner join menu m on s.product_id = m.product_id
inner join members me on s.customer_id=me.customer_id 
where to_char(order_date,'MM')='01'
group by s.customer_id,m.product_name,join_date,order_date order by s.customer_id) A group by customer_id order by customer_id;