-- PostgreSQL initialization script for Docker (idempotent).
-- Designed to be placed in /docker-entrypoint-initdb.d/ or mounted and executed
-- by your postgres container on first init.
--
-- NOTE: This script uses psql meta-commands (\connect) which are supported when
-- the file is executed by the official postgres docker entrypoint.

-- --------------------------
-- 1) Create role and database (if missing)
-- --------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'napasa_main_user') THEN
    CREATE ROLE napasa_main_user WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD 'napasa_main_password';
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'napasa_main_backend') THEN
    PERFORM pg_sleep(0.01); -- tiny pause for safety
    CREATE DATABASE napasa_main_backend OWNER napasa_main_user ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;
  END IF;
END$$;

\connect napasa_main_backend

-- --------------------------
-- 2) Extensions
-- --------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

-- --------------------------
-- 3) Helper: update timestamp trigger
-- --------------------------
CREATE OR REPLACE FUNCTION public.trigger_set_timestamp()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- --------------------------
-- 4) Users table
-- --------------------------
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email citext NOT NULL UNIQUE,
  password text NOT NULL,
  name text NOT NULL,
  phone text,
  role text NOT NULL CHECK (role IN (
    'Tourist',
    'Travel Agency',
    'Lodge Owner',
    'Restaurant Owner',
    'Travel Gear Seller',
    'Photographer',
    'Tour Guide',
    'Admin'
  )),
  avatar text,
  is_active boolean NOT NULL DEFAULT true,
  is_verified boolean NOT NULL DEFAULT false,
  last_active timestamptz DEFAULT now(),
  additional_data jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users (email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users (role);
CREATE INDEX IF NOT EXISTS idx_users_active ON public.users (is_active);

DROP TRIGGER IF EXISTS users_set_timestamp ON public.users;
CREATE TRIGGER users_set_timestamp
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

-- --------------------------
-- 5) Parks table
-- --------------------------
CREATE TABLE IF NOT EXISTS public.parks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  location text,
  coordinates jsonb, -- { "latitude": .., "longitude": .. }
  area_km2 numeric,
  established_year integer,
  entry_fee_usd numeric,
  wildlife text[],
  best_time_to_visit text,
  facilities text[],
  activities text[],
  images jsonb DEFAULT '[]'::jsonb,
  climate text,
  accessibility text,
  is_active boolean NOT NULL DEFAULT true,
  rating_avg numeric DEFAULT 0,
  rating_count integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_parks_name ON public.parks (name);

DROP TRIGGER IF EXISTS parks_set_timestamp ON public.parks;
CREATE TRIGGER parks_set_timestamp
BEFORE UPDATE ON public.parks
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

-- --------------------------
-- 6) Tours table
-- --------------------------
CREATE TABLE IF NOT EXISTS public.tours (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  park uuid REFERENCES public.parks(id) ON DELETE SET NULL,
  agency uuid REFERENCES public.users(id) ON DELETE SET NULL,
  duration_days integer,
  price_usd numeric,
  max_participants integer,
  current_participants integer DEFAULT 0,
  difficulty_level text,
  includes text[],
  excludes text[],
  itinerary jsonb DEFAULT '[]'::jsonb,
  images jsonb DEFAULT '[]'::jsonb,
  requirements text[],
  what_to_bring text[],
  cancellation_policy text DEFAULT 'Free cancellation up to 24 hours before tour start',
  is_active boolean NOT NULL DEFAULT true,
  is_available boolean NOT NULL DEFAULT true,
  start_dates jsonb DEFAULT '[]'::jsonb, -- [{ "date": "...", "availableSpots": n }, ...]
  rating_avg numeric DEFAULT 0,
  rating_count integer DEFAULT 0,
  tags text[],
  search_vector tsvector,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tours_title ON public.tours (title);
CREATE INDEX IF NOT EXISTS idx_tours_park ON public.tours (park);
CREATE INDEX IF NOT EXISTS idx_tours_agency ON public.tours (agency);
CREATE INDEX IF NOT EXISTS idx_tours_active_avail ON public.tours (is_active, is_available);
CREATE INDEX IF NOT EXISTS idx_tours_price ON public.tours (price_usd);
CREATE INDEX IF NOT EXISTS idx_tours_duration ON public.tours (duration_days);
CREATE INDEX IF NOT EXISTS idx_tours_tags ON public.tours USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_tours_search_vector ON public.tours USING GIN (search_vector);

-- trigger to update search_vector
CREATE OR REPLACE FUNCTION public.tours_search_vector_update()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.search_vector :=
    to_tsvector('english', coalesce(NEW.title, '') || ' ' || coalesce(NEW.description, ''));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tours_set_timestamp ON public.tours;
CREATE TRIGGER tours_set_timestamp
BEFORE UPDATE ON public.tours
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

DROP TRIGGER IF EXISTS tours_search_vector_trg ON public.tours;
CREATE TRIGGER tours_search_vector_trg
BEFORE INSERT OR UPDATE ON public.tours
FOR EACH ROW EXECUTE FUNCTION public.tours_search_vector_update();

-- --------------------------
-- 7) Lodges table
-- --------------------------
CREATE TABLE IF NOT EXISTS public.lodges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  location text NOT NULL,
  park uuid REFERENCES public.parks(id) ON DELETE SET NULL,
  lodge_type text,
  capacity integer,
  price_per_night_usd numeric,
  amenities text[],
  description text,
  images jsonb DEFAULT '[]'::jsonb,
  contact_email citext,
  contact_phone text,
  coordinates jsonb,
  is_active boolean NOT NULL DEFAULT true,
  rating_avg numeric DEFAULT 0,
  rating_count integer DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lodges_name ON public.lodges (name);
