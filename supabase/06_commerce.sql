begin;
create extension if not exists pgcrypto;

alter table public.redlight_products alter column is_demo set default false;
drop policy if exists redlight_products_read_all on public.redlight_products;
create policy redlight_products_read_all on public.redlight_products for select using (true);

create table if not exists public.redlight_payment_methods (
  code text primary key check (code in ('moncash','moncash_ussd','natcash','kashpaw','carte','all')),
  name text not null,
  logo_url text check (logo_url is null or logo_url ~ '^https?://'),
  enabled boolean not null default false,
  sort_order integer not null default 0
);
insert into public.redlight_payment_methods(code,name,sort_order) values
  ('moncash','MonCash',1),('moncash_ussd','MonCash USSD',2),
  ('natcash','NatCash',3),('kashpaw','KashPaw',4),('carte','Carte / Square',5),('all','PLOP PLOP',6)
on conflict(code) do nothing;
alter table public.redlight_payment_methods enable row level security;
drop policy if exists redlight_payment_methods_read on public.redlight_payment_methods;
drop policy if exists redlight_payment_methods_admin on public.redlight_payment_methods;
create policy redlight_payment_methods_read on public.redlight_payment_methods for select using (true);
create policy redlight_payment_methods_admin on public.redlight_payment_methods for all using (public.redlight_is_admin()) with check (public.redlight_is_admin());

create table if not exists public.redlight_legal_documents (
  kind text not null check (kind in ('terms','privacy','support')),
  locale text not null check (locale in ('fr','ht','en','es')),
  title text not null,
  body text not null,
  updated_at timestamptz not null default now(),
  primary key(kind,locale)
);
alter table public.redlight_legal_documents enable row level security;
drop policy if exists redlight_legal_read on public.redlight_legal_documents;
drop policy if exists redlight_legal_admin on public.redlight_legal_documents;
create policy redlight_legal_read on public.redlight_legal_documents for select using (true);
create policy redlight_legal_admin on public.redlight_legal_documents for all using (public.redlight_is_admin()) with check (public.redlight_is_admin());

alter table public.redlight_orders add column if not exists checkout_key uuid;
alter table public.redlight_orders add column if not exists payment_status text not null default 'unpaid';
create unique index if not exists redlight_orders_checkout_unique on public.redlight_orders(user_id,checkout_key);

create table if not exists public.redlight_payments (
  order_id uuid primary key references public.redlight_orders(id),
  reference text not null unique,
  transaction_id text unique,
  amount numeric(10,2) not null check(amount >= 20),
  method text not null references public.redlight_payment_methods(code),
  status text not null default 'creating' check(status in ('creating','pending','paid','review')),
  redirect_url text,
  last_verified_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.redlight_payments enable row level security;
drop policy if exists redlight_payments_read on public.redlight_payments;
create policy redlight_payments_read on public.redlight_payments for select using (
  public.redlight_is_admin() or exists(select 1 from public.redlight_orders o where o.id = order_id and o.user_id = auth.uid())
);

create table if not exists public.redlight_merchant_withdrawals (
  reference uuid primary key default gen_random_uuid(),
  admin_id uuid not null references auth.users(id),
  amount numeric(10,2) not null check(amount > 0),
  method text not null check(method in ('moncash','natcash')),
  recipient text not null check(recipient ~ '^509[0-9]{8}$'),
  status text not null default 'prepared' check(status in ('prepared','processing','pending','success','failed','remboursé')),
  transaction_id text,
  error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.redlight_merchant_withdrawals enable row level security;
drop policy if exists redlight_withdrawals_admin_read on public.redlight_merchant_withdrawals;
create policy redlight_withdrawals_admin_read on public.redlight_merchant_withdrawals for select using(public.redlight_is_admin());

create or replace function public.redlight_checkout_order(p_items jsonb,p_delivery_address text,p_payment_method text,p_checkout_key uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
  v_item record;
  v_product public.redlight_products%rowtype;
  v_total numeric := 0;
begin
  if auth.uid() is null or coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise exception 'authentication_required'; end if;
  if p_checkout_key is null then raise exception 'invalid_checkout_key'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,0));
  select id into v_id from public.redlight_orders where user_id = auth.uid() and checkout_key = p_checkout_key;
  if found then return v_id; end if;
  if (select count(*) from public.redlight_orders where user_id = auth.uid() and status = 'pending') >= 5 then raise exception 'pending_order_limit'; end if;
  if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) not between 1 and 100 then raise exception 'invalid_items'; end if;
  if length(trim(p_delivery_address)) not between 5 and 1000 or p_delivery_address is null then raise exception 'invalid_address'; end if;
  if not exists(select 1 from public.redlight_payment_methods where code = p_payment_method and enabled) then raise exception 'payment_method_disabled'; end if;
  insert into public.redlight_orders(user_id,total,delivery_address,payment_method,checkout_key)
  values(auth.uid(),0,trim(p_delivery_address),p_payment_method,p_checkout_key) returning id into v_id;
  for v_item in
    select (x->>'product_id')::uuid as pid, sum((x->>'quantity')::numeric) as qty
    from jsonb_array_elements(p_items) x group by 1 order by 1
  loop
    if v_item.qty is null or v_item.qty <> trunc(v_item.qty) or v_item.qty not between 1 and 999 then raise exception 'invalid_quantity'; end if;
    select * into v_product from public.redlight_products where id = v_item.pid and is_demo = false for update;
    if not found or v_product.price <= 0 then raise exception 'product_not_found'; end if;
    if v_product.stock < v_item.qty then raise exception 'insufficient_stock'; end if;
    update public.redlight_products set stock = stock - v_item.qty::int where id = v_item.pid;
    insert into public.redlight_order_items(order_id,product_id,quantity,unit_price) values(v_id,v_item.pid,v_item.qty::int,v_product.price);
    v_total := v_total + v_product.price * v_item.qty;
  end loop;
  if v_total < 20 then raise exception 'minimum_amount_20'; end if;
  update public.redlight_orders set total = v_total where id = v_id;
  return v_id;
