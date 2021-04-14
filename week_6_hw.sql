--Show all customers whose last names start with T. Order them by first name from A-Z. 

/*Choose all the columns from all of the records within the customer table where the last_name column contains the starting letter T followed by the wildcard %. This chooses all last names that start with T.  Then the records are ordered alphabetically by first name in the first_name column*/

SELECT *
FROM customer
WHERE last_name LIKE 'T%'
ORDER BY first_name


--Show all rentals returned from 5/28/2005 to 6/1/2005 

/*Choose all return dates between 5/28/2005 and 6/1/2005, making sure to correctly format the date */

SELECT *
FROM rental
WHERE return_date 
BETWEEN '2005-05-28' AND '2005-06-01';

--How would you determine which movies are rented the most? 
/* I would figure out the number of times each film is rented from the rental table using inventory id, then join that to the inventory table to retrieve the film id for each movie.  I would then use the film id joined to the film table to retrieve the title. Count is performed to figure out how many times a movie has been rented.*/

SELECT title, COUNT(*)
FROM inventory
INNER JOIN rental
USING (inventory_id)
INNER JOIN film
USING (film_id)
GROUP BY title
ORDER BY count DESC

--Show how much each customer spent on movies (for all time) . Order them from least to most. 

/*Adding up all amounts for each customer id.*/

SELECT customer_id, SUM(amount) AS sum_amount
FROM payment
GROUP BY customer_id
ORDER BY sum_amount

--Which actor was in the most movies in 2006 (based on this dataset)? Be sure to alias the actor name and count as a more descriptive name. Order the results from most to least. 

SELECT last_name AS actor_last_name, first_name AS actor_first_name, COUNT(*) AS number_of_movie_roles
FROM film_actor
INNER JOIN actor
USING (actor_id)
INNER JOIN film
USING (film_id)
WHERE release_year = 2006
GROUP BY actor_last_name, actor_first_name
ORDER BY number_of_movie_roles DESC

--Write an explain plan for 4 and 5. Show the queries and explain what is happening in each one. Use the following link to understand how this works http://postgresguide.com/performance/explain.html  
/*#4*/
EXPLAIN SELECT customer_id, SUM(amount) AS sum_amount
FROM payment
GROUP BY customer_id
ORDER BY sum_amount
/*result*/
"Sort  (cost=383.25..384.75 rows=599 width=34) (actual time=9.373..9.408 rows=599 loops=1)"
"  Sort Key: (sum(amount))"
"  Sort Method: quicksort  Memory: 53kB"
"  ->  HashAggregate  (cost=348.13..355.62 rows=599 width=34) (actual time=8.502..8.892 rows=599 loops=1)"
"        Group Key: customer_id"
"        Batches: 1  Memory Usage: 297kB"
"        ->  Seq Scan on payment  (cost=0.00..270.42 rows=15542 width=8) (actual time=0.056..1.779 rows=14596 loops=1)"
"Planning Time: 0.110 ms"
"Execution Time: 26.958 ms"
/* This explain shows the estimated cost associated both setting up the run and including it (first number and second) as well as estimated rows returned. Then it shows the actual costs and rows.*/
/*5/
"Sort  (cost=271.63..271.95 rows=128 width=21) (actual time=8.186..8.201 rows=199 loops=1)"
"  Sort Key: (count(*)) DESC"
"  Sort Method: quicksort  Memory: 40kB"
"  ->  HashAggregate  (cost=265.87..267.15 rows=128 width=21) (actual time=8.055..8.107 rows=199 loops=1)"
"        Group Key: actor.last_name, actor.first_name"
"        Batches: 1  Memory Usage: 64kB"
"        ->  Hash Join  (cost=85.50..218.08 rows=6372 width=13) (actual time=0.607..5.495 rows=5462 loops=1)"
"              Hash Cond: (film_actor.film_id = film.film_id)"
"              ->  Hash Join  (cost=6.50..122.30 rows=6372 width=15) (actual time=0.154..3.216 rows=5462 loops=1)"
"                    Hash Cond: (film_actor.actor_id = actor.actor_id)"
"                    ->  Seq Scan on film_actor  (cost=0.00..98.72 rows=6372 width=4) (actual time=0.034..0.673 rows=5462 loops=1)"
"                    ->  Hash  (cost=4.00..4.00 rows=200 width=17) (actual time=0.109..0.110 rows=200 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 18kB"
"                          ->  Seq Scan on actor  (cost=0.00..4.00 rows=200 width=17) (actual time=0.009..0.051 rows=200 loops=1)"
"              ->  Hash  (cost=66.50..66.50 rows=1000 width=4) (actual time=0.444..0.445 rows=1000 loops=1)"
"                    Buckets: 1024  Batches: 1  Memory Usage: 44kB"
"                    ->  Seq Scan on film  (cost=0.00..66.50 rows=1000 width=4) (actual time=0.009..0.294 rows=1000 loops=1)"
"                          Filter: ((release_year)::integer = 2006)"
"Planning Time: 0.574 ms"
"Execution Time: 8.333 ms"
/* This explain shows the same estimated and actual types of costs as the explain above. One difference in the size of output can be attributed to all of the joins that are being run through.*/

