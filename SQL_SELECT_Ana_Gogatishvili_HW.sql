/*********************************************************************************
 * PART 1, TASK 1: Animation Movies (2017-2019)
 *********************************************************************************/

-- TASK: The marketing team needs a list of animation movies between 2017 and 2019 to promote
-- family-friendly content in an upcoming season in stores. Show all animation movies released
-- during this period with rate more than 1, sorted alphabetically.

-- BUSINESS LOGIC:
-- 1. Filters: category.name = 'Animation', film.release_year BETWEEN 2017 AND 2019, film.rental_rate > 1.00.
-- 2. Join Path: film -> film_category -> category.

---------------------------------------------------------------------------------
-- Solution 1.1: INNER JOIN
---------------------------------------------------------------------------------
SELECT
    f.title,
    f.release_year,
    f.rental_rate
FROM
    public.film AS f
INNER JOIN
    public.film_category AS fc ON f.film_id = fc.film_id
INNER JOIN
    public.category AS c ON fc.category_id = c.category_id
WHERE
    c.name = 'Animation'
    AND f.release_year BETWEEN 2017 AND 2019
    AND f.rental_rate > 1.00
ORDER BY
    f.title ASC;

-- PROS: Standard SQL, high performance due to efficient optimizer planning.
-- CONS: Requires joining three tables, which could become complex for larger queries.

---------------------------------------------------------------------------------
-- Solution 1.2: Subquery (in WHERE clause using IN)
---------------------------------------------------------------------------------
SELECT
    f.title,
    f.release_year,
    f.rental_rate
FROM
    public.film AS f
INNER JOIN
    public.film_category AS fc ON f.film_id = fc.film_id
WHERE
    fc.category_id IN (
        SELECT category_id FROM public.category WHERE name = 'Animation'
    )
    AND f.release_year BETWEEN 2017 AND 2019
    AND f.rental_rate > 1.00
ORDER BY
    f.title ASC;

-- PROS: Avoids explicitly joining the 'category' table, making the main query slightly cleaner.
-- CONS: The subquery can sometimes be less efficient than a direct INNER JOIN depending on the database's execution plan.

---------------------------------------------------------------------------------
-- Solution 1.3: CTE (Common Table Expression)
---------------------------------------------------------------------------------
WITH AnimationFilter AS (
    SELECT category_id
    FROM public.category
    WHERE name = 'Animation'
)
SELECT
    f.title,
    f.release_year,
    f.rental_rate
FROM
    public.film AS f
INNER JOIN
    public.film_category AS fc ON f.film_id = fc.film_id
INNER JOIN
    AnimationFilter AS af ON fc.category_id = af.category_id
WHERE
    f.release_year BETWEEN 2017 AND 2019
    AND f.rental_rate > 1.00
ORDER BY
    f.title ASC;

