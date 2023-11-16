/*  
Note: 
1. In table [customer_order], change the datatype of column [order_time] from TIMESTAMP to DATETIME.
Otherwise, we can't insert new values to table [customer_order].

2. In table [pizza_names], [pizza_recipes], and [pizza_toppings], change datatype from TEXT to VARCHAR. 
Otherwise, we will face the error in Q4.
*/ 


CREATE DATABASE pizza_runner;

DROP TABLE IF EXISTS pizza_runner.dbo.runners;
CREATE TABLE pizza_runner.dbo.runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO pizza_runner.dbo.runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS pizza_runner.dbo.customer_orders;
CREATE TABLE pizza_runner.dbo.customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" DATETIME     
);

INSERT INTO pizza_runner.dbo.customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS pizza_runner.dbo.runner_orders;
CREATE TABLE pizza_runner.dbo.runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO pizza_runner.dbo.runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_runner.dbo.pizza_names;
CREATE TABLE pizza_runner.dbo.pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" VARCHAR(10)
);
INSERT INTO pizza_runner.dbo.pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_runner.dbo.pizza_recipes;
CREATE TABLE pizza_runner.dbo.pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" VARCHAR(30)
);
INSERT INTO pizza_runner.dbo.pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_runner.dbo.pizza_toppings;
CREATE TABLE pizza_runner.dbo.pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" VARCHAR(20)
);
INSERT INTO pizza_runner.dbo.pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

  -----------------------------------
--A. Data Cleaning: Pizza Metrics--
-----------------------------------

-- Create a new temporary table: #customer_orders_temp

SELECT 
    order_id,
    customer_id,
    pizza_id,
    CASE 
    	WHEN exclusions IS NULL OR exclusions LIKE 'null' THEN ''
      	ELSE exclusions 
      	END AS exclusions,
    CASE 
    	WHEN extras IS NULL OR extras LIKE 'null' THEN ''
      	ELSE extras 
      	END AS extras,
    order_time
INTO #customer_orders_temp
FROM customer_orders;

SELECT * FROM #customer_orders_temp;

-- Create a new temporary table: #runner_orders_temp

SELECT 
    order_id,
    runner_id,
    CAST(
    	CASE WHEN pickup_time LIKE 'null' THEN NULL ELSE pickup_time END 
	AS DATETIME) AS pickup_time,
    CAST(
    	CASE 
	    WHEN distance LIKE 'null' THEN NULL
	    WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
	    ELSE distance END
        AS FLOAT) AS distance,
    CAST(
    	CASE 
	    WHEN duration LIKE 'null' THEN NULL
	    WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
	    WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
	    WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
	    ELSE duration END
        AS INT) AS duration,
    CASE
        WHEN cancellation IN ('null', 'NaN', '') THEN NULL 
        ELSE cancellation
        END AS cancellation
INTO #runner_orders_temp
FROM runner_orders;

SELECT * FROM #runner_orders_temp;

--------------------
--A. Pizza Metrics--
--------------------

-- 1. How many pizzas were ordered?

SELECT COUNT(order_id) AS pizza_count
FROM #customer_orders_temp;


-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS order_count
FROM #customer_orders_temp;


-- 3. How many successful orders were delivered by each runner?

SELECT 
    runner_id,
    COUNT(order_id) AS successful_orders
FROM #runner_orders_temp
WHERE cancellation IS NULL
GROUP BY runner_id;


-- 4. How many of each type of pizza was delivered?

-- Approach 1:
SELECT 
    p.pizza_name,
    COUNT(*) AS deliver_count
FROM #customer_orders_temp c
    JOIN pizza_names p ON c.pizza_id = p.pizza_id
WHERE c.order_id IN (
    SELECT order_id 
    FROM #runner_orders_temp
    WHERE cancellation IS NULL)
GROUP BY p.pizza_name;

-- Aproach 2:

SELECT 
    p.pizza_name,
    COUNT(*) AS deliver_count
FROM #customer_orders_temp c
    JOIN pizza_names p ON c.pizza_id = p.pizza_id
    JOIN #runner_orders_temp r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY p.pizza_name;


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT 
    customer_id,
    SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS Meatlovers,
    SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS Vegetarian
FROM #customer_orders_temp
GROUP BY customer_id;


