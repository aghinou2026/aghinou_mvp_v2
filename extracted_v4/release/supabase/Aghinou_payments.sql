-- Aghinou real payment ledger for the monthly base subscription.
-- Amount is stored in Rial: 35,000 Toman = 350,000 Rial.
-- The Edge Function is the only writer; users can only read their own rows.

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount bigint not null,
  plan text not null default 'base_monthly',
  authority text unique,
  ref_id bigint,
  status text not null default 'pending'
    check (status in ('pending','paid','failed','cancelled')),
  subscription_expires_at timestamptz,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

create index if not exists payments_user_id_idx
  on public.payments(user_id);

create index if not exists payments_authority_idx
  on public.payments(authority);

alter table public.payments enable row level security;

drop policy if exists "Users can read own payments" on public.payments;

create policy "Users can read own payments"
on public.payments
for select
to authenticated
using (auth.uid() = user_id);
