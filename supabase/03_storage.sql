-- ============================================================
-- REDLIGHT AUTOPARTS — 03_storage.sql
-- Buckets 'redlight-product-images' & 'redlight-payment-logos': lekti piblik, ekriti sèlman admin.
-- ============================================================

insert into storage.buckets (id, name, public)
values ('redlight-product-images', 'redlight-product-images', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('redlight-payment-logos', 'redlight-payment-logos', true, 2097152, array['image/png','image/jpeg','image/webp'])
on conflict (id) do nothing;

-- Tout moun ka li imaj yo (bucket piblik)
drop policy if exists "redlight_product_images_read" on storage.objects;
create policy "redlight_product_images_read"
  on storage.objects for select
  using (bucket_id in ('redlight-product-images', 'product-images'));

-- Sèlman admin ka upload / modifye / efase
drop policy if exists "redlight_product_images_admin_insert" on storage.objects;
create policy "redlight_product_images_admin_insert"
  on storage.objects for insert
  with check (bucket_id in ('redlight-product-images', 'product-images') and public.redlight_is_admin());

drop policy if exists "redlight_product_images_admin_update" on storage.objects;
create policy "redlight_product_images_admin_update"
  on storage.objects for update
  using (bucket_id in ('redlight-product-images', 'product-images') and public.redlight_is_admin())
  with check (bucket_id in ('redlight-product-images', 'product-images') and public.redlight_is_admin());

drop policy if exists "redlight_product_images_admin_delete" on storage.objects;
create policy "redlight_product_images_admin_delete"
  on storage.objects for delete
  using (bucket_id in ('redlight-product-images', 'product-images') and public.redlight_is_admin());

drop policy if exists "redlight_payment_logos_read" on storage.objects;
create policy "redlight_payment_logos_read"
  on storage.objects for select
  using (bucket_id in ('redlight-payment-logos', 'payment-logos'));

drop policy if exists "redlight_payment_logos_admin_insert" on storage.objects;
create policy "redlight_payment_logos_admin_insert"
  on storage.objects for insert
  with check (bucket_id in ('redlight-payment-logos', 'payment-logos') and public.redlight_is_admin());

drop policy if exists "redlight_payment_logos_admin_update" on storage.objects;
create policy "redlight_payment_logos_admin_update"
  on storage.objects for update
  using (bucket_id in ('redlight-payment-logos', 'payment-logos') and public.redlight_is_admin())
  with check (bucket_id in ('redlight-payment-logos', 'payment-logos') and public.redlight_is_admin());
