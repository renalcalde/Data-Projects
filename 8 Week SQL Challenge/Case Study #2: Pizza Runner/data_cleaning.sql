
/*
8 WEEK SQL CHALLENGE
CASE STUDY #2: PIZZA RUNNER 
(DATA CLEANING)
*/

-- CLEANS customer_orders TABLE
-- replaces all empty rows and capitalize null into NULL
UPDATE customer_orders
SET exclusions = NULL
WHERE TRIM(exclusions) = '' OR TRIM(exclusions) = 'null';

UPDATE customer_orders
SET extras = NULL
WHERE TRIM(extras) = '' OR TRIM(extras) = 'null';


-- CLEANS runner_orders TABLE
-- change columns to show metrics
ALTER TABLE runner_orders
RENAME COLUMN distance TO distance_km;

ALTER TABLE runner_orders
RENAME COLUMN duration TO duration_mins;
 
-- adds NULL 
UPDATE runner_orders
SET pickup_time = NULL
WHERE TRIM(pickup_time) = '' OR TRIM(pickup_time) = 'null';

UPDATE runner_orders
SET distance_km = NULL
WHERE TRIM(distance_km) = '' OR TRIM(distance_km) = 'null';

UPDATE runner_orders
SET duration_mins = NULL
WHERE TRIM(duration_mins) = '' OR TRIM(duration_mins) = 'null';

UPDATE runner_orders
SET cancellation = NULL
WHERE TRIM(cancellation) = '' OR TRIM(cancellation) = 'null';

-- removes km inside columns
UPDATE runner_orders
SET distance_km = REPLACE(distance_km, 'km', '')
WHERE distance_km LIKE '%km%';

-- removes minutes inside columns
UPDATE runner_orders
SET duration_mins = REPLACE(duration_mins, 'minute', '')
WHERE duration_mins LIKE '%min%';

UPDATE runner_orders
SET duration_mins = REPLACE(duration_mins, 'minutes', '')
WHERE duration_mins LIKE '%min%';

UPDATE runner_orders
SET duration_mins = REPLACE(duration_mins, 'mins', '')
WHERE duration_mins LIKE '%min%';

-- changes all the type to the appropriate data type
ALTER TABLE runner_orders
ALTER COLUMN duration_mins TYPE INT USING duration_mins::INT;

ALTER TABLE runner_orders
ALTER COLUMN distance_km TYPE FLOAT USING distance_km::FLOAT;

ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::TIMESTAMP;
