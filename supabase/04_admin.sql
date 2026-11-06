-- ============================================================
-- REDLIGHT AUTOPARTS — 04_admin.sql
-- Lis administratè Redlight ki gen aksè konplè nan Dashboard & DB.
-- ============================================================

insert into redlight_admin_users (email)
values 
  ('laurorejeanclarens0@gmail.com'),
  ('redlightautomotive945@gmail.com')
on conflict (email) do nothing;
