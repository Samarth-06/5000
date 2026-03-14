-- =============================================================
-- Supabase Schema for Smart Farm / Sat2Farm App
-- Run this in the Supabase SQL Editor
-- =============================================================

-- 1. Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Farms table
CREATE TABLE IF NOT EXISTS public.farms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  farm_id TEXT,
  crop_type TEXT,
  location JSONB,
  name TEXT,
  area_in_acres FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Vegetation History table
CREATE TABLE IF NOT EXISTS public.vegetation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id TEXT,
  ndvi FLOAT,
  lswi FLOAT,
  rvi FLOAT,
  sm FLOAT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Weather History table
CREATE TABLE IF NOT EXISTS public.weather_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id TEXT,
  temperature FLOAT,
  humidity FLOAT,
  wind_speed FLOAT,
  rainfall_probability FLOAT,
  narrative TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Image Reports table
CREATE TABLE IF NOT EXISTS public.image_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id TEXT,
  image_url TEXT,
  disease TEXT,
  advisory TEXT,
  solution TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (optional but recommended)
ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vegetation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weather_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.image_reports ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies: allow all authenticated users
CREATE POLICY "Allow all for authenticated users" ON public.farms
  FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow all for authenticated users" ON public.vegetation_history
  FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow all for authenticated users" ON public.weather_history
  FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Allow all for authenticated users" ON public.image_reports
  FOR ALL USING (auth.uid() IS NOT NULL);
