begin;

-- ============================================================
-- REDLIGHT AUTOPARTS — 08_tracking.sql
-- Swivi koli (tracking): pozisyon + ETA + istorik etap.
-- ============================================================

-- Pozisyon kounye a nan koli a (1 ranje pa kòmand).
create table if not exists public.redlight_order_tracking (
  order_id uuid primary key references public.redlight_orders(id) on delete cascade,
  location text,                        -- tèks lib: "Okap — Wout Nasyonal 1"
  latitude double precision,
  longitude double precision,
  eta_at timestamptz,                   -- dat/lè livrezon estime
  delay_note text,                      -- anprevu siyale pa admin (null = pa gen)
  updated_by uuid references auth.users(id),
  updated_at timestamptz not null default now()
);

alter table public.redlight_order_tracking enable row level security;

drop policy if exists redlight_order_tracking_read on public.redlight_order_tracking;
drop policy if exists redlight_order_tracking_admin_write on public.redlight_order_tracking;

create policy redlight_order_tracking_read on public.redlight_order_tracking for select using (
  public.redlight_is_admin()
  or exists(
    select 1 from public.redlight_orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
);
create policy redlight_order_tracking_admin_write on public.redlight_order_tracking for all
  using (public.redlight_is_admin())
  with check (public.redlight_is_admin());

-- Istorik etap yo (checkpoint / anprevu) — timeline pou kliyan an.
create table if not exists public.redlight_order_tracking_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.redlight_orders(id) on delete cascade,
  kind text not null default 'checkpoint'
    check (kind in ('checkpoint', 'delay')),
  location text,
  note text,
  latitude double precision,
  longitude double precision,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists redlight_order_tracking_events_order_idx
  on public.redlight_order_tracking_events(order_id, created_at desc);

alter table public.redlight_order_tracking_events enable row level security;

drop policy if exists redlight_tracking_events_read on public.redlight_order_tracking_events;
drop policy if exists redlight_tracking_events_admin_write on public.redlight_order_tracking_events;

create policy redlight_tracking_events_read on public.redlight_order_tracking_events for select using (
  public.redlight_is_admin()
  or exists(
    select 1 from public.redlight_orders o
    where o.id = order_id and o.user_id = auth.uid()
  )
);
create policy redlight_tracking_events_admin_write on public.redlight_order_tracking_events for all
  using (public.redlight_is_admin())
  with check (public.redlight_is_admin());

commit;