end;
$$;
revoke all on function public.redlight_checkout_order(jsonb,text,text,uuid) from public,anon;
grant execute on function public.redlight_checkout_order(jsonb,text,text,uuid) to authenticated;

create or replace function public.redlight_claim_payment(p_order_id uuid)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_order public.redlight_orders%rowtype;
begin
  select * into v_order from public.redlight_orders where id = p_order_id for update;
  if not found or v_order.status <> 'pending' or v_order.payment_status <> 'unpaid' then return false; end if;
  insert into public.redlight_payments(order_id,reference,amount,method) values(v_order.id,'PAY-' || v_order.id,v_order.total,v_order.payment_method) on conflict(order_id) do nothing;
  return found;
end;
$$;
revoke all on function public.redlight_claim_payment(uuid) from public,anon,authenticated;
grant execute on function public.redlight_claim_payment(uuid) to service_role;

create or replace function public.redlight_change_order_status(p_order_id uuid,p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare v_order public.redlight_orders%rowtype;
begin
  select * into v_order from public.redlight_orders where id = p_order_id for update;
  if not found or auth.uid() is null or (v_order.user_id is distinct from auth.uid() and not public.redlight_is_admin()) then raise exception 'access_denied'; end if;
  if p_status = v_order.status then return; end if;
  if p_status = 'cancelled' then
    if v_order.status <> 'pending'
       or exists(select 1 from public.redlight_payments where order_id = p_order_id and transaction_id is not null)
    then raise exception 'payment_reconciliation_required'; end if;
    update public.redlight_products p set stock = p.stock + i.quantity from public.redlight_order_items i where i.order_id = p_order_id and i.product_id = p.id;
  elsif not public.redlight_is_admin() or v_order.payment_status <> 'paid' or not (
    (v_order.status = 'confirmed' and p_status = 'shipped') or (v_order.status = 'shipped' and p_status = 'delivered')
      or (v_order.status = 'cancelled' and p_status = 'cancelled')
  ) then raise exception 'invalid_transition';
  end if;
  update public.redlight_orders set status = p_status where id = p_order_id;
end;
$$;
revoke all on function public.redlight_change_order_status(uuid,text) from public,anon;
grant execute on function public.redlight_change_order_status(uuid,text) to authenticated;

create or replace function public.redlight_claim_withdrawal(p_reference uuid)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  perform pg_advisory_xact_lock(73489125);
  if exists(select 1 from public.redlight_merchant_withdrawals where status <> 'prepared' and updated_at > now() - interval '120 seconds') then raise exception 'WITHDRAWAL_COOLDOWN'; end if;
  update public.redlight_merchant_withdrawals set status = 'processing',updated_at = now() where reference = p_reference and status = 'prepared' and created_at > now() - interval '10 minutes';
  return found;
end;
$$;
revoke all on function public.redlight_claim_withdrawal(uuid) from public,anon,authenticated;
grant execute on function public.redlight_claim_withdrawal(uuid) to service_role;

commit;
