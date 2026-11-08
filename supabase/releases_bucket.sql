-- Run once in Supabase → SQL Editor. Creates a public bucket for the APK.
-- Public means anyone with the link can download. Nobody can upload or list files
-- from the app: uploads happen only from your Supabase dashboard.
insert into storage.buckets (id, name, public)
values ('releases', 'releases', true)
on conflict (id) do nothing;