-- 6. What was the maximum number of pizzas delivered in a single order?

--Approach 1:
SELECT MAX(pizza_count) AS max_count
FROM (
    SELECT 
        c.order_id,
        COUNT(c.pizza_id) AS pizza_count
    FROM #customer_orders_temp c
        JOIN #runner_orders_temp r ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL
    GROUP BY c.order_id
) tmp;

--Approach 2:
WITH max_number_of_pizza 
AS 
(
    SELECT 
        c.order_id,
        COUNT(c.pizza_id) AS pizza_count
    FROM #customer_orders_temp c
        JOIN #runner_orders_temp r ON c.order_id = r.order_id
    WHERE r.cancellation IS NULL
    GROUP BY c.order_id
)

SELECT MAX(pizza_count) as max_number_of_pizza_delivered FROM max_number_of_pizza


-- 7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT 
    c.customer_id,
    SUM(CASE WHEN exclusions != '' OR extras != '' THEN 1 ELSE 0 END) AS has_change,
    SUM(CASE WHEN exclusions = '' AND extras = '' THEN 1 ELSE 0 END) AS no_change
FROM #customer_orders_temp c
    JOIN #runner_orders_temp r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id;


-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT 
    SUM(CASE WHEN exclusions != '' AND extras != '' THEN 1 ELSE 0 END) AS change_both
FROM #customer_orders_temp c
    JOIN #runner_orders_temp r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL;


-- 9.What was the total volume of pizzas ordered for each hour of the day?

SELECT 
    DATEPART(HOUR, order_time) AS hour_of_day,
    COUNT(order_id) AS pizza_volume
FROM #customer_orders_temp
GROUP BY DATEPART(HOUR, order_time)
ORDER BY hour_of_day;


-- 10. What was the volume of orders for each day of the week?

SELECT 
    DATENAME(weekday, order_time) AS week_day,
    COUNT(order_id) AS order_volume
FROM #customer_orders_temp
GROUP BY DATENAME(weekday, order_time);

-------------------------------------
--B. Runner and Customer Experience--
-------------------------------------

--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
    DATEPART(week, registration_date) AS week_period,
    COUNT(*) AS runner_count
FROM runners
GROUP BY DATEPART(week, registration_date);


-- 2. What was the average time in minutes 
-- it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH time_pickup
AS
(
    SELECT 
        r.runner_id,
        c.order_time, 
        r.pickup_time, 
        DATEDIFF(MINUTE, c.order_time, r.pickup_time) as time_to_pickup_order
    FROM #runner_orders_temp as r 
    JOIN #customer_orders_temp as c on r.order_id = c.order_id
    WHERE r.cancellation is NULL
    GROUP By r.runner_id, c.order_time, r.pickup_time
)

SELECT runner_id, AVG(time_to_pickup_order) as time_pickup_the_order
FROM time_pickup
GROUP By runner_id;

-- Q3. Is there any relationship between the number of pizzas 
-- and how long the order takes to prepare?

WITH relation_number_of_pizza_and_time_to_prepare
AS
(
    SELECT 
        r.order_id, 
        DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS pickup_minutes,
        COUNT(c.pizza_id) as count_pizza_of_order
    FROM #customer_orders_temp as c 
        JOIN #runner_orders_temp as r 
        ON r.order_id = c.order_id
    WHERE r.cancellation is NULL
    GROUP BY r.order_id, c.order_time, r.pickup_time
)

SELECT count_pizza_of_order, AVG(pickup_minutes) as time_to_prepare
FROM relation_number_of_pizza_and_time_to_prepare
GROUP BY count_pizza_of_order;

-- Result:
-- More pizzas, longer time to prepare.
-- 2 pizzas took 6 minutes more to prepare, 3 pizza took 12 minutes more to prepare.
-- On average, it took 6 * (number of pizzas - 1) minutes more to prepare the next pizz

-- Q4. What was the average distance travelled for each customer?

SELECT 
    c.customer_id,
    ROUND(AVG(r.distance), 1) as avg_distance
FROM #customer_orders_temp as c 
    JOIN #runner_orders_temp as r 
    ON r.order_id = c.order_id
WHERE r.cancellation is NULL
GROUP BY c.customer_id; 