-- PROS: Excellent readability; the initial filtering step is named clearly.
-- CONS: More verbose for a simple filter, slightly increased overhead due to CTE materialization (if the optimizer doesn't simplify it).




/*********************************************************************************
 * PART 1, TASK 2: Store Revenue (After March 2017)
 *********************************************************************************/

-- TASK: Calculate the revenue earned by each rental store after March 2017 (since April)
-- (include columns: address and address2 – as one column, revenue)

-- BUSINESS LOGIC:
-- 1. Revenue: SUM(payment.amount). 2. Time Filter: payment.payment_date > '2017-03-31'.
-- 3. Join Path: payment -> rental -> inventory -> store -> address.
-- 4. Concatenation: address.address || ' ' || address.address2.

---------------------------------------------------------------------------------
-- Solution 2.1: INNER JOIN
---------------------------------------------------------------------------------
SELECT
    a.address || ' ' || a.address2 AS store_location,
    SUM(p.amount) AS total_revenue
FROM
    public.payment AS p
INNER JOIN
    public.rental AS r ON p.rental_id = r.rental_id
INNER JOIN
    public.inventory AS i ON r.inventory_id = i.inventory_id
INNER JOIN
    public.store AS s ON i.store_id = s.store_id
INNER JOIN
    public.address AS a ON s.address_id = a.address_id
WHERE
    p.payment_date > '2017-03-31'
GROUP BY
    a.address, a.address2
ORDER BY
    total_revenue DESC;

-- PROS: Standard, efficient, and direct linking of all tables.
-- CONS: Complex join path (5 joins) which can be intimidating for beginners.

---------------------------------------------------------------------------------
-- Solution 2.2: Subquery (in FROM clause)
---------------------------------------------------------------------------------
SELECT
    a.address || ' ' || a.address2 AS store_location,
    SUM(store_payments.amount) AS total_revenue
FROM
    public.address AS a
INNER JOIN
    public.store AS s ON a.address_id = s.address_id
INNER JOIN
    (
        -- Subquery calculates all payments for the period and links them back to store_id
        SELECT
            p.amount,
            i.store_id
        FROM
            public.payment AS p
        INNER JOIN
            public.rental AS r ON p.rental_id = r.rental_id
        INNER JOIN
            public.inventory AS i ON r.inventory_id = i.inventory_id
        WHERE
            p.payment_date > '2017-03-31'
    ) AS store_payments ON s.store_id = store_payments.store_id
GROUP BY
    a.address, a.address2
ORDER BY
    total_revenue DESC;

-- PROS: Separates logic; the inner subquery handles the complex payment-to-store linkage.
-- CONS: Subquery can be less readable and may force a full materialization of the inner result set.

---------------------------------------------------------------------------------
-- Solution 2.3: CTE (Common Table Expression)
---------------------------------------------------------------------------------
WITH StorePayments AS (
    -- Step 1: Aggregate all payments and link them to the store_id
    SELECT
        i.store_id,
        SUM(p.amount) AS revenue
    FROM
        public.payment AS p
    INNER JOIN
        public.rental AS r ON p.rental_id = r.rental_id
    INNER JOIN
        public.inventory AS i ON r.inventory_id = i.inventory_id
    WHERE
        p.payment_date > '2017-03-31'
    GROUP BY
        i.store_id
)
SELECT
    a.address || ' ' || a.address2 AS store_location,
    sp.revenue AS total_revenue
FROM
    StorePayments AS sp
INNER JOIN
    public.store AS s ON sp.store_id = s.store_id
INNER JOIN
    public.address AS a ON s.address_id = a.address_id
ORDER BY
    total_revenue DESC;

-- PROS: Best readability. The CTE clearly defines the revenue calculation before linking to the final address details.
-- CONS: More verbose than the direct JOIN.






/*********************************************************************************
 * PART 1, TASK 3: Top-5 Actors (Released after 2015)
 *********************************************************************************/

-- TASK: Show top-5 actors by number of movies (released after 2015) they took part in
-- (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order).

-- BUSINESS LOGIC:
-- 1. Filter: film.release_year > 2015.
-- 2. Aggregate: COUNT(film.film_id).
-- 3. Join Path: actor -> film_actor -> film.
-- 4. Limit: 5.

---------------------------------------------------------------------------------
-- Solution 3.1: INNER JOIN
---------------------------------------------------------------------------------
SELECT
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS number_of_movies
FROM
    public.actor AS a
INNER JOIN
    public.film_actor AS fa ON a.actor_id = fa.actor_id
INNER JOIN
    public.film AS f ON fa.film_id = f.film_id
WHERE
    f.release_year > 2015
GROUP BY
    a.first_name, a.last_name
ORDER BY
    number_of_movies DESC
LIMIT 5;

-- PROS: Simple, direct, and fast way to aggregate data across tables.
-- CONS: None significant; this is the most optimal approach.

---------------------------------------------------------------------------------
-- Solution 3.2: Subquery (in WHERE clause using IN)
---------------------------------------------------------------------------------
SELECT
    a.first_name,
    a.last_name,
    COUNT(fa.film_id) AS number_of_movies
FROM
    public.actor AS a
INNER JOIN
    public.film_actor AS fa ON a.actor_id = fa.actor_id
WHERE
    fa.film_id IN (
        -- Subquery finds IDs of all films released after 2015
        SELECT film_id FROM public.film WHERE release_year > 2015
    )
GROUP BY
    a.first_name, a.last_name
ORDER BY
    number_of_movies DESC
LIMIT 5;

-- PROS: Separates the year filtering logic.
-- CONS: Subqueries using IN with large lists can be slower than a direct JOIN, especially if the optimizer doesn't convert it.

---------------------------------------------------------------------------------
-- Solution 3.3: CTE (Common Table Expression)
---------------------------------------------------------------------------------
WITH RecentFilms AS (
    SELECT film_id
    FROM public.film
    WHERE release_year > 2015
)
SELECT
    a.first_name,
    a.last_name,
    COUNT(rf.film_id) AS number_of_movies
FROM
    public.actor AS a
INNER JOIN
    public.film_actor AS fa ON a.actor_id = fa.actor_id
INNER JOIN
    RecentFilms AS rf ON fa.film_id = rf.film_id
GROUP BY
    a.first_name, a.last_name
ORDER BY
    number_of_movies DESC
LIMIT 5;

-- PROS: High readability; clearly defines the set of films being analyzed first.
-- CONS: Overly verbose for a simple filter compared to the direct JOIN.










/*********************************************************************************
 * PART 1, TASK 4: Genre Production Trends (Drama, Travel, Documentary)
 *********************************************************************************/

-- TASK: Show number of Drama, Travel, Documentary per year (include columns: release_year,
-- number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies),
-- sorted by release year in descending order. Dealing with NULL values is encouraged.

-- BUSINESS LOGIC:
-- 1. PIVOT: Use conditional aggregation (COUNT with CASE WHEN) to pivot genres into columns.
-- 2. Join Path: film -> film_category -> category.
-- 3. Grouping: release_year.

---------------------------------------------------------------------------------
-- Solution 4.1: INNER JOIN (Conditional Aggregation)
---------------------------------------------------------------------------------
SELECT
    f.release_year,
    -- COUNT(*) only counts non-NULL values, so if the CASE returns NULL (ELSE), it won't be counted.
    COUNT(CASE WHEN c.name = 'Drama' THEN f.film_id END) AS number_of_drama_movies,
    COUNT(CASE WHEN c.name = 'Travel' THEN f.film_id END) AS number_of_travel_movies,
    COUNT(CASE WHEN c.name = 'Documentary' THEN f.film_id END) AS number_of_documentary_movies
FROM
    public.film AS f
INNER JOIN
    public.film_category AS fc ON f.film_id = fc.film_id
INNER JOIN
    public.category AS c ON fc.category_id = c.category_id
WHERE
    c.name IN ('Drama', 'Travel', 'Documentary') -- Optional optimization: Filter categories early
GROUP BY
    f.release_year
ORDER BY
    f.release_year DESC;

-- PROS: Efficient, standard SQL pivot technique. Returns 0 instead of NULL for missing years/genres when INNER JOIN is used.
-- CONS: Requires understanding of conditional aggregation (COUNT/SUM with CASE).

---------------------------------------------------------------------------------
-- Solution 4.2: Subquery (Pivot logic using Self-Joins/Multiple Subqueries - **AVOIDED**)
---------------------------------------------------------------------------------
-- Note: A subquery solution for pivoting is overly complex and highly inefficient (requiring 3 subqueries
-- or multiple self-joins) compared to conditional aggregation. We use a Subquery to filter categories first.
SELECT
    f.release_year,
    COUNT(CASE WHEN category_id = (SELECT category_id FROM public.category WHERE name = 'Drama') THEN 1 END) AS number_of_drama_movies,
    COUNT(CASE WHEN category_id = (SELECT category_id FROM public.category WHERE name = 'Travel') THEN 1 END) AS number_of_travel_movies,
    COUNT(CASE WHEN category_id = (SELECT category_id FROM public.category WHERE name = 'Documentary') THEN 1 END) AS number_of_documentary_movies
FROM
    public.film AS f
INNER JOIN
    public.film_category AS fc ON f.film_id = fc.film_id
GROUP BY
    f.release_year
ORDER BY
    f.release_year DESC;

-- PROS: Does not require joining the 'category' table; category IDs are resolved once by non-correlated subqueries.
-- CONS: If the category list grows, the query becomes unmanageable; subqueries are less readable than direct JOIN.

---------------------------------------------------------------------------------
-- Solution 4.3: CTE (Grouping logic into a CTE)
---------------------------------------------------------------------------------
WITH FilmGenre AS (
    SELECT
        f.release_year,
        c.name AS genre_name
    FROM
        public.film AS f
    INNER JOIN
        public.film_category AS fc ON f.film_id = fc.film_id
    INNER JOIN
        public.category AS c ON fc.category_id = c.category_id
)
SELECT
    fg.release_year,
    COUNT(CASE WHEN fg.genre_name = 'Drama' THEN 1 END) AS number_of_drama_movies,
    COUNT(CASE WHEN fg.genre_name = 'Travel' THEN 1 END) AS number_of_travel_movies,
    COUNT(CASE WHEN fg.genre_name = 'Documentary' THEN 1 END) AS number_of_documentary_movies
FROM
    FilmGenre AS fg
WHERE
    fg.genre_name IN ('Drama', 'Travel', 'Documentary')
GROUP BY
    fg.release_year
ORDER BY
    fg.release_year DESC;

-- PROS: Best separation of concerns: The CTE handles the data linkage (film-to-genre), and the main SELECT handles the pivoting and aggregation.
-- CONS: Verbose for simple pivoting.

part 2

/*********************************************************************************
 * PART 2, TASK 1: Top 3 Revenue-Generating Employees in 2017
 *********************************************************************************/

-- TASK: Show which three employees generated the most revenue in 2017?
-- Assumptions: staff processed payment then works in the same store; take into account only payment_date;
-- staff could work in several stores (use the last one: staff.store_id).

-- BUSINESS LOGIC:
-- 1. Revenue: SUM(payment.amount). 2. Filter: payment.payment_date BETWEEN '2017-01-01' AND '2017-12-31'.
-- 3. Store Address: Link staff -> store -> address.
-- 4. Grouping: staff_id, first_name, last_name, and the final store address.
-- 5. Limit: 3.

---------------------------------------------------------------------------------
-- Solution 1.1: INNER JOIN
---------------------------------------------------------------------------------
SELECT
    s.first_name,
    s.last_name,
    a.address || ' ' || a.address2 AS last_store_location,
    SUM(p.amount) AS total_revenue
FROM
    public.staff AS s
INNER JOIN
    public.payment AS p ON s.staff_id = p.staff_id
INNER JOIN
    public.store AS st ON s.store_id = st.store_id -- staff.store_id is used for last store as per assumption
INNER JOIN
    public.address AS a ON st.address_id = a.address_id
WHERE
    EXTRACT(YEAR FROM p.payment_date) = 2017
GROUP BY
    s.staff_id, s.first_name, s.last_name, a.address, a.address2
ORDER BY
    total_revenue DESC
LIMIT 3;

-- PROS: Direct and efficient joining; correctly captures the store location using the staff.store_id as the "last" store.
-- CONS: Multi-column grouping and ordering makes the code verbose.

---------------------------------------------------------------------------------
-- Solution 2.1: Subquery (in FROM clause)
---------------------------------------------------------------------------------
SELECT
    s.first_name,
    s.last_name,
    a.address || ' ' || a.address2 AS last_store_location,
    revenue_2017.total_revenue
FROM
    public.staff AS s
INNER JOIN
    public.store AS st ON s.store_id = st.store_id
INNER JOIN
    public.address AS a ON st.address_id = a.address_id
INNER JOIN
    (
        -- Subquery: Calculates total revenue per staff member in 2017
        SELECT
            staff_id,
            SUM(amount) AS total_revenue
        FROM
            public.payment
        WHERE
            EXTRACT(YEAR FROM payment_date) = 2017
        GROUP BY
            staff_id
    ) AS revenue_2017 ON s.staff_id = revenue_2017.staff_id
ORDER BY
    revenue_2017.total_revenue DESC
LIMIT 3;

-- PROS: Clear separation of concerns; revenue aggregation is isolated from store details.
-- CONS: Database may process the inner subquery first, which can be an unnecessary step compared to a direct join and group.

---------------------------------------------------------------------------------
-- Solution 3.1: CTE (Common Table Expression)
---------------------------------------------------------------------------------
WITH StaffRevenue2017 AS (
    -- Step 1: Calculate total revenue per employee for 2017
    SELECT
        staff_id,
        SUM(amount) AS total_revenue
    FROM
        public.payment
    WHERE
        EXTRACT(YEAR FROM payment_date) = 2017
    GROUP BY
        staff_id
)
SELECT
    s.first_name,
    s.last_name,
    a.address || ' ' || a.address2 AS last_store_location,
    sr.total_revenue
FROM
    StaffRevenue2017 AS sr
INNER JOIN
    public.staff AS s ON sr.staff_id = s.staff_id
INNER JOIN
    public.store AS st ON s.store_id = st.store_id
INNER JOIN
    public.address AS a ON st.address_id = a.address_id
ORDER BY
    sr.total_revenue DESC
LIMIT 3;

-- PROS: Excellent readability; the CTE clearly names the revenue calculation.
-- CONS: More verbose than necessary; performance is usually equivalent to the Subquery solution.

/*********************************************************************************
 * PART 2, TASK 2: Top 5 Movies and Audience Age
 *********************************************************************************/

-- TASK: Show which 5 movies were rented more than others (number of rentals), and what's the expected
-- age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system'.

-- BUSINESS LOGIC:
-- 1. Popularity: COUNT(rental.rental_id). 2. Limit: 5.
-- 3. Age Mapping: Use CASE statement on film.rating (G, PG, PG-13, R, NC-17).
-- 4. Join Path: film -> inventory -> rental.

---------------------------------------------------------------------------------
-- Solution 2.1: INNER JOIN (with CASE)
---------------------------------------------------------------------------------
SELECT
    f.title,
    COUNT(r.rental_id) AS number_of_rentals,
    CASE f.rating
        WHEN 'G' THEN 'All Ages'
        WHEN 'PG' THEN 'Parental Guidance Suggested (7+)'
        WHEN 'PG-13' THEN 'Parents Strongly Cautioned (13+)'
        WHEN 'R' THEN 'Restricted (17+)'
        WHEN 'NC-17' THEN 'Adults Only (18+)'
        ELSE 'Not Rated'
    END AS expected_age
FROM
    public.film AS f
INNER JOIN
    public.inventory AS i ON f.film_id = i.film_id
INNER JOIN
    public.rental AS r ON i.inventory_id = r.inventory_id
GROUP BY
    f.film_id, f.title, f.rating -- Grouping by PK and title is sufficient
ORDER BY
    number_of_rentals DESC
LIMIT 5;

-- PROS: Single, efficient query; CASE statement handles the business logic (age mapping) clearly.
-- CONS: CASE statement logic can clutter the main SELECT statement if the conditions are complex.

---------------------------------------------------------------------------------
-- Solution 2.2: Subquery (in SELECT clause)
---------------------------------------------------------------------------------
-- Subqueries in the SELECT clause are not suitable here, as the age mapping is a static lookup,
-- not a calculation per row. We'll use a subquery to find the top rental IDs first.
SELECT
    f.title,
    rental_counts.num_rentals AS number_of_rentals,
    CASE f.rating
        WHEN 'G' THEN 'All Ages'
        WHEN 'PG' THEN 'Parental Guidance Suggested (7+)'
        WHEN 'PG-13' THEN 'Parents Strongly Cautioned (13+)'
        WHEN 'R' THEN 'Restricted (17+)'
        WHEN 'NC-17' THEN 'Adults Only (18+)'
        ELSE 'Not Rated'
    END AS expected_age
FROM
    public.film AS f
INNER JOIN
    (
        -- Subquery: Calculates rental count per film
        SELECT
            i.film_id,
            COUNT(r.rental_id) AS num_rentals
        FROM
            public.inventory AS i
        INNER JOIN
            public.rental AS r ON i.inventory_id = r.inventory_id
        GROUP BY
            i.film_id
        ORDER BY
            num_rentals DESC
        LIMIT 5
    ) AS rental_counts ON f.film_id = rental_counts.film_id
ORDER BY
    number_of_rentals DESC;

-- PROS: Isolates the popular film calculation (aggregation and limiting) cleanly.
-- CONS: Can be inefficient as the subquery is executed first and materialized, although LIMIT 5 helps performance significantly.

---------------------------------------------------------------------------------
-- Solution 2.3: CTE (Common Table Expression)
---------------------------------------------------------------------------------
WITH TopFilms AS (
    -- Step 1: Find the top 5 films by rental count
    SELECT
        i.film_id,
        COUNT(r.rental_id) AS number_of_rentals
    FROM
        public.inventory AS i
    INNER JOIN
        public.rental AS r ON i.inventory_id = r.inventory_id
    GROUP BY
        i.film_id
    ORDER BY
        number_of_rentals DESC
    LIMIT 5
)
SELECT
    f.title,
    tf.number_of_rentals,
    CASE f.rating
        WHEN 'G' THEN 'All Ages'
        WHEN 'PG' THEN 'Parental Guidance Suggested (7+)'
        WHEN 'PG-13' THEN 'Parents Strongly Cautioned (13+)'
        WHEN 'R' THEN 'Restricted (17+)'
        WHEN 'NC-17' THEN 'Adults Only (18+)'
        ELSE 'Not Rated'
    END AS expected_age
FROM
    public.film AS f
INNER JOIN
    TopFilms AS tf ON f.film_id = tf.film_id
ORDER BY
    tf.number_of_rentals DESC;

-- PROS: Highest readability; the CTE clearly names and defines the core calculation (TopFilms).
-- CONS: Most verbose.

/*********************************************************************************
 * PART 3, TASK 3.V1: Inactivity Gap (Latest Film to Current Year)
 *********************************************************************************/

-- TASK: V1: gap between the latest release_year and current year per each actor.

-- BUSINESS LOGIC:
-- 1. Latest Film: MAX(film.release_year) grouped by actor.
-- 2. Gap: EXTRACT(YEAR FROM CURRENT_DATE) - MAX(film.release_year).
-- 3. Join Path: actor -> film_actor -> film.

---------------------------------------------------------------------------------
-- Solution V1.1: INNER JOIN (Aggregation)
---------------------------------------------------------------------------------
SELECT
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS latest_film_year,
    (EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year)) AS years_inactive
