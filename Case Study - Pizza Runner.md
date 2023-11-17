# 🍕 Case Study - Pizza Runner
### ❓Case Study Questions
## A. Pizza Metrics
### Data cleaning
  
  * Create a temporary table ```#customer_orders_temp``` from ```customer_orders``` table:
  	* Convert ```null``` values and ```'null'``` text values in ```exclusions``` and ```extras``` into blank ```''```.
  
  ```TSQL
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
  
  SELECT *
  FROM #customer_orders_temp;
  ```
| order_id | customer_id | pizza_id | exclusions | extras | order_time               |
|----------|-------------|----------|------------|--------|--------------------------|
| 1        | 101         | 1        |            |        | 2020-01-01 18:05:02.000  |
| 2        | 101         | 1        |            |        | 2020-01-01 19:00:52.000  |
| 3        | 102         | 1        |            |        | 2020-01-02 23:51:23.000  |
| 3        | 102         | 2        |            |        | 2020-01-02 23:51:23.000  |
| 4        | 103         | 1        | 4          |        | 2020-01-04 13:23:46.000  |
| 4        | 103         | 1        | 4          |        | 2020-01-04 13:23:46.000  |
| 4        | 103         | 2        | 4          |        | 2020-01-04 13:23:46.000  |
| 5        | 104         | 1        |            | 1      | 2020-01-08 21:00:29.000  |
| 6        | 101         | 2        |            |        | 2020-01-08 21:03:13.000  |
| 7        | 105         | 2        |            | 1      | 2020-01-08 21:20:29.000  |
| 8        | 102         | 1        |            |        | 2020-01-09 23:54:33.000  |
| 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10 11:22:59.000  |
| 10       | 104         | 1        |            |        | 2020-01-11 18:34:49.000  |
  
  
  * Create a temporary table ```#runner_orders_temp``` from ```runner_orders``` table:
  	* Convert ```'null'``` text values in ```pickup_time```, ```duration``` and ```cancellation``` into ```null``` values. 
	* Cast ```pickup_time``` to DATETIME.
	* Cast ```distance``` to FLOAT.
	* Cast ```duration``` to INT.
  
  ```TSQL
  SELECT 
    order_id,
    runner_id,
    CAST(
    	CASE WHEN pickup_time LIKE 'null' THEN NULL ELSE pickup_time END 
	    AS DATETIME) AS pickup_time,
    CAST(
    	CASE WHEN distance LIKE 'null' THEN NULL
	      WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
	      ELSE distance END
      AS FLOAT) AS distance,
    CAST(
    	CASE WHEN duration LIKE 'null' THEN NULL
	      WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
	      WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
	      WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
	      ELSE duration END
      AS INT) AS duration,
    CASE WHEN cancellation IN ('null', 'NaN', '') THEN NULL 
        ELSE cancellation
        END AS cancellation
INTO #runner_orders_temp
FROM runner_orders;
  
SELECT *
FROM #runner_orders_temp;

```
| order_id | runner_id | pickup_time             | distance | duration | cancellation             |
|----------|-----------|-------------------------|----------|----------|--------------------------|
| 1        | 1         | 2020-01-01 18:15:34.000 | 20       | 32       | NULL                     |
| 2        | 1         | 2020-01-01 19:10:54.000 | 20       | 27       | NULL                     |
| 3        | 1         | 2020-01-03 00:12:37.000 | 13.4     | 20       | NULL                     |
| 4        | 2         | 2020-01-04 13:53:03.000 | 23.4     | 40       | NULL                     |
| 5        | 3         | 2020-01-08 21:10:57.000 | 10       | 15       | NULL                     |
| 6        | 3         | NULL                    | NULL     | NULL     | Restaurant Cancellation  |
| 7        | 2         | 2020-01-08 21:30:45.000 | 25       | 25       | NULL                     |
| 8        | 2         | 2020-01-10 00:15:02.000 | 23.4     | 15       | NULL                     |
| 9        | 2         | NULL                    | NULL     | NULL     | Customer Cancellation    |
  
