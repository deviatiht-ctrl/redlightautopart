begin;

-- ============================================================
-- REDLIGHT AUTOPARTS — 10_payment_verification.sql
-- Verifikasyon peman ki pa bloke sou PAYMENT_MISMATCH
-- ============================================================

alter table public.redlight_payments add column if not exists provider_transaction_id text;
alter table public.redlight_payments add column if not exists provider_status text;
alter table public.redlight_payments add column if not exists provider_method text;
alter table public.redlight_payments add column if not exists paid_amount numeric(10,2);
alter table public.redlight_payments add column if not exists last_error text;
alter table public.redlight_payments add column if not exists verify_attempts integer not null default 0;

create table if not exists public.redlight_payment_checks (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.redlight_payments(order_id) on delete cascade,
  reference text not null,
  source text not null check (source in ('client','webhook','cron','start','admin')),
  result text not null check (result in ('paid','pending','failed','mismatch','error')),
  provider_status text,
  transaction_id text,
  amount numeric(10,2),
  method text,
  error text,
  raw jsonb,
  created_at timestamptz not null default now()
);
create index if not exists redlight_payment_checks_order_idx on public.redlight_payment_checks(order_id, created_at desc);
create index if not exists redlight_payment_checks_transaction_idx on public.redlight_payment_checks(transaction_id);
alter table public.redlight_payment_checks enable row level security;
drop policy if exists redlight_payment_checks_admin_read on public.redlight_payment_checks;
create policy redlight_payment_checks_admin_read on public.redlight_payment_checks for select using (public.redlight_is_admin());

create or replace function public.redlight_apply_payment(
  p_reference text,
  p_transaction text,
  p_amount numeric,
  p_paid boolean,
  p_provider_status text default null,
  p_method text default null,
  p_source text default 'client',
  p_raw jsonb default null
)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_payment public.redlight_payments%rowtype;
  v_tx text := nullif(trim(coalesce(p_transaction, '')), '');
  v_provider_status text := nullif(lower(trim(coalesce(p_provider_status, ''))), '');
  v_source text := case when p_source in ('client','webhook','cron','start','admin') then p_source else 'client' end;
  v_result text;
  v_error text;
  v_status text;
begin
  select * into v_payment from public.redlight_payments where reference = p_reference for update;
  if not found then raise exception 'payment_not_found'; end if;

  if v_tx is not null and exists(select 1 from public.redlight_payments where transaction_id = v_tx and order_id <> v_payment.order_id) then
    v_result := 'mismatch'; v_error := 'TRANSACTION_ID_USED_BY_OTHER_ORDER'; v_tx := null;
  elsif p_paid and (p_amount is null or round(p_amount, 2) <> round(v_payment.amount, 2)) then
    v_result := 'mismatch'; v_error := 'AMOUNT_MISMATCH';
  elsif p_paid then
    v_result := 'paid';
  elsif v_provider_status in ('failed','fail','echec','error','cancelled','canceled','rejected') then
    v_result := 'failed';
  else
    v_result := 'pending';
  end if;

  update public.redlight_payments set
    transaction_id = coalesce(v_tx, transaction_id),
    provider_transaction_id = coalesce(provider_transaction_id, v_tx),
    provider_status = v_provider_status,
    provider_method = coalesce(nullif(trim(coalesce(p_method, '')), ''), provider_method),
    paid_amount = coalesce(p_amount, paid_amount),
    status = case
      when v_result = 'paid' then 'paid'
      when v_result = 'mismatch' then 'review'
      when status in ('paid','review') then 'review'
      else 'pending' end,
    last_error = v_error,
    last_verified_at = now(),
    verify_attempts = verify_attempts + 1
  where order_id = v_payment.order_id
  returning status into v_status;

  update public.redlight_orders set
    payment_status = v_status,
    status = case when v_status = 'paid' and status = 'pending' then 'confirmed' else status end
  where id = v_payment.order_id;

  insert into public.redlight_payment_checks(order_id, reference, source, result, provider_status, transaction_id, amount, method, error, raw)
  values (v_payment.order_id, v_payment.reference, v_source, v_result, v_provider_status,
          nullif(trim(coalesce(p_transaction, '')), ''), p_amount, p_method, v_error, p_raw);

  return v_result;
end;
$$;
revoke all on function public.redlight_apply_payment(text,text,numeric,boolean,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.redlight_apply_payment(text,text,numeric,boolean,text,text,text,jsonb) to service_role;

commit;