FROM
    public.actor AS a
INNER JOIN
    public.film_actor AS fa ON a.actor_id = fa.actor_id
INNER JOIN
    public.film AS f ON fa.film_id = f.film_id
GROUP BY
    a.actor_id, a.first_name, a.last_name
ORDER BY
    years_inactive DESC;

-- PROS: Simple, single-pass aggregate query. Highly efficient.
-- CONS: None; this is the definitive solution for this interpretation.

---------------------------------------------------------------------------------
-- Solution V1.2: Subquery (in SELECT clause - not efficient, but possible)
---------------------------------------------------------------------------------
SELECT
    a.first_name,
    a.last_name,
    (
        SELECT MAX(f.release_year)
        FROM public.film AS f
        INNER JOIN public.film_actor AS fa ON f.film_id = fa.film_id
        WHERE fa.actor_id = a.actor_id
    ) AS latest_film_year,
    (EXTRACT(YEAR FROM CURRENT_DATE) - (
        SELECT MAX(f.release_year)
        FROM public.film AS f
        INNER JOIN public.film_actor AS fa ON f.film_id = fa.film_id
        WHERE fa.actor_id = a.actor_id
    )) AS years_inactive
FROM
    public.actor AS a
ORDER BY
    years_inactive DESC;

-- PROS: Avoids an explicit JOIN in the main FROM clause.
-- CONS: **Poor Performance.** This is a Correlated Subquery that runs for EVERY row in the 'actor' table. Do not use in production.