--- 
### Q1. How many pizzas were ordered?
```TSQL
SELECT COUNT(order_id) AS pizza_count
FROM #customer_orders_temp;
```
| pizza_count  |
|--------------|
| 14           |

---
### Q2. How many pizzas were ordered?
```TSQL
SELECT COUNT(DISTINCT order_id) AS order_count
FROM #customer_orders_temp;
```
| order_count  |
|--------------|
| 10           |

---
### Q3. How many successful orders were delivered by each runner?
```TSQL
SELECT 
    runner_id,
    COUNT(order_id) AS successful_orders
FROM #runner_orders_temp
WHERE cancellation IS NULL
GROUP BY runner_id;
```
| runner_id | successful_orders  |
|-----------|--------------------|
| 1         | 4                  |
| 2         | 3                  |

---
### Q4. How many successful orders were delivered by each runner?
Approach 1: Use subquery.
```TSQL
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
```

Approach 2: Use JOIN.
```TSQL
SELECT 
    p.pizza_name,
    COUNT(*) AS deliver_count
FROM #customer_orders_temp c
    JOIN pizza_names p ON c.pizza_id = p.pizza_id
    JOIN #runner_orders_temp r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY p.pizza_name;
```

| pizza_name | deliver_count  |
|------------|----------------|
| Meatlovers | 9              |
| Vegetarian | 3              |

---
### Q5. How many Vegetarian and Meatlovers were ordered by each customer?
```TSQL
SELECT 
    customer_id,
    SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS Meatlovers,
    SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS Vegetarian
FROM #customer_orders_temp
GROUP BY customer_id;
```
| customer_id | Meatlovers | Vegetarian  |
|-------------|------------|-------------|
| 101         | 2          | 1           |
| 102         | 2          | 1           |
| 103         | 3          | 1           |
| 104         | 3          | 0           |
| 105         | 0          | 1           |

---
### Q6. What was the maximum number of pizzas delivered in a single order?
```TSQL
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
```
| max_number_of_pizza_delivered  |
|------------|
| 3          |

---
### Q7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```TSQL
SELECT 
    c.customer_id,
    SUM(CASE WHEN exclusions != '' OR extras != '' THEN 1 ELSE 0 END) AS has_change,
    SUM(CASE WHEN exclusions = '' AND extras = '' THEN 1 ELSE 0 END) AS no_change
FROM #customer_orders_temp c
    JOIN #runner_orders_temp r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY c.customer_id;
```
| customer_id | has_change | no_change  |
|-------------|------------|------------|
| 101         | 0          | 2          |
| 102         | 0          | 3          |
| 103         | 3          | 0          |
| 104         | 2          | 1          |
| 105         | 1          | 0          |

---
### Q8. How many pizzas were delivered that had both exclusions and extras?
```TSQL
SELECT 
    SUM(CASE WHEN exclusions != '' AND extras != '' THEN 1 ELSE 0 END) AS change_both
FROM #customer_orders_temp c
    JOIN #runner_orders_temp r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL;
```
| change_both  |
|--------------|
| 1            |

---
### Q9. What was the total volume of pizzas ordered for each hour of the day?
```TSQL
SELECT 
    DATEPART(HOUR, order_time) AS hour_of_day,
    COUNT(order_id) AS pizza_volume
FROM #customer_orders_temp
GROUP BY DATEPART(HOUR, order_time)
ORDER BY hour_of_day;
```
| hour_of_day | pizza_volume  |
|-------------|---------------|
| 11          | 1             |
| 13          | 3             |
| 18          | 3             |
| 19          | 1             |
| 21          | 3             |
| 23          | 3             |

---
### Q10. What was the volume of orders for each day of the week?
```TSQL
SELECT 
    DATENAME(weekday, order_time) AS week_day,
    COUNT(order_id) AS order_volume
FROM #customer_orders_temp
GROUP BY DATENAME(weekday, order_time);
```
| week_day  | order_volume  |
|-----------|---------------|
| Friday    | 1             |
| Saturday  | 5             |
| Thursday  | 3             |
| Wednesday | 5             |

---

## B. Runner and Customer Experience
### Q1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```TSQL
SELECT 
    DATEPART(week, registration_date) AS week_period,
    COUNT(*) AS runner_count