-- Q5. What was the difference between the longest 
-- and shortest delivery times for all orders?

SELECT MAX(r.duration) - MIN(r.duration) as time_different
FROM #runner_orders_temp as r;

-- Q6. What was the average speed for each runner for each delivery 
-- and do you notice any trend for these values?

SELECT 
    r.runner_id, r.order_id,
    r.distance, r.duration, COUNT(c.order_id) as count_pizza,
    CONCAT(AVG(ROUND(r.distance*60/r.duration, 1)), ' km/h') as avg_runner_speed_for_each_delivery
FROM #runner_orders_temp as r 
    JOIN #customer_orders_temp as c
ON r.order_id = c.order_id
WHERE r.cancellation is NULL
GROUP BY r.runner_id, r.order_id, r.distance, r.duration
ORDER BY r.runner_id;

-- Q7. What is the successful delivery percentage for each runner?

WITH runner_order
AS
(
    SELECT 
        r.runner_id,
        SUM(CASE WHEN r.cancellation IS NULL then 1 ELSE 0 END ) AS order_delivered,
        COUNT(r.runner_id) AS total_order
    FROM #runner_orders_temp AS r 
    GROUP BY r.runner_id
)

SELECT r.runner_id, (r.order_delivered*100/total_order) AS percent_sucessful_delivery_order
FROM runner_order AS r
ORDER BY r.runner_id

---------------------------------------------
--C. Data Cleaning: Ingredient Optimisation--
---------------------------------------------

-- 1. Create a new temporary table #toppingsBreak to separate toppings into multiple rows

SELECT 
  pr.pizza_id,
  TRIM(value) AS topping_id,
  pt.topping_name
INTO #toppingsBreak
FROM pizza_recipes pr
  CROSS APPLY STRING_SPLIT(toppings, ',') AS t
JOIN pizza_toppings pt
  ON TRIM(t.value) = pt.topping_id;
  
SELECT * FROM #toppingsBreak;

-- 2. Add an identity column record_id to #customer_orders_temp to select each ordered pizza more easily

ALTER TABLE #customer_orders_temp
ADD record_id INT IDENTITY(1,1);

SELECT *
FROM #customer_orders_temp;

-- 3. Create a new temporary table extrasBreak to separate extras into multiple rows

SELECT 
  c.record_id,
  TRIM(e.value) AS extra_id
INTO #extrasBreak 
FROM #customer_orders_temp c
  CROSS APPLY STRING_SPLIT(extras, ',') AS e;

SELECT *
FROM #extrasBreak;

-- 4. Create a new temporary table exclusionsBreak to separate into exclusions into multiple rows

SELECT 
  c.record_id,
  TRIM(e.value) AS exclusion_id
INTO #exclusionsBreak 
FROM #customer_orders_temp c
  CROSS APPLY STRING_SPLIT(exclusions, ',') AS e;

SELECT *
FROM #exclusionsBreak;

------------------------------
--C. Ingredient Optimisation--
------------------------------

-- 1. What are the standard ingredients for each pizza?

SELECT p.pizza_name, STRING_AGG(tp.topping_name, ', ') as topping_name
FROM pizza_names as p
JOIN #toppingsBreak as tp on p.pizza_id = tp.pizza_id
GROUP BY p.pizza_name

-- Q2. What was the most commonly added extra?

SELECT p.topping_id, p.topping_name, COUNT(*) as most_add_extra
FROM #extrasBreak as e
JOIN pizza_toppings as p on e.extra_id = p.topping_id
GROUP BY p.topping_id, p.topping_name

-- Q3. What was the most common exclusion?

SELECT p.topping_id, p.topping_name, COUNT(*) as most_remove_exclusion
FROM #exclusionsBreak as e
JOIN pizza_toppings as p on e.exclusion_id = p.topping_id
GROUP BY p.topping_id, p.topping_name;

-- Q4.Generate an order item for each record in the customers_orders table in the format of one of the following
    -- Meat Lovers
    -- Meat Lovers - Exclude Beef
    -- Meat Lovers - Extra Bacon
    -- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- To solve this question:
    -- Create 3 CTEs: extras_cte, exclusions_cte, and union_cte combining two tables
    -- Use the union_cte to LEFT JOIN with the customer_orders_temp and JOIN with the pizza_name
    -- Use the CONCAT_WS with STRING_AGG to get the result