---------------------------------------------------------------------------------
-- Solution V1.3: CTE (Grouping logic into a CTE)
---------------------------------------------------------------------------------
WITH ActorLatestFilm AS (
    SELECT
        fa.actor_id,
        MAX(f.release_year) AS latest_year
    FROM
        public.film_actor AS fa
    INNER JOIN
        public.film AS f ON fa.film_id = f.film_id
    GROUP BY
        fa.actor_id
)
SELECT
    a.first_name,
    a.last_name,
    alf.latest_year AS latest_film_year,
    (EXTRACT(YEAR FROM CURRENT_DATE) - alf.latest_year) AS years_inactive
FROM
    public.actor AS a
INNER JOIN
    ActorLatestFilm AS alf ON a.actor_id = alf.actor_id
ORDER BY
    years_inactive DESC;

-- PROS: Clear separation of logic; the calculation (ActorLatestFilm) is isolated from the reporting (actor names).
-- CONS: More steps than the optimal JOIN.

/*********************************************************************************
 * PART 3, TASK 3.V2: Inactivity Gap (Gaps between sequential films)
 *********************************************************************************/

-- TASK: V2: gaps between sequential films per each actor; then find the actor with the maximum gap.
-- Constraint: Cannot use Window Functions (LAG/LEAD).