FROM runners
GROUP BY DATEPART(week, registration_date);
```
| week_period | runner_count  |
|-------------|---------------|
| 1           | 1             |
| 2           | 2             |
| 3           | 1             |

---
### Q2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```TSQL
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
```
| runner_id | time_pickup_the_order |
|-----------|------------------------|
| 1         | 14                     |
| 2         | 20                     |
| 3         | 10                     |
---
### Q3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```TSQL
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
```
| count_pizza_of_order | time_to_prepare |
|-----------------------|-----------------|
| 1                     | 12              |
| 2                     | 18              |
| 3                     | 30              |

* More pizzas, longer time to prepare. 
* 2 pizzas took 6 minutes more to prepare, 3 pizza took 12 minutes more to prepare.
* On average, it took 6 * (number of pizzas - 1) minutes more to prepare the next pizza.

---
### Q4. What was the average distance travelled for each customer?
```TSQL
SELECT 
    c.customer_id,
    ROUND(AVG(r.distance), 1) as avg_distance
FROM #customer_orders_temp as c 
    JOIN #runner_orders_temp as r 
    ON r.order_id = c.order_id
WHERE r.cancellation is NULL
GROUP BY c.customer_id; 
```
| customer_id | avg_distance |
|-------------|--------------|
| 101         | 20           |
| 102         | 16.7         |
| 103         | 23.4         |
| 104         | 10           |
| 105         | 25           |
---
### Q5. What was the difference between the longest and shortest delivery times for all orders?
```TSQL
SELECT MAX(r.duration) - MIN(r.duration) as time_different
FROM #runner_orders_temp as r;
```
| time_difference|
|----------------|
| 30             |

---
### Q6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```TSQL
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
```
| runner_id | order_id | distance | duration | count_pizza | avg_runner_speed_for_each_delivery |
|-----------|----------|----------|----------|-------------|----------------------------------|
| 1         | 1        | 20       | 32       | 1           | 37.5 km/h                        |
| 1         | 2        | 20       | 27       | 1           | 44.4 km/h                        |
| 1         | 3        | 13.4     | 20       | 2           | 40.2 km/h                        |
| 1         | 10       | 10       | 10       | 2           | 60 km/h                          |
| 2         | 4        | 23.4     | 40       | 3           | 35.1 km/h                        |
| 2         | 7        | 25       | 25       | 1           | 60 km/h                          |
| 2         | 8        | 23.4     | 15       | 1           | 93.6 km/h                        |
| 3         | 5        | 10       | 15       | 1           | 40 km/h                          |

* Runner ```1``` had the average speed from 37.5 km/h to 60 km/h
* Runner ```2``` had the average speed from 35.1 km/h to 93.6 km/h. With the same distance (23.4 km), order ```4``` was delivered at 35.1 km/h, while order ```8``` was delivered at 93.6 km/h. There must be something wrong here!
* Runner ```3``` had the average speed at 40 km/h

---
### Q7. What is the successful delivery percentage for each runner?
```TSQL
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
```
| runner_id | percent_successful_delivery_order |
|-----------|----------------------------------|
| 1         | 100                              |
| 2         | 75                               |
| 3         | 50                               |
---
## C. Ingredient Optimisation
### Data cleaning
**1. Create a new temporary table ```#toppingsBreak``` to separate ```toppings``` into multiple rows**
```TSQL
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
```
  
| pizza_id | topping_id | topping_name  |
|----------|------------|---------------|
| 1        | 1          | Bacon         |
| 1        | 2          | BBQ Sauce     |
| 1        | 3          | Beef          |
| 1        | 4          | Cheese        |
| 1        | 5          | Chicken       |
| 1        | 6          | Mushrooms     |
| 1        | 8          | Pepperoni     |
| 1        | 10         | Salami        |
| 2        | 4          | Cheese        |
| 2        | 6          | Mushrooms     |
| 2        | 7          | Onions        |
| 2        | 9          | Peppers       |
| 2        | 11         | Tomatoes      |
| 2        | 12         | Tomato Sauce  |

