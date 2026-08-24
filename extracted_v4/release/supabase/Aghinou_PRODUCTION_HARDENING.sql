-- Aghinou production hardening (v4)
-- Preserves existing Profiles, Ads and Ad Images tables.
-- Adds the payment ledger and server-side publication enforcement.

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount bigint not null check (amount > 0),
  plan text not null default 'base_monthly',
  authority text unique,
  ref_id bigint,
  status text not null default 'pending' check (status in ('pending','paid','failed','cancelled')),
  subscription_expires_at timestamptz,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

create index if not exists payments_user_id_idx on public.payments(user_id);
create index if not exists payments_active_lookup_idx on public.payments(user_id, status, subscription_expires_at);
create index if not exists ads_seller_id_idx on public.ads(seller_id);

alter table public.payments enable row level security;
drop policy if exists "Users can read own payments" on public.payments;
create policy "Users can read own payments" on public.payments
for select to authenticated using ((select auth.uid()) = user_id);
revoke insert, update, delete on public.payments from anon, authenticated;
grant select on public.payments to authenticated;

create or replace function public.publish_ad(
  p_title text,
  p_description text,
  p_price bigint,
  p_city text,
  p_category text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_ad_count integer;
  v_ad_id uuid;
begin
  if v_user_id is null then raise exception 'AUTH_REQUIRED'; end if;
  if not exists (
    select 1 from public.payments
    where user_id = v_user_id and status = 'paid' and subscription_expires_at > now()
  ) then raise exception 'SUBSCRIPTION_REQUIRED'; end if;
  select count(*)::integer into v_ad_count from public.ads where seller_id = v_user_id;
  if v_ad_count >= 9 then raise exception 'AD_LIMIT_REACHED'; end if;
  if length(trim(coalesce(p_title, ''))) < 3 then raise exception 'INVALID_TITLE'; end if;
  if length(trim(coalesce(p_description, ''))) < 5 then raise exception 'INVALID_DESCRIPTION'; end if;
  if p_price < 0 then raise exception 'INVALID_PRICE'; end if;

  insert into public.ads (seller_id, title, edescriptions, price, city, category)
  values (v_user_id, trim(p_title), trim(p_description), p_price, trim(p_city), trim(p_category))
  returning idd into v_ad_id;
  return v_ad_id;
end;
$$;

revoke all on function public.publish_ad(text,text,bigint,text,text) from public;
grant execute on function public.publish_ad(text,text,bigint,text,text) to authenticated;

alter table public.ads enable row level security;
alter table public.ad_images enable row level security;

drop policy if exists "Authenticated users can create own ads" on public.ads;
drop policy if exists "Users can insert own ads" on public.ads;
drop policy if exists "Users can update own ads" on public.ads;
drop policy if exists "Users can delete own ads" on public.ads;
create policy "Users can update own ads" on public.ads for update to authenticated
using ((select auth.uid()) = seller_id)
with check ((select auth.uid()) = seller_id);
create policy "Users can delete own ads" on public.ads for delete to authenticated
using ((select auth.uid()) = seller_id);

drop policy if exists "Ad owners can add ad images" on public.ad_images;
drop policy if exists "Ad owners can delete ad images" on public.ad_images;
create policy "Ad owners can add ad images" on public.ad_images for insert to authenticated
with check (exists (select 1 from public.ads a where a.idd = ad_images.ad_id and a.seller_id = (select auth.uid())));
create policy "Ad owners can delete ad images" on public.ad_images for delete to authenticated
using (exists (select 1 from public.ads a where a.idd = ad_images.ad_id and a.seller_id = (select auth.uid())));

-- Existing public bucket name is exactly `ad-images`.
drop policy if exists "Users can upload own ad images" on storage.objects;
drop policy if exists "Users can delete own ad images" on storage.objects;
drop policy if exists "Users can upload own Aghinou ad images" on storage.objects;
drop policy if exists "Users can delete own Aghinou ad images" on storage.objects;
create policy "Users can upload own Aghinou ad images" on storage.objects for insert to authenticated
with check (bucket_id = 'ad-images' and (storage.foldername(name))[1] = (select auth.uid()::text));
create policy "Users can delete own Aghinou ad images" on storage.objects for delete to authenticated
using (bucket_id = 'ad-images' and (storage.foldername(name))[1] = (select auth.uid()::text));

drop policy if exists "Public can read Aghinou ad images" on storage.objects;
create policy "Public can read Aghinou ad images" on storage.objects for select to anon, authenticated
using (bucket_id = 'ad-images');