--What is the average rental rate per genre? 
/* I had to join the tables for film_category, category, and film.  This was so that I could match the category types to their category id and the film id to the rental rate. I performed an average function on the rental rate to get the ultimate answer.*/
SELECT film_category.category_id, COUNT(film_category.film_id), category.name, AVG(film.rental_rate):: NUMERIC(4,2)
FROM film_category
FULL JOIN category 
USING (category_id)
FULL JOIN film
USING (film_id)
GROUP BY film_category.category_id, category.name 

--How many films were returned late? Early? On time? 
/* "early"	7738
"late"	6403
"on_time"	1904*/
SELECT CASE WHEN rental_duration > date_part('day', return_date - rental_date) THEN 'early'
	WHEN rental_duration < date_part('day', return_date - rental_date) THEN 'late'
	ELSE 'on_time' END AS status_of_return,
	COUNT (*) AS total_no_of_films
	FROM film
	INNER JOIN inventory
	USING (film_id)
	FULL JOIN rental
	USING (inventory_id)
	GROUP BY 1
	ORDER BY 2 DESC;

--What categories are the most rented and what are their total sales? 
/* The highest entry amounts were under Sports with total sales of 231.26*/
SELECT film_category.category_id, COUNT(film_category.film_id), category.name, SUM(film.rental_rate) AS total_sales
FROM film_category
FULL JOIN category 
USING (category_id)
FULL JOIN film
USING (film_id)
GROUP BY film_category.category_id, category.name 
ORDER BY total_sales DESC

--Create a view for 8 and a view for 9. Be sure to name them appropriately.  
/*8*/
CREATE VIEW return_status AS
SELECT CASE WHEN rental_duration > date_part('day', return_date - rental_date) THEN 'early'
	WHEN rental_duration < date_part('day', return_date - rental_date) THEN 'late'
	ELSE 'on_time' END AS status_of_return,
	COUNT (*) AS total_no_of_films
	FROM film
	INNER JOIN inventory
	USING (film_id)
	FULL JOIN rental
	USING (inventory_id)
	GROUP BY 1
	ORDER BY 2 DESC;
/*9*/
CREATE VIEW most_rented AS
SELECT film_category.category_id, COUNT(film_category.film_id), category.name, SUM(film.rental_rate) AS total_sales
FROM film_category
FULL JOIN category 
USING (category_id)
FULL JOIN film
USING (film_id)
GROUP BY film_category.category_id, category.name 
ORDER BY total_sales DESC
Bonus: 

--Write a query that shows how many films were rented each month. Group them by category and month.  

SELECT COUNT(film_category.category_id), COUNT(film_category.film_id), category.name, COUNT(inventory.inventory_id), COUNT(rental.inventory_id), date_part('month', rental.rental_date) AS month_rented
FROM film_category
FULL JOIN category 
ON category.category_id=film_category.category_id 
FULL JOIN film
ON film.film_id=film_category.category_id
FULL JOIN inventory
ON inventory.film_id=film_category.film_id
FULL JOIN rental
ON rental.inventory_id=inventory.inventory_id
GROUP BY category.name,  month_rented
ORDER BY month_rented DESC