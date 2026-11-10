-- Optional: a public bucket if you want to host the APK on Supabase instead of GitHub Releases.
insert into storage.buckets (id, name, public)
values ('releases', 'releases', true)
on conflict (id) do nothing;
