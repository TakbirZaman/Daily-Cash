-- Daily Cash: complete Supabase setup. Paste this whole file into SQL Editor and click Run.

-- Run this once in Supabase → SQL Editor → New query.

create table if not exists public.transactions (
  id          uuid primary key,                       -- created on the phone, so offline entries work
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,
  amount      numeric(14, 2) not null check (amount > 0),
  type        text not null check (type in ('income', 'expense')),
  note        text not null default '',
  created_at  timestamptz not null,                   -- the automatic date/time of the entry
  updated_at  timestamptz not null default now()
);

create index if not exists transactions_user_created_idx
  on public.transactions (user_id, created_at desc);

-- Each user can only ever touch their own rows.
alter table public.transactions enable row level security;

create policy "read own"   on public.transactions
  for select using (auth.uid() = user_id);
create policy "insert own" on public.transactions
  for insert with check (auth.uid() = user_id);
create policy "update own" on public.transactions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own" on public.transactions
  for delete using (auth.uid() = user_id);

-- Public bucket for the APK download page (optional).
insert into storage.buckets (id, name, public)
values ('releases', 'releases', true)
on conflict (id) do nothing;