**2. Add an identity column ```record_id``` to ```#customer_orders_temp``` to select each ordered pizza more easily**
```TSQL
ALTER TABLE #customer_orders_temp
ADD record_id INT IDENTITY(1,1);

SELECT * FROM #customer_orders_temp;
```
  
| order_id | customer_id | pizza_id | exclusions | extras | order_time              | record_id  |
|----------|-------------|----------|------------|--------|-------------------------|------------|
| 1        | 101         | 1        |            |        | 2020-01-01 18:05:02.000 | 1          |
| 2        | 101         | 1        |            |        | 2020-01-01 19:00:52.000 | 2          |
| 3        | 102         | 1        |            |        | 2020-01-02 23:51:23.000 | 3          |
| 3        | 102         | 2        |            |        | 2020-01-02 23:51:23.000 | 4          |
| 4        | 103         | 1        | 4          |        | 2020-01-04 13:23:46.000 | 5          |
| 4        | 103         | 1        | 4          |        | 2020-01-04 13:23:46.000 | 6          |
| 4        | 103         | 2        | 4          |        | 2020-01-04 13:23:46.000 | 7          |
| 5        | 104         | 1        |            | 1      | 2020-01-08 21:00:29.000 | 8          |
| 6        | 101         | 2        |            |        | 2020-01-08 21:03:13.000 | 9          |
| 7        | 105         | 2        |            | 1      | 2020-01-08 21:20:29.000 | 10         |
| 8        | 102         | 1        |            |        | 2020-01-09 23:54:33.000 | 11         |
| 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10 11:22:59.000 | 12         |
| 10       | 104         | 1        |            |        | 2020-01-11 18:34:49.000 | 13         |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2020-01-11 18:34:49.000 | 14         |
  

**3. Create a new temporary table ```extrasBreak``` to separate ```extras``` into multiple rows**
```TSQL
SELECT 
    c.record_id,
    TRIM(e.value) AS extra_id
INTO #extrasBreak 
FROM #customer_orders_temp c
    CROSS APPLY STRING_SPLIT(extras, ',') AS e;

SELECT * FROM #extrasBreak;
```
  
| record_id | extra_id  |
|-----------|-----------|
| 1         |           |
| 2         |           |
| 3         |           |
| 4         |           |
| 5         |           |
| 6         |           |
| 7         |           |
| 8         | 1         |
| 9         |           |
| 10        | 1         |
| 11        |           |
| 12        | 1         |
| 12        | 5         |
| 13        |           |
| 14        | 1         |
| 14        | 4         |

**4. Create a new temporary table ```exclusionsBreak``` to separate into ```exclusions``` into multiple rows**
```TSQL
SELECT 
    c.record_id,
    TRIM(e.value) AS exclusion_id
INTO #exclusionsBreak 
FROM #customer_orders_temp c
    CROSS APPLY STRING_SPLIT(exclusions, ',') AS e;

SELECT * FROM #exclusionsBreak;
```
  
| record_id | exclusion_id  |
|-----------|---------------|
| 1         |               |
| 2         |               |
| 3         |               |
| 4         |               |
| 5         | 4             |
| 6         | 4             |
| 7         | 4             |
| 8         |               |
| 9         |               |
| 10        |               |
| 11        |               |
| 12        | 4             |
| 13        |               |
| 14        | 2             |
| 14        | 6             |

---
### Q1. What are the standard ingredients for each pizza?
```TSQL
SELECT p.pizza_name, STRING_AGG(tp.topping_name, ', ') as topping_name
FROM pizza_names as p
JOIN #toppingsBreak as tp on p.pizza_id = tp.pizza_id
GROUP BY p.pizza_name
```
  
| pizza_name  | topping_name                                        |
|-------------|-----------------------------------------------------|
| Meatlovers  | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian  | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |

---
### Q2. What was the most commonly added extra?
```TSQL
SELECT p.topping_id, p.topping_name, COUNT(*) as most_add_extra
FROM #extrasBreak as e
JOIN pizza_toppings as p on e.extra_id = p.topping_id
GROUP BY p.topping_id, p.topping_name
```
  
