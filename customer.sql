-- Book-It.com Hotel Search Engine Database Schema
-- CockroachDB schema for hotel semantic search with geospatial filtering

-- Drop table if exists (for clean recreation)
DROP TABLE IF EXISTS customer CASCADE;

-- Customer table
CREATE TABLE IF NOT EXISTS customer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name STRING NOT NULL,
    last_name STRING NOT NULL,
    email STRING UNIQUE NOT NULL,
    phone STRING,
    address STRING,
    city STRING NOT NULL,
    postal_code STRING,
    country STRING NOT NULL,
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT now()
);