CREATE INDEX IF NOT EXISTS idx_lodges_park ON public.lodges (park);

DROP TRIGGER IF EXISTS lodges_set_timestamp ON public.lodges;
CREATE TRIGGER lodges_set_timestamp
BEFORE UPDATE ON public.lodges
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

-- --------------------------
-- 8) Bookings table
-- --------------------------
CREATE TABLE IF NOT EXISTS public.bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "user" uuid REFERENCES public.users(id) ON DELETE CASCADE,
  tour uuid REFERENCES public.tours(id) ON DELETE CASCADE,
  participants jsonb DEFAULT '{}'::jsonb, -- { adults: n, children: n, infants: n }
  total_participants integer,
  start_date timestamptz,
  end_date timestamptz,
  price_usd numeric,
  status text DEFAULT 'pending',
  payment_status text DEFAULT 'pending',
  reserved_at timestamptz DEFAULT now(),
  cancelled_at timestamptz,
  refunded_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bookings_user ON public.bookings ("user");
CREATE INDEX IF NOT EXISTS idx_bookings_tour ON public.bookings (tour);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings (status);
CREATE INDEX IF NOT EXISTS idx_bookings_payment ON public.bookings (payment_status);
CREATE INDEX IF NOT EXISTS idx_bookings_startdate ON public.bookings (start_date);

DROP TRIGGER IF EXISTS bookings_set_timestamp ON public.bookings;
CREATE TRIGGER bookings_set_timestamp
BEFORE UPDATE ON public.bookings
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

-- --------------------------
-- 9) Reviews table
-- --------------------------
CREATE TABLE IF NOT EXISTS public.reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "user" uuid REFERENCES public.users(id) ON DELETE CASCADE,
  tour uuid REFERENCES public.tours(id) ON DELETE CASCADE,
  booking uuid REFERENCES public.bookings(id) ON DELETE SET NULL,
  rating smallint CHECK (rating >= 0 AND rating <= 5),
  title text,
  comment text,
  pros text[],
  cons text[],
  images jsonb DEFAULT '[]'::jsonb,
  is_verified boolean DEFAULT false,
  is_public boolean DEFAULT true,
  helpful_count integer DEFAULT 0,
  helpful_users uuid[] DEFAULT '{}',
  response jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reviews_user ON public.reviews ("user");
CREATE INDEX IF NOT EXISTS idx_reviews_tour ON public.reviews (tour);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON public.reviews (rating);

DROP TRIGGER IF EXISTS reviews_set_timestamp ON public.reviews;
CREATE TRIGGER reviews_set_timestamp
BEFORE UPDATE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();

-- --------------------------
-- 10) Grants
-- --------------------------
GRANT CONNECT ON DATABASE napasa_main_backend TO napasa_main_user;
GRANT USAGE ON SCHEMA public TO napasa_main_user;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO napasa_main_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO napasa_main_user;

-- --------------------------
-- Finalization
-- --------------------------
-- Optionally you can insert seed rows here. Avoid inserting plain-text passwords.
-- Leave seeding to your application or use bcrypt-hashed values generated outside SQL.

-- End of setup.sql