| topping_id | topping_name | most_add_extra |
|------------|--------------|----------------|
| 1          | Bacon        | 4              |
| 4          | Cheese       | 1              |
| 5          | Chicken      | 1              |

The most commonly added extra was Bacon.

---
### Q3. What was the most common exclusion?
```TSQL
SELECT p.topping_id, p.topping_name, COUNT(*) as most_remove_exclusion
FROM #exclusionsBreak as e
JOIN pizza_toppings as p on e.exclusion_id = p.topping_id
GROUP BY p.topping_id, p.topping_name;
```
  
| topping_id | topping_name | most_remove_exclusion |
|------------|--------------|------------------------|
| 2          | BBQ Sauce    | 1                      |
| 4          | Cheese       | 4                      |
| 6          | Mushrooms    | 1                      |

The most common exclusion was Cheese.

---
### Q4.Generate an order item for each record in the ```customers_orders``` table in the format of one of the following
* ```Meat Lovers```
* ```Meat Lovers - Exclude Beef```
* ```Meat Lovers - Extra Bacon```
* ```Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers```

To solve this question:
* Create 3 CTEs: ```extras_cte```, ```exclusions_cte```, and ```union_cte``` combining two tables
* Use the ```union_cte``` to LEFT JOIN with the ```customer_orders_temp``` and JOIN with the ```pizza_name```
* Use the ```CONCAT_WS``` with ```STRING_AGG``` to get the result

```TSQL
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
```

**Table ```cteExtra```**
| record_id | record_options        |
|-----------|-----------------------|
| 8         | Extra Bacon           |
| 10        | Extra Bacon           |
| 12        | Extra Bacon, Chicken  |
| 14        | Extra Bacon, Cheese   |

**Table ```cteExclusion```**
| record_id | record_options                 |
|-----------|--------------------------------|
| 5         | Exclusion Cheese               |
| 6         | Exclusion Cheese               |
| 7         | Exclusion Cheese               |
| 12        | Exclusion Cheese               |
| 14        | Exclusion BBQ Sauce, Mushrooms |

**Table ```cteUnion```**
| record_id | record_options                  |
|-----------|---------------------------------|
| 5         | Exclusion Cheese                |
| 6         | Exclusion Cheese                |
| 7         | Exclusion Cheese                |
| 8         | Extra Bacon                     |
| 10        | Extra Bacon                     |
| 12        | Exclusion Cheese                |
| 12        | Extra Bacon, Chicken            |
| 14        | Exclusion BBQ Sauce, Mushrooms  |
| 14        | Extra Bacon, Cheese             |

**Result**
  
| record_id | order_id | customer_id | pizza_id | order_time              | pizza_info                                                        |
|-----------|----------|-------------|----------|-------------------------|-------------------------------------------------------------------|
| 1         | 1        | 101         | 1        | 2020-01-01 18:05:02.000 | Meatlovers                                                        |
| 2         | 2        | 101         | 1        | 2020-01-01 19:00:52.000 | Meatlovers                                                        |
| 3         | 3        | 102         | 1        | 2020-01-02 23:51:23.000 | Meatlovers                                                        |
| 4         | 3        | 102         | 2        | 2020-01-02 23:51:23.000 | Vegetarian                                                        |
| 5         | 4        | 103         | 1        | 2020-01-04 13:23:46.000 | Meatlovers - Exclusion Cheese                                     |
| 6         | 4        | 103         | 1        | 2020-01-04 13:23:46.000 | Meatlovers - Exclusion Cheese                                     |
| 7         | 4        | 103         | 2        | 2020-01-04 13:23:46.000 | Vegetarian - Exclusion Cheese                                     |
| 8         | 5        | 104         | 1        | 2020-01-08 21:00:29.000 | Meatlovers - Extra Bacon                                          |
| 9         | 6        | 101         | 2        | 2020-01-08 21:03:13.000 | Vegetarian                                                        |
| 10        | 7        | 105         | 2        | 2020-01-08 21:20:29.000 | Vegetarian - Extra Bacon                                          |
| 11        | 8        | 102         | 1        | 2020-01-09 23:54:33.000 | Meatlovers                                                        |
| 12        | 9        | 103         | 1        | 2020-01-10 11:22:59.000 | Meatlovers - Exclusion Cheese - Extra Bacon, Chicken              |
| 13        | 10       | 104         | 1        | 2020-01-11 18:34:49.000 | Meatlovers                                                        |
| 14        | 10       | 104         | 1        | 2020-01-11 18:34:49.000 | Meatlovers - Exclusion BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

