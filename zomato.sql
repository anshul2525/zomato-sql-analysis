
-- ZOMATO PROJECT

drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');


drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES 
(1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);



drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Q1) What is the total amount each customer spent on zomato?

select a.userid , sum(b.price) total_amt_spend from sales a inner join product b on a.product_id  = b.product_id
group by a.userid;

-- Q2) how many days does the customers visited zomato?
select userid , count(distinct(created_date)) dates_visited from sales group by userid;

-- Q3) what was the first product purchased by each of the customer

select userid , product_id , first_value(created_date) over(partition by userid order by created_date) First_purchased from sales;
-- or
select * from (select * ,rank() over (partition by userid order by created_date ) rnk from sales) a where rnk in (1);

-- Q4) what is the most purchased item on the menu and how many times was it purchased by all customers

SELECT product_id, COUNT(product_id) cnt
FROM sales 
GROUP BY product_id 
ORDER BY COUNT(product_id)  DESC limit 1;

-- OR
 
SELECT userid, COUNT(product_id) AS cnt
FROM sales
WHERE product_id = (
    SELECT product_id
    FROM sales
    GROUP BY product_id
    ORDER BY COUNT(product_id) DESC
    LIMIT 1
)
GROUP BY userid;
 
--  Q6) WHICH ITEM WAS PURCHASED FIRST BY THE CUSTOMER AFTER THEY BECAME A MEMBER?
select d. * from 
(select c.*, rank() over(partition by userid order by created_date) as rnk from
(select a.userid, a.created_date ,a.product_id ,b.gold_signup_date
from sales a inner join goldusers_signup b on a.userid = b.userid
and created_date > gold_signup_date)c )d where rnk = 1;

-- Q7) WHICH ITEM WASPURCHASED JUST BEFORE BECAMING THE GOLD MEMBER

select d. * from 
(select c.*, rank() over(partition by userid order by created_date DESC) as rnk from
(select a.userid, a.created_date ,a.product_id ,b.gold_signup_date
from sales a inner join goldusers_signup b on a.userid = b.userid
and created_date <= gold_signup_date)c )d where rnk = 1;

-- Q8) WHAT IS THE TOTAL ORDERS AND AMOUNT SPENT FOR EACH MEMBER BEFORE THEY BECAME A MEMEBER

SELECT userid, COUNT(created_date) AS cnt, SUM(price) AS amt_spent
FROM (
    SELECT a.userid, a.created_date, a.product_id, d.price
    FROM sales a
    inner join goldusers_signup b ON a.userid = b.userid AND a.created_date <= b.gold_signup_date
	inner join product d ON a.product_id = d.product_id
) sub
GROUP BY userid;

-- Q9)IF BUYING EACH PRODUCT GENERATES POINTS FOR EG 5RS = 2 ZOMATO POINTS AND EACH PRODUCT HAS DIFFERNT PURCHASING
-- POINTS FOR EG FOR P1 5RS = 1ZOMATO POINT , FOR P2 10RS = 5 ZOMATO POINT AND P3 5RS = 1 ZOMATO POINT

-- CALCULATE POINTS COLLECTED BY EACH CUSTOMERS AND FOR WHICH PRODUCT MOST POINTS HAVE BEEN GIVEN TILL NOW

select userid ,sum(total_points) total_zomato_points, sum(total_points)*2.5 total_money_earned from
(select e.* ,amt/points total_points from
(select d.*, case when product_id = 1 then 5 when product_id =2 then 2 when product_id =3 then 5 else 0 end as points from
(select c.userid ,c.product_id , sum(price) amt from
(select a.*,b.price from sales a inner join product b on a.product_id = b.product_id)c
group by userid , product_id order by userid , product_id)d)e)f group by userid ;


-- TILL NOW
select * from
(select g.* ,rank() over (order by total_zomato_points desc)rnk from
(select product_id ,sum(total_points) total_zomato_points from
(select e.* ,amt/points total_points from
(select d.*, case when product_id = 1 then 5 when product_id =2 then 2 when product_id =3 then 5 else 0 end as points from
(select c.userid ,c.product_id , sum(price) amt from
(select a.*,b.price from sales a inner join product b on a.product_id = b.product_id)c
group by userid , product_id order by userid , product_id)d)e)f group by product_id)g)h where rnk in (1) ;


-- In the first one years after a customer joins the gold progess (including their join date) irrespective
-- of what the customer has purchased they earn 5  zomato points for every 10rs spent who earned more 1 or 3
-- and what was tehir points earniongs in their first year?

-- 1 zomato point = 2rs i.e. 1rs = 0.54 points 

SELECT 
    c.*, 
    d.price * 0.5 AS total_points_earned  
FROM 
(
    SELECT 
        a.userid, 
        a.created_date, 
        a.product_id, 
        b.gold_signup_date
    FROM 
        sales a 
    INNER JOIN 
        goldusers_signup b 
        ON a.userid = b.userid
    WHERE 
        a.created_date >= b.gold_signup_date 
        AND a.created_date <= DATE_ADD(b.gold_signup_date, INTERVAL 1 YEAR)
) c
INNER JOIN 
    product d 
    ON c.product_id = d.product_id;

-- Q11) rnk all the transaction of the customers
select * , rank() over(partition by userid order by created_date) rnk from sales;

-- Q12) Find all the transactions for each member whenever they Are a zomato gold member transaction mark as n/a
select c.* ,case when gold_signup_date is null then 'N/A' else rank () over (partition by userid order by created_date desc)end as rnk from 
(select a.userid, a.created_date ,a.product_id ,b.gold_signup_date
from sales a left join goldusers_signup b on a.userid = b.userid
and created_date > gold_signup_date)c 
