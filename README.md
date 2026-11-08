# Daily Cash

A personal daily ledger for Android. Flutter app, Supabase backend (login + database).
Works fully offline: entries are saved on the phone first and synced when the internet returns.

## Architecture

Views talk only to controllers, controllers talk only to services, and services are the only
code that touches Supabase or the disk. The phone keeps its own copy of the data and a queue of
unsent changes, so the app never waits on the network.

```
lib/
├── core/        theme tokens, palette, shared widgets, strings (English + Bangla), config
├── models/      TransactionModel
├── services/    auth_service, ledger_service (offline queue + sync), export_service
├── controllers/ auth, dashboard, calendar, report, history
└── views/       auth, dashboard, calendar, report, history, settings
supabase/schema.sql   database table + row level security
```

## How to run

```bash
# 1. Create the Android/iOS folders (one time)
flutter create . --org com.dailycash --project-name daily_cash

# 2. Add your Supabase keys (never commit this file)
cp dart_defines.example.json dart_defines.json      # then edit the two values

# 3. Install and run
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

## Supabase setup (one time)

1. Create a project at supabase.com. Pick the region closest to your users (Singapore for Bangladesh).
2. **SQL Editor → New query**, paste `supabase/schema.sql`, click Run.
3. **Authentication → Providers → Email**: turn **Confirm email** OFF.
   If it stays on, new users cannot log in until they click a link, which breaks the sign up flow.
4. **Authentication → Email Templates → Reset Password**: replace the body with
   `<h2>Reset your password</h2><p>Your code: <strong>{{ .Token }}</strong></p>`
   The app uses this 6 digit code, so no web page or deep link is needed.
5. **Project Settings → API**: copy the **Project URL** and the **anon public** key into
   `dart_defines.json`. Never put the `service_role` key in the app.

## Build the APK

See `android_setup/ANDROID_RELEASE.md` (custom keystore, signed release build, permission check).
Build command with your keys:

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json
```

## Tests

```bash
flutter test
```
