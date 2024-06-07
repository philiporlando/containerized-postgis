-- Seed the database with some test data

BEGIN;

-- Set the default search path to the public schema
SET search_path TO public;

-- Enable PostGIS extension (if it's not already enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create a table to store test data with a geographic point (latitude, longitude)
CREATE TABLE public.test_places (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    geom GEOGRAPHY(Point, 4326) 
);

-- Insert some initial test_places
INSERT INTO public.test_places (name, description, geom) VALUES
('Eiffel Tower', 'A wrought-iron lattice tower on the Champ de Mars in Paris, France.', ST_GeogFromText('POINT(2.2945 48.8584)')),
('Statue of Liberty', 'A colossal neoclassical sculpture on Liberty Island in New York Harbor within New York City.', ST_GeogFromText('POINT(-74.0445 40.6892)'));

-- Test PostGIS functionality
DO $$
DECLARE
    calculated_distance DOUBLE PRECISION;
    expected_distance DOUBLE PRECISION := 5853103.67725805;
    BEGIN
    -- Calculate the distance between two points, for example, Eiffel Tower and Statue of Liberty
    SELECT ST_Distance(p1.geom, p2.geom) INTO calculated_distance
    FROM test_places p1, test_places p2
    WHERE p1.name = 'Eiffel Tower' AND p2.name = 'Statue of Liberty';

    -- Check if the calculated distance matches the expected distance (with a 1 meter tolerance)
    IF abs(calculated_distance - expected_distance) > 1 THEN
        RAISE EXCEPTION 'Distance assertion failed: Expected %, Found %', expected_distance, calculated_distance;
    END IF;
END $$;
 
 COMMIT;
