-- Book-It.com Hotel Search Engine Database Schema
-- CockroachDB schema for hotel semantic search with geospatial filtering

-- Drop table if exists (for clean recreation)
DROP TABLE IF EXISTS hotel CASCADE;

-- Main hotel table - with column families
CREATE TABLE IF NOT EXISTS hotel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name STRING NOT NULL,
    location GEOGRAPHY(POINT) NOT NULL,
    metadata JSONB NOT NULL,
    embedding VECTOR(512),

    FAMILY f_primary (id, name),
    FAMILY f_details (location, metadata),
    FAMILY f_vector  (embedding)
);