---
## D. Pricing and Ratings
### Q1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

```TSQL
SELECT 
    SUM(CASE WHEN p.pizza_name = 'Meatlovers' THEN 12
        ELSE 10 END) AS money_earned
FROM #customer_orders_temp as c
    JOIN pizza_names as p on c.pizza_id = p.pizza_id
    JOIN #runner_orders_temp as r on c.order_id = r.order_id
WHERE r.cancellation is NULL
```
| money_earned  |
|---------------|
| 138           |

---
### Q2. What if there was an additional $1 charge for any pizza extras?
* Add cheese is $1 extra
```TSQL
DECLARE @basecost INT
SET @basecost = 138 	-- @basecost = result of the previous question

SELECT 
  @basecost + SUM(CASE WHEN p.topping_name = 'Cheese' THEN 2 ELSE 1 END) updated_money
FROM #extrasBreak e
    JOIN pizza_toppings p ON e.extra_id = p.topping_id;
```
| updated_money  |
|----------------|
| 145            |

---
### Q3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```TSQL
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
 ```
| order_id | rating  |
|----------|---------|
| 1        | 3       |
| 2        | 5       |
| 3        | 3       |
| 4        | 1       |
| 5        | 5       |
| 7        | 3       |
| 8        | 4       |
| 10       | 3       |

---
### Q4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
* ```customer_id```
* ```order_id```
* ```runner_id```
* ```rating```
* ```order_time```
* ```pickup_time```
* Time between order and pickup
* Delivery duration
* Average speed
* Total number of pizzas

```TSQL
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
  ```
| customer_id | order_id | runner_id | rating | order_time                | pickup_time               | time_to_delivery | delivery_duration | average_speed | total_number_of_pizzas |
|-------------|----------|-----------|--------|---------------------------|---------------------------|-------------------|---------------------|---------------|------------------------|
| 101         | 1        | 1         | 3      | 2020-01-01 18:05:02.000   | 2020-01-01 18:15:34.000   | 10                | 32                  | 37.5          | 1                      |
| 101         | 2        | 1         | 5      | 2020-01-01 19:00:52.000   | 2020-01-01 19:10:54.000   | 10                | 27                  | 44.4          | 1                      |
| 102         | 3        | 1         | 3      | 2020-01-02 23:51:23.000   | 2020-01-03 00:12:37.000   | 21                | 20                  | 40.2          | 2                      |
| 103         | 4        | 2         | 1      | 2020-01-04 13:23:46.000   | 2020-01-04 13:53:03.000   | 30                | 40                  | 35.1          | 3                      |
| 104         | 5        | 3         | 5      | 2020-01-08 21:00:29.000   | 2020-01-08 21:10:57.000   | 10                | 15                  | 40            | 1                      |
| 105         | 7        | 2         | 3      | 2020-01-08 21:20:29.000   | 2020-01-08 21:30:45.000   | 10                | 25                  | 60            | 1                      |
| 102         | 8        | 2         | 4      | 2020-01-09 23:54:33.000   | 2020-01-10 00:15:02.000   | 21                | 15                  | 93.6          | 1                      |

---
### Q5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```TSQL
DECLARE @basecost INT
SET @basecost = 138

SELECT 
  @basecost AS revenue,
  SUM(distance)*0.3 AS runner_paid,
  @basecost - SUM(distance)*0.3 AS money_left
FROM #runner_orders_temp;
```
| revenue | runner_paid | money_left  |
|---------|-------------|-------------|
| 138     | 43.56       | 94.44       |

---
