-- ============================================================
-- REDLIGHT AUTOPARTS — 02_rls.sql
-- Row Level Security + fonksyon redlight_is_admin() + redlight_place_order().
-- ============================================================

alter table redlight_categories  enable row level security;
alter table redlight_products    enable row level security;
alter table redlight_orders      enable row level security;
alter table redlight_order_items enable row level security;
alter table redlight_admin_users enable row level security;

-- ------------------------------------------------------------
-- redlight_is_admin() — true si email itilizatè konekte a nan redlight_admin_users.
-- ------------------------------------------------------------
create or replace function public.redlight_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.redlight_admin_users
    where lower(email) = lower(auth.jwt() ->> 'email')
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.redlight_is_admin();
$$;

-- ------------------------------------------------------------
-- redlight_categories / redlight_products : tout moun ka li, sèlman admin ka ekri
-- ------------------------------------------------------------
drop policy if exists "redlight_categories_read_all" on redlight_categories;
create policy "redlight_categories_read_all"
  on redlight_categories for select using (true);

drop policy if exists "redlight_categories_admin_write" on redlight_categories;
create policy "redlight_categories_admin_write"
  on redlight_categories for all
  using (public.redlight_is_admin())
  with check (public.redlight_is_admin());

drop policy if exists "redlight_products_read_all" on redlight_products;
create policy "redlight_products_read_all"
  on redlight_products for select using (true);

drop policy if exists "redlight_products_admin_write" on redlight_products;
create policy "redlight_products_admin_write"
  on redlight_products for all
  using (public.redlight_is_admin())
  with check (public.redlight_is_admin());

-- ------------------------------------------------------------
-- redlight_orders : pwopriyetè ka li / kreye / kansèle (pending -> cancelled)
--                   admin ka fè tout bagay
-- ------------------------------------------------------------
drop policy if exists "redlight_orders_owner_read" on redlight_orders;
create policy "redlight_orders_owner_read"
  on redlight_orders for select
  using (auth.uid() = user_id);

drop policy if exists "redlight_orders_owner_insert" on redlight_orders;
create policy "redlight_orders_owner_insert"
  on redlight_orders for insert
  with check (auth.uid() = user_id);

drop policy if exists "redlight_orders_owner_cancel" on redlight_orders;
create policy "redlight_orders_owner_cancel"
  on redlight_orders for update
  using (auth.uid() = user_id and status = 'pending')
  with check (auth.uid() = user_id and status = 'cancelled');

drop policy if exists "redlight_orders_admin_all" on redlight_orders;
create policy "redlight_orders_admin_all"
  on redlight_orders for all
  using (public.redlight_is_admin())
  with check (public.redlight_is_admin());

-- ------------------------------------------------------------
-- redlight_order_items : aksè atravè kòmand paran an
-- ------------------------------------------------------------
drop policy if exists "redlight_order_items_owner_read" on redlight_order_items;
create policy "redlight_order_items_owner_read"
  on redlight_order_items for select
  using (exists (
    select 1 from redlight_orders o
    where o.id = redlight_order_items.order_id and o.user_id = auth.uid()
  ));

drop policy if exists "redlight_order_items_owner_insert" on redlight_order_items;
create policy "redlight_order_items_owner_insert"
  on redlight_order_items for insert
  with check (exists (
    select 1 from redlight_orders o
    where o.id = redlight_order_items.order_id and o.user_id = auth.uid()
  ));

drop policy if exists "redlight_order_items_admin_all" on redlight_order_items;
create policy "redlight_order_items_admin_all"
  on redlight_order_items for all
  using (public.redlight_is_admin())
  with check (public.redlight_is_admin());

-- ------------------------------------------------------------
-- redlight_admin_users : sèlman admin ka li lis la
-- ------------------------------------------------------------
drop policy if exists "redlight_admin_users_admin_read" on redlight_admin_users;
create policy "redlight_admin_users_admin_read"
  on redlight_admin_users for select
  using (public.redlight_is_admin());

-- ------------------------------------------------------------
-- redlight_place_order() — kòmand atomik
-- ------------------------------------------------------------
create or replace function public.redlight_place_order(
  p_items jsonb,
  p_total numeric,
  p_delivery_address text,
  p_payment_method text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_id uuid;
  v_item jsonb;
  v_stock int;
  v_pid uuid;
  v_qty int;
begin
  insert into redlight_orders (user_id, total, delivery_address, payment_method)
  values (auth.uid(), p_total, p_delivery_address, p_payment_method)
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_pid := (v_item ->> 'product_id')::uuid;
    v_qty := (v_item ->> 'quantity')::int;

    select stock into v_stock
    from redlight_products where id = v_pid
    for update;

    if v_stock is null then
      raise exception 'product_not_found: %', v_pid;
    end if;
    if v_stock < v_qty then
      raise exception 'insufficient_stock: %', v_pid;
    end if;

    update redlight_products set stock = stock - v_qty where id = v_pid;

    insert into redlight_order_items (order_id, product_id, quantity, unit_price)
    values (v_order_id, v_pid, v_qty, (v_item ->> 'unit_price')::numeric);
  end loop;

  return v_order_id;
end;
$$;