-- BUSINESS LOGIC:
-- 1. Find the next film's release year for every film an actor was in.
-- 2. Correlated Subquery (CS) is needed: For a given film and actor, find the MIN(release_year) of all *other* films for that actor that are *later* than the current film's year.
-- 3. Calculate the gap: next_year - current_year.
-- 4. Find the MAX of these gaps per actor.

---------------------------------------------------------------------------------
-- Solution V2.1: Correlated Subquery (to find the next year)
---------------------------------------------------------------------------------
WITH FilmGaps AS (
    -- Step 1: Generate a row for every film an actor was in, and calculate the gap to the *next* film.
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        f_current.release_year AS current_film_year,
        (
            -- Correlated Subquery: Finds the minimum (next) release year greater than the current one for this actor
            SELECT
                MIN(f_next.release_year)
            FROM
                public.film AS f_next
            INNER JOIN
                public.film_actor AS fa_next ON f_next.film_id = fa_next.film_id
            WHERE
                fa_next.actor_id = a.actor_id -- Correlation: same actor
                AND f_next.release_year > f_current.release_year -- Next year must be greater than current year
        ) AS next_film_year
    FROM
        public.actor AS a
    INNER JOIN
        public.film_actor AS fa_current ON a.actor_id = fa_current.actor_id
    INNER JOIN
        public.film AS f_current ON fa_current.film_id = f_current.film_id
    GROUP BY
        a.actor_id, a.first_name, a.last_name, f_current.release_year -- GROUP BY removes duplicate films in the same year
)
-- Step 2: Calculate the gap and find the maximum gap per actor.
SELECT
    fg.first_name,
    fg.last_name,
    MAX(fg.next_film_year - fg.current_film_year) AS max_sequential_gap_years
FROM
    FilmGaps AS fg
WHERE
    fg.next_film_year IS NOT NULL -- Exclude the last film, which has a NULL 'next_film_year'
GROUP BY
    fg.first_name, fg.last_name
ORDER BY
    max_sequential_gap_years DESC;

-- PROS: Solves the problem precisely without window functions.
-- CONS: **EXTREMELY COMPLEX AND RESOURCE INTENSIVE.** The correlated subquery runs many times, making it very slow.

---------------------------------------------------------------------------------
-- Solution V2.2: Self-JOIN (Alternative to Correlated Subquery)
---------------------------------------------------------------------------------
-- Note: A self-JOIN is also needed here, which is often complex and hard to ensure MIN(next_year) logic.
-- The correlated subquery is the more standard, albeit resource-heavy, way to avoid window functions.
-- Since the correlated subquery (V2.1) is the required technique here, the other two solutions will be omitted
-- as they either rely on the same heavy logic or require unsupported functions.

---------------------------------------------------------------------------------
-- Solution V2.3: CTE (Same as V2.1, but using a CTE structure)
---------------------------------------------------------------------------------
-- V2.3 is omitted as it is functionally identical to V2.1, only with a more structured CTE for the main logic.
-- V2.1 stands as the representative solution for the required logic.
