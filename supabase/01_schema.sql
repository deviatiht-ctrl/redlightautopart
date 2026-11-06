-- ============================================================
-- REDLIGHT AUTOPARTS — 01_schema.sql
-- Tables + triggers updated_at avèk prefixe redlight_.
-- ============================================================

create table if not exists redlight_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text,               -- non icon Lucide (string) pou app la mapé li
  image_url text,          -- URL imaj pou bèl kat orizontal rektangilè
  created_at timestamptz default now()
);
alter table redlight_categories add column if not exists image_url text;

create table if not exists redlight_products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price numeric(10,2) not null,
  stock int not null default 0,
  category_id uuid references redlight_categories(id) on delete set null,
  compatible_models text[],   -- ['Toyota Corolla 2015-2020', ...]
  images text[],              -- URLs Supabase Storage
  is_demo boolean default false, -- flag pou fasil idantifye/efase done demo pita
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists redlight_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  status text default 'pending', -- pending | confirmed | shipped | delivered | cancelled
  total numeric(10,2) not null,
  delivery_address text,
  payment_method text,
  checkout_key uuid,
  payment_status text not null default 'unpaid',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists redlight_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references redlight_orders(id) on delete cascade,
  product_id uuid references redlight_products(id),
  quantity int not null,
  unit_price numeric(10,2) not null
);

create table if not exists redlight_admin_users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null
);

-- ------------------------------------------------------------
-- Trigger: mete updated_at ajou otomatikman
-- ------------------------------------------------------------
create or replace function public.redlight_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_redlight_products_updated_at on redlight_products;
create trigger trg_redlight_products_updated_at
  before update on redlight_products
  for each row execute function public.redlight_set_updated_at();

drop trigger if exists trg_redlight_orders_updated_at on redlight_orders;
create trigger trg_redlight_orders_updated_at
  before update on redlight_orders
  for each row execute function public.redlight_set_updated_at();
