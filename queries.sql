
--
-- Standard Relational Queries
--

-- Customer details and all stays for a given customer_id - f19b4c65-55c0-4567-97e4-7763100a7772

SELECT
    c.first_name || ' ' || c.last_name as customer, c.country, c.email
FROM customer c
WHERE c.id='f19b4c65-55c0-4567-97e4-7763100a7772';

SELECT s.check_in_date, s.check_out_date-s.check_in_date as length,
    h.name as hotel_name, s.room_type, s.number_of_guests, s.total_price
FROM stay s
JOIN customer c ON s.customer_id = c.id
JOIN hotel h ON s.hotel_id = h.id
WHERE c.id='f19b4c65-55c0-4567-97e4-7763100a7772'
ORDER BY s.check_in_date DESC;


-- All "no shows" from Ireland with more than one guest

SELECT
    c.first_name || ' ' || c.last_name as customer,
    c.email as customer_email,
    h.name as hotel_name,
    s.check_in_date,
    (s.check_out_date - s.check_in_date) as nights,
    s.number_of_guests as guests,
    s.room_type,
    s.total_price
FROM stay s
JOIN customer c ON s.customer_id = c.id
JOIN hotel h ON s.hotel_id = h.id
WHERE booking_status = 'no-show' AND number_of_guests > 1 AND c.country='Ireland'
ORDER BY s.total_price DESC;

-- Partial index to accerlerate the above query

CREATE INDEX ON stay (customer_id) 
  STORING (hotel_id, check_in_date, check_out_date, room_type, total_price, number_of_guests)
WHERE (booking_status = 'no-show') AND (number_of_guests > 1);


-- Top 10 spenders

SELECT
    c.first_name || ' ' || c.last_name as customer,
    c.country, c.email,
    min(s.check_in_date) as earliest_date,
    max(s.check_in_date) as latest_date,
    avg(s.check_out_date - s.check_in_date)::DECIMAL(2,1) as avg_nights,
    count(s.check_in_date) as stays,
    sum(s.total_price) as total_spend
FROM stay s
JOIN customer c ON s.customer_id = c.id
JOIN hotel h ON s.hotel_id = h.id
GROUP BY 1,2,3
ORDER BY 8 DESC
LIMIT 10;


--
-- JSONB queries
--

-- Show hotel metadata

SELECT metadata FROM hotel WHERE name = 'The Station Hotel Galway';

-- Extract data from the JSONB metadata column 

SELECT (metadata->'bed_types') AS bed_types, metadata->'room_facilities' AS room_facilities,
        metadata->>'board_type' AS board_type, metadata->>'review_score' AS review_score
FROM hotel 
WHERE name = 'The Station Hotel Galway';

-- How many hotels in Ireland have a swimming pool and where are they located?

SELECT metadata->>'city' as city, count(*) 
FROM hotel 
WHERE metadata @> '{"country": "Ireland", "swimming_pool": true}'
GROUP BY 1
ORDER BY 1;

-- Show that missing data in the JSON column returns NULL (UK hotels did not have a "country" attribute)

SELECT metadata->>'country' AS country, count(*) FROM hotel GROUP BY 1 ORDER BY 1;


--
-- Full text search (using a trigram index)
--

-- Find all hotels that have "boutique" in the name (case insensitive)

SELECT name FROM hotel WHERE name ilike '%boutique%'; 

-- Find the plan for the above query

EXPLAIN SELECT name FROM hotel WHERE name ilike '%boutique%';  

-- Create a trigram index and re-execute the above EXPLAINM

CREATE INVERTED INDEX hotel_name_trigram_idx ON hotel (name gin_trgm_ops);

-- Can this query make use of the trigram index? If not, why not? (hint: tri=3)

EXPLAIN SELECT name FROM hotel WHERE name ilike '%ij%'; 


--
-- Full text search (using a TSVECTOR virtual column)
--

-- Add a virtual column as the name converted into a TSVECTOR

ALTER TABLE hotel ADD COLUMN ts_vector TSVECTOR AS (to_tsvector('english',name)) VIRTUAL;

-- Show the format of the TSVECTOR column

SELECT name, ts_vector FROM hotel LIMIT 5;

-- Query for keywords using a TSQUERY

SELECT name FROM hotel WHERE ts_vector @@ to_tsquery('english', 'crown <-> plaza');

-- Use EXPLAIN to find out how the above query is executed 
-- Create an INVERTED INDEX on the TSVECTOR column to optimise the search and EXPLAIN again

CREATE INVERTED INDEX ts_vector_idx ON hotel (ts_vector);


--
-- VECTOR queries
--

-- Create a function to get a preview of an embedding

CREATE OR REPLACE FUNCTION embedding_preview(v VECTOR)
RETURNS STRING AS $$
  SELECT left(v::string, 100) || '…'
$$ LANGUAGE SQL IMMUTABLE;

-- Show some hotel rows

\set display_format=records
SELECT name, location, metadata, vector_dims(embedding), embedding_preview(embedding) 
FROM hotel
WHERE embedding is not null 
LIMIT 2;
\set display_format=table

-- Find recommendations based on last stay

WITH last_stay(embedding,city,hotel_name) as
  (select embedding, metadata->>'city', name from hotel 
    where id=(select hotel_id from stay WHERE customer_id='f19b4c65-55c0-4567-97e4-7763100a7772' 
    order by check_in_date desc limit 1) )
SELECT ls.city as last_city, ls.hotel_name as last_hotel, 
        h.metadata->>'city' as new_city, h.name as new_hotel, 
        (h.embedding <-> ls.embedding)::DECIMAL(5,4) as vector_distance
FROM hotel h, last_stay ls 
WHERE h.metadata->>'city' != ls.city AND h.embedding is not null
ORDER BY vector_distance limit 5;



--
-- Geospatial queries
--

-- How can we define a point on the globe (e.g. Amsterdam Centraal)?

SELECT st_geographyfromtext('POINT(4.8994 52.3792)');

-- Which hotels are within 5km of Amsterdam Centraal? List all hotels by distance (nearest first).

SELECT name AS hotel_name, metadata->>'review_score' AS review, st_asewkt(location) AS exact_location,
    (st_distance(location, st_geographyfromtext('POINT(4.8994 52.3792)'))/1000)::DECIMAL(3,2) AS dist_in_km
FROM hotel
WHERE st_dwithin(st_geographyfromtext('POINT(4.8994 52.3792)'), location, 5000)
ORDER BY 3;

-- Use EXPLAIN to get the plan for the above query

-- Create an index to accelerate this query (prevent the FULL SCAN)

CREATE INVERTED INDEX ON hotel (location);

-- Make the Geo-spatial index invisible and EXPLAIN the query again 

ALTER INDEX hotel_location_idx NOT VISIBLE;



