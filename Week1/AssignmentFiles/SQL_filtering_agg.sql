-- ==================================
-- FILTERS & AGGREGATION
-- ==================================

USE coffeeshop_db;


-- Q1) Compute total items per order.
--     Return (order_id, total_items) from order_items.
select order_id, sum(quantity) AS total_items
from order_items
group by  order_id;
-- Q2) Compute total items per order for PAID orders only.
--     Return (order_id, total_items). Hint: order_id IN (SELECT ... FROM orders WHERE status='paid').
select oi.order_id, sum(quantity) AS total_items
from order_items oi
join orders o on oi.order_id=o.order_id
where status='paid'
group by  oi.order_id;
-- Q3) How many orders were placed per day (all statuses)?
--     Return (order_date, orders_count) from orders.
select  date(order_datetime) as order_date, sum(quantity) AS total_items
from order_items oi
join orders o on oi.order_id=o.order_id
group by  date(order_datetime);
-- Q4) What is the average number of items per PAID order?
--     Use a subquery or CTE over order_items filtered by order_id IN (...).
with paid_orders as (
    select order_id, count(*) AS items
   from order_items oi
    WHERE order_id in (select order_id from orders where status = 'paid')
    group by order_id
)
select order_id, avg(items) AS avg_items_per_order
FROM paid_orders
group by order_id;
-- Q5) Which products (by product_id) have sold the most units overall across all stores?
--     Return (product_id, total_units), sorted desc.
select product_id, sum(quantity) AS total_units
from order_items oi
    join orders o on oi.order_id=o.order_id
    join stores s on s.store_id= o.store_id
group by 
    product_id
order by total_units desc;
-- Q6) Among PAID orders only, which product_ids have the most units sold?
--     Return (product_id, total_units_paid), sorted desc.
--     Hint: order_id IN (SELECT order_id FROM orders WHERE status='paid').
select oi.product_id, sum(quantity) as total_units_paid
from orders o
join order_items oi on oi.order_id=o.order_id
where status = 'paid' and oi.order_id in (select o.order_id from orders o where status='paid')
group by product_id
order by total_units_paid desc;
-- Q7) For each store, how many UNIQUE customers have placed a PAID order?
--     Return (store_id, unique_customers) using only the orders table.
select store_id, count(distinct customer_id) AS unique_customers
from orders
where status = 'paid' 
group by store_id;
-- Q8) Which day of week has the highest number of PAID orders?
--     Return (day_name, orders_count). Hint: DAYNAME(order_datetime). Return ties if any.
select dayname(order_datetime) as day_name, count(order_id) AS count
from orders
where status='paid'
group by dayname(order_datetime),weekday(order_datetime) 
order by count desc;


-- Q9) Show the calendar days whose total orders (any status) exceed 3.
--     Use HAVING. Return (order_date, orders_count).
select cast(order_datetime as date) order_date, count(order_id) as orders_count
from orders
group by cast(order_datetime as date)
having count(order_id) > 3;
-- Q10) Per store, list payment_method and the number of PAID orders.
--      Return (store_id, payment_method, paid_orders_count).
select store_id, payment_method, count(*) as paid_orders_count
from orders
where status = 'paid'
group by store_id, payment_method;

-- Q11) Among PAID orders, what percent used 'app' as the payment_method?
--      Return a single row with pct_app_paid_orders (0–100).
select (count(case when payment_method = 'app' then 1 end) *100.0) /count(*) as pct_app_paid_orders
from orders
where status = 'paid';
-- Q12) Busiest hour: for PAID orders, show (hour_of_day, orders_count) sorted desc.
select hour(order_datetime) as hour_of_day,count(*) as orders_count
from orders
where status = 'paid'
group by hour(order_datetime)
order by orders_count desc;

-- ================
