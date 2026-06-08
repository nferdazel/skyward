-- Catalog upsert template for curated seed files.
-- Replace the staging INSERT payloads with generated values from:
-- - data/curated/airports_seed.csv
-- - data/curated/aircraft_models_seed.csv

BEGIN;

CREATE TEMP TABLE staging_airports (
  iata VARCHAR(3) PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  demand_index INT NOT NULL,
  airport_tax NUMERIC(12,2) NOT NULL
) ON COMMIT DROP;

CREATE TEMP TABLE staging_aircraft_models (
  manufacturer TEXT NOT NULL,
  model_name TEXT NOT NULL,
  type TEXT NOT NULL,
  range_km INT NOT NULL,
  capacity INT NOT NULL,
  speed_kmh INT NOT NULL,
  fuel_burn_per_km NUMERIC(12,3) NOT NULL,
  maintenance_cost_per_hour NUMERIC(12,2) NOT NULL,
  purchase_price NUMERIC(20,2) NOT NULL,
  lease_price_per_month NUMERIC(20,2) NOT NULL,
  PRIMARY KEY (manufacturer, model_name)
) ON COMMIT DROP;

-- Populate staging tables here before running the upserts.
-- Example:
-- INSERT INTO staging_airports (iata, name, city, country, latitude, longitude, demand_index, airport_tax)
-- VALUES
--   ('CGK', 'Soekarno-Hatta International Airport', 'Jakarta', 'Indonesia', -6.1256, 106.6558, 95, 1200.00);

INSERT INTO airports (
  iata,
  name,
  city,
  country,
  latitude,
  longitude,
  demand_index,
  airport_tax
)
SELECT
  iata,
  name,
  city,
  country,
  latitude,
  longitude,
  demand_index,
  airport_tax
FROM staging_airports
ON CONFLICT (iata) DO UPDATE SET
  name = EXCLUDED.name,
  city = EXCLUDED.city,
  country = EXCLUDED.country,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  demand_index = EXCLUDED.demand_index,
  airport_tax = EXCLUDED.airport_tax;

INSERT INTO aircraft_models (
  manufacturer,
  model_name,
  type,
  range_km,
  capacity,
  speed_kmh,
  fuel_burn_per_km,
  maintenance_cost_per_hour,
  purchase_price,
  lease_price_per_month
)
SELECT
  manufacturer,
  model_name,
  type,
  range_km,
  capacity,
  speed_kmh,
  fuel_burn_per_km,
  maintenance_cost_per_hour,
  purchase_price,
  lease_price_per_month
FROM staging_aircraft_models
ON CONFLICT (manufacturer, model_name) DO UPDATE SET
  type = EXCLUDED.type,
  range_km = EXCLUDED.range_km,
  capacity = EXCLUDED.capacity,
  speed_kmh = EXCLUDED.speed_kmh,
  fuel_burn_per_km = EXCLUDED.fuel_burn_per_km,
  maintenance_cost_per_hour = EXCLUDED.maintenance_cost_per_hour,
  purchase_price = EXCLUDED.purchase_price,
  lease_price_per_month = EXCLUDED.lease_price_per_month;

COMMIT;
