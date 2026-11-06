-- ============================================================
-- REDLIGHT AUTOPARTS — 09_today_offers.sql
-- Tab pou jere Today's Offers (Flyers ak bouton Shop Now pozisyone)
-- ============================================================

create table if not exists public.redlight_today_offers (
  id uuid primary key default gen_random_uuid(),
  title text not null default '',
  subtitle text,
  image_url text not null,
  product_id uuid references public.redlight_products(id) on delete set null,
  button_text text not null default 'SHOP NOW',
  button_align_x double precision not null default -0.7,
  button_align_y double precision not null default 0.65,
  button_color text not null default '#FF5000',
  button_text_color text not null default '#FFFFFF',
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.redlight_today_offers enable row level security;

-- Tout itilizatè ka li òf aktif yo
drop policy if exists redlight_today_offers_read_all on public.redlight_today_offers;
create policy redlight_today_offers_read_all on public.redlight_today_offers
  for select using (true);

-- Admin sèlman ka kreye, modifye, oswa efase
drop policy if exists redlight_today_offers_admin_all on public.redlight_today_offers;
create policy redlight_today_offers_admin_all on public.redlight_today_offers
  for all using (public.redlight_is_admin()) with check (public.redlight_is_admin());

-- Trigger pou mete updated_at ajou
drop trigger if exists trg_redlight_today_offers_updated_at on public.redlight_today_offers;
create trigger trg_redlight_today_offers_updated_at
  before update on public.redlight_today_offers
  for each row execute function public.redlight_set_updated_at();
