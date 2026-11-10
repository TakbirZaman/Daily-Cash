-- Daily Cash database. Safe to run more than once.

create table if not exists public.transactions (
  id          uuid primary key,                       -- created on the phone, so offline entries work
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  amount      numeric(14, 2) not null check (amount > 0),
  type        text not null check (type in ('income', 'expense')),
  note        text not null default '',
  created_at  timestamptz not null,                   -- the automatic date and time of the entry
  updated_at  timestamptz not null default now()
);

create index if not exists transactions_user_created_idx
  on public.transactions (user_id, created_at desc);

-- Each user can only ever touch their own rows.
alter table public.transactions enable row level security;

drop policy if exists "read own" on public.transactions;
create policy "read own" on public.transactions
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "insert own" on public.transactions;
create policy "insert own" on public.transactions
  for insert to authenticated with check ((select auth.uid()) = user_id);

drop policy if exists "update own" on public.transactions;
create policy "update own" on public.transactions
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "delete own" on public.transactions;
create policy "delete own" on public.transactions
  for delete to authenticated using ((select auth.uid()) = user_id);
