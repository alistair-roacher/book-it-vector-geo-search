-- Book-It.com Hotel Search Engine Database Schema
-- CockroachDB schema for hotel semantic search with geospatial filtering

-- Drop table if exists (for clean recreation)
DROP TABLE IF EXISTS stay CASCADE;

-- Stay table (booking records)
CREATE TABLE IF NOT EXISTS stay (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
    hotel_id UUID NOT NULL REFERENCES hotel(id) ON DELETE CASCADE,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    number_of_guests INT NOT NULL DEFAULT 1,
    room_type STRING,
    total_price DECIMAL(10,2),
    booking_status STRING NOT NULL DEFAULT 'confirmed',
    special_requests STRING,
    created_at TIMESTAMP DEFAULT now(),

    CONSTRAINT valid_dates CHECK (check_out_date > check_in_date),
    CONSTRAINT valid_guests CHECK (number_of_guests > 0 AND number_of_guests <= 10),
    CONSTRAINT valid_status CHECK (booking_status IN ('confirmed', 'cancelled', 'completed', 'no-show'))
);

