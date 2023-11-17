# 🍜 Case Study - Danny's Diner

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## 📕 Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:
- sales
- menu
- members
## ❓ Case Study Questions

#### 1. What is the total amount each customer spent at the restaurant?

```TSQL
SELECT s.customer_id, SUM(m.price) AS total_amt
FROM sales AS s 
JOIN menu AS m on s.product_id = m.product_id
GROUP BY s.customer_id;
```
##### Result
| customer_id | total_amt |
|-------------|-----------|
| A           | 76        |
| B           | 74        |
| C           | 36        |

#### 2. How many days has each customer visited the restaurant?

```TSQL
SELECT s.customer_id, COUNT(DISTINCT(s.order_date)) as count_vst
FROM sales as s
GROUP BY s.customer_id;
```
##### Result
| customer_id | count_vst |
|-------------|-----------|
| A           | 4         |
| B           | 6         |
| C           | 2         |


#### 3. What was the first item from the menu purchased by each customer?

```TSQL
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
```
##### Result
| customer_id | order_date | product_name |
|-------------|------------|--------------|
| A           | 2021-01-01 | curry        |
| A           | 2021-01-01 | sushi        |
| B           | 2021-01-01 | curry        |
| C           | 2021-01-01 | ramen        |


#### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```TSQL
SELECT TOP 1 m.product_name, COUNT(s.product_id) as most_purchase
FROM sales as s
JOIN menu as m on s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY most_purchase DESC;
```
##### Result
| product_name | most_purchase |
|--------------|---------------|
| ramen        | 8             |

#### 5. Which item was the most popular for each customer?

```TSQL
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
```
##### Result
| customer_id | product_name | count_purchase |
|-------------|--------------|-----------------|
| A           | ramen        | 3               |
| B           | sushi        | 2               |
| B           | curry        | 2               |
| B           | ramen        | 2               |
| C           | ramen        | 3               |

#### 6. Which item was purchased first by the customer after they became a member?

```TSQL
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
```
##### Result
| customer_id | join_date  | order_date | product_id | product_name |
|-------------|------------|------------|------------|--------------|
| A           | 2021-01-07 | 2021-01-10 | 3          | ramen        |
| B           | 2021-01-09 | 2021-01-11 | 1          | sushi        |


#### 7. Which item was purchased just before the customer became a member?

```TSQL
SELECT s.customer_id, m.join_date, s.order_date, s.product_id, me.product_name
FROM sales as s 
JOIN members as m on s.customer_id = m.customer_id
JOIN menu as me on s.product_id = me.product_id
WHERE s.order_date < m.join_date
```
##### Result
| customer_id | join_date  | order_date | product_id | product_name |
|-------------|------------|------------|------------|--------------|
| A           | 2021-01-07 | 2021-01-01 | 1          | sushi        |
| A           | 2021-01-07 | 2021-01-01 | 2          | curry        |
| B           | 2021-01-09 | 2021-01-01 | 2          | curry        |
| B           | 2021-01-09 | 2021-01-02 | 2          | curry        |
| B           | 2021-01-09 | 2021-01-04 | 1          | sushi        |


#### 8. What is the total items and amount spent for each member before they became a member?

```TSQL
SELECT s.customer_id, COUNT(s.product_id) as total_items, SUM(me.price) as amount_spent
FROM sales as s 
JOIN members as m on s.customer_id = m.customer_id
JOIN menu as me on s.product_id = me.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;
```
##### Result
| customer_id | total_items | amount_spent |
|-------------|-------------|--------------|
| A           | 2           | 25           |
| B           | 3           | 40           |


#### 9. If each $1 spent equates to 10 points and sushi has a x2 points multiplier - how many points would each customer have?

```TSQL
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
```
##### Result
| customer_id | total_points |
|-------------|--------------|
| A           | 860          |
| B           | 940          |
| C           | 360          |


#### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```TSQL
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
```
##### Result
| customer_id | total_point |
|-------------|-------------|
| A           | 152         |
| B           | 124         |


#### 11. Bonus Questions: Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

```TSQL
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
```
##### Result
| customer_id | order_date | product_name | price | member |
|-------------|------------|--------------|-------|--------|
| A           | 2021-01-01 | sushi         | 10    | N      |
| A           | 2021-01-01 | curry         | 15    | N      |
| A           | 2021-01-07 | curry         | 15    | Y      |
| A           | 2021-01-10 | ramen         | 12    | Y      |
| A           | 2021-01-11 | ramen         | 12    | Y      |
| A           | 2021-01-11 | ramen         | 12    | Y      |
| B           | 2021-01-01 | curry         | 15    | N      |
| B           | 2021-01-02 | curry         | 15    | N      |
| B           | 2021-01-04 | sushi         | 10    | N      |
| B           | 2021-01-11 | sushi         | 10    | Y      |
| B           | 2021-01-16 | ramen         | 12    | Y      |
| B           | 2021-02-01 | ramen         | 12    | Y      |
| C           | 2021-01-01 | ramen         | 12    | N      |
| C           | 2021-01-01 | ramen         | 12    | N      |
| C           | 2021-01-07 | ramen         | 12    | N      |

#### 12. Danny also requires further information about the ranking of customer products,but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

```TSQL
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
```
##### Result
| customer_id | order_date | product_name | price | member | ranking |
|-------------|------------|--------------|-------|--------|---------|
| A           | 2021-01-01 | sushi         | 10    | N      | NULL    |
| A           | 2021-01-01 | curry         | 15    | N      | NULL    |
| A           | 2021-01-07 | curry         | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen         | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen         | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen         | 12    | Y      | 3       |
| B           | 2021-01-01 | curry         | 15    | N      | NULL    |
| B           | 2021-01-02 | curry         | 15    | N      | NULL    |
| B           | 2021-01-04 | sushi         | 10    | N      | NULL    |
| B           | 2021-01-11 | sushi         | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen         | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen         | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen         | 12    | N      | NULL    |
| C           | 2021-01-01 | ramen         | 12    | N      | NULL    |
| C           | 2021-01-07 | ramen         | 12    | N      | NULL    |