WITH CTEs_Extra AS 
(
    SELECT e.record_id, 'Extra ' + STRING_AGG(p.topping_name, ', ') as record_options
    FROM #extrasBreak as e
    JOIN pizza_toppings as p on e.extra_id = p.topping_id
    GROUP BY e.record_id
), CTEs_Exclusion AS
(

    SELECT e.record_id, 'Exclusion ' + STRING_AGG(p.topping_name, ', ') as record_options
    FROM #exclusionsBreak as e
    JOIN pizza_toppings as p on e.exclusion_id = p.topping_id
    GROUP BY e.record_id
), CTEs_Union AS (
    SELECT * FROM CTEs_Extra
    UNION
    SELECT * FROM CTEs_Exclusion
)

SELECT 
    c.record_id,
    c.order_id,
    c.customer_id,
    c.pizza_id,
    c.order_time,
    CONCAT_WS(' - ', p.pizza_name, STRING_AGG(u.record_options, ' - ')) AS pizza_info
FROM #customer_orders_temp c
    LEFT JOIN CTEs_Union u ON c.record_id = u.record_id
    JOIN pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY
    c.record_id, 
    c.order_id,
    c.customer_id,
    c.pizza_id,
    c.order_time,
    p.pizza_name
ORDER BY record_id;

--------------------------
--D. Pricing and Ratings--
--------------------------

--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
--how much money has Pizza Runner made so far if there are no delivery fees?

SELECT 
    SUM(CASE WHEN p.pizza_name = 'Meatlovers' THEN 12
        ELSE 10 END) AS money_earned
FROM #customer_orders_temp as c
    JOIN pizza_names as p on c.pizza_id = p.pizza_id
    JOIN #runner_orders_temp as r on c.order_id = r.order_id
WHERE r.cancellation is NULL

-- 2.What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

DECLARE @basecost INT
SET @basecost = 138 	-- @basecost = result of the previous question

SELECT 
  @basecost + SUM(CASE WHEN p.topping_name = 'Cheese' THEN 2 ELSE 1 END) updated_money
FROM #extrasBreak e
    JOIN pizza_toppings p ON e.extra_id = p.topping_id;

--3. --The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--how would you design an additional table for this new dataset - generate a schema for this new table and 
--insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS ratings
CREATE TABLE ratings (
    order_id INT,
    rating INT
);
INSERT INTO ratings (order_id, rating)
VALUES 
  (1,3),
  (2,5),
  (3,3),
  (4,1),
  (5,5),
  (7,3),
  (8,4),
  (10,3);

 SELECT * FROM ratings;  

-- 4. Using your newly generated table - 
-- can you join all of the information together to form a table 
-- which has the following information for successful deliveries?
    -- customer_id
    -- order_id
    -- runner_id
    -- rating
    -- order_time
    -- pickup_time
    -- Time between order and pickup
    -- Delivery duration
    -- Average speed
    -- Total number of pizzas

SELECT 
    co.customer_id,
    ro.order_id,
    ro.runner_id,
    ra.rating,
    co.order_time,
    ro.pickup_time,
    DATEDIFF(minute, co.order_time, ro.pickup_time) as time_to_delivery,
    ro.duration as delivery_duration,
    ROUND(AVG((ro.distance*60/ro.duration)), 1) as average_speed,
    COUNT(co.order_id) as total_number_of_pizzas
FROM #customer_orders_temp as co
    JOIN #runner_orders_temp as ro on co.order_id = ro.order_id 
    JOIN ratings as ra on co.order_id = ra.order_id
WHERE ro.cancellation is NULL
GROUP BY co.customer_id, ro.order_id, ro.runner_id, ra.rating, co.order_time, ro.pickup_time, ro.duration
ORDER BY ro.order_id


--5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
--and each runner is paid $0.30 per kilometre traveled - 
-- how much money does Pizza Runner have left over after these deliveries?

DECLARE @basecost INT
SET @basecost = 138

SELECT 
  @basecost AS revenue,
  ROUND(SUM(distance)*0.3, 1) AS runner_paid,
  @basecost - SUM(distance)*0.3 AS money_left
FROM #runner_orders_temp;
