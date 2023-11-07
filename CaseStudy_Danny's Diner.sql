CREATE DATABASE CaseStudy#1
GO

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_amt
FROM sales AS s 
JOIN menu AS m on s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id, COUNT(DISTINCT(s.order_date)) as count_vst
FROM sales as s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH tempt
AS
(
    SELECT s.customer_id, s.order_date, m.product_name,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date ASC) as rank
    FROM sales as s
    JOIN menu as m on s.product_id = m.product_id
)

SELECT customer_id, order_date, product_name
FROM tempt
WHERE rank = 1
GROUP BY customer_id, order_date, product_name

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name, COUNT(s.product_id) as most_purchase
FROM sales as s
JOIN menu as m on s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY most_purchase DESC;

-- 5. Which item was the most popular for each customer?
WITH tempt
AS 
(
    SELECT s.customer_id, m.product_name, COUNT(m.product_name) as count_purchase,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_name) DESC) as rank
    FROM sales as s
    JOIN menu as m on s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)

SELECT customer_id, product_name, count_purchase FROM tempt
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH tempt
AS 
(
    SELECT s.customer_id, m.join_date, s.order_date, s.product_id, me.product_name,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) as rank
    FROM sales as s 
    JOIN members as m on s.customer_id = m.customer_id
    JOIN menu as me on s.product_id = me.product_id
    WHERE s.order_date > m.join_date
)

SELECT customer_id, join_date, order_date, product_id, product_name
FROM tempt
WHERE rank = 1


-- 7. Which item was purchased just before the customer became a member?

SELECT s.customer_id, m.join_date, s.order_date, s.product_id, me.product_name
FROM sales as s 
JOIN members as m on s.customer_id = m.customer_id
JOIN menu as me on s.product_id = me.product_id
WHERE s.order_date < m.join_date

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(s.product_id) as total_items, SUM(me.price) as amount_spent
FROM sales as s 
JOIN members as m on s.customer_id = m.customer_id
JOIN menu as me on s.product_id = me.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a x2 points multiplier - how many points would each customer have?
with points_table
AS 
(
    SELECT *, 
        (CASE When me.product_name = 'sushi' THEN me.price*10*2
        ELSE me.price*10 
        END) as points
    FROM menu as me
)

SELECT s.customer_id, SUM(p.points) as total_points
FROM sales as s
JOIN points_table as p on s.product_id = p.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH tempt
AS
(
    SELECT s.customer_id, s.order_date, mem.join_date, me.price,
        (
            
            CASE When DATEDIFF(DAY,mem.join_date, s.order_date) <= 7 then me.price*2
            else me.price
            END
        ) as points
    FROM sales as s
        JOIN menu as me on s.product_id = me.product_id
        JOIN members as mem on s.customer_id = mem.customer_id
)

SELECT tempt.customer_id, SUM(tempt.points) as total_point
FROM tempt
WHERE tempt.order_date <= '2021-01-31'
GROUP BY tempt.customer_id

--Bonus Questions
-- Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT s.customer_id, s.order_date, m.product_name, m.price,
    (CASE
      WHEN mm.join_date > s.order_date THEN 'N'
      WHEN mm.join_date <= s.order_date THEN 'Y'
      ELSE 'N'
    END) AS member
FROM sales AS s
JOIN menu AS m
   ON s.product_id = m.product_id
JOIN members AS mm
   ON s.customer_id = mm.customer_id;

-- Danny also requires further information about the ranking of customer products, 
-- but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records 
-- when customers are not yet part of the loyalty program.

WITH summary_cte AS 
(
   SELECT s.customer_id, s.order_date, m.product_name, m.price,
      CASE
      WHEN mm.join_date > s.order_date THEN 'N'
      WHEN mm.join_date <= s.order_date THEN 'Y'
      ELSE 'N' END AS member
   FROM sales AS s
   LEFT JOIN menu AS m
      ON s.product_id = m.product_id
   LEFT JOIN members AS mm
      ON s.customer_id = mm.customer_id
)

SELECT *, CASE
   WHEN member = 'N' then NULL
   ELSE
      RANK () OVER(PARTITION BY customer_id, member
      ORDER BY order_date) END AS ranking
FROM summary_cte;

