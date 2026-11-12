# Daily Cash

[![Download APK](https://img.shields.io/badge/Download-APK-blue?style=for-the-badge&logo=android)](https://takbirzaman.github.io/Daily-Cash/)
[![Latest release](https://img.shields.io/github/v/release/TakbirZaman/Daily-Cash?label=release)](https://github.com/TakbirZaman/Daily-Cash/releases/latest)
[![Build](https://img.shields.io/github/actions/workflow/status/TakbirZaman/Daily-Cash/build-apk.yml?label=CI)](https://github.com/TakbirZaman/Daily-Cash/actions)

**→ Download the app: https://takbirzaman.github.io/Daily-Cash/**

A personal daily ledger for Android. Flutter app, Supabase backend (auth + Postgres with row
level security). Fully offline-first: entries are written to the phone first, queued, and synced
to Supabase when connectivity returns. The UI is never blocked on the network.

## Architecture

Strict layering — dependencies point one way only: `views → controllers → services → Supabase/disk`.
Views contain no business logic; services are the only code that touches Supabase or the file
system; a local write-ahead queue guarantees durable offline writes and replay in order.

```
lib/
├── core/        design tokens, palette, shared widgets, l10n (English + Bangla), config
├── models/      TransactionModel
├── services/    auth_service, ledger_service (offline queue + sync), export_service
├── controllers/ auth, dashboard, calendar, report, history
└── views/       auth, dashboard, calendar, report, history, settings
supabase/schema.sql   table definitions + row level security policies
```

Key properties:

- **Offline-first sync** — local writes are acknowledged immediately; a mutation queue drains to
  Supabase when online. No data loss on flaky connections.
- **Row level security** — every row in `public.transactions` is scoped to `auth.uid()`; the
  publishable key is the only credential shipped in the binary.
- **Exports** — PDF (monthly statement) and Excel, rendered on-device, shared via the OS share
  sheet.
- **i18n** — English and Bangla, with Bangla numeral formatting for money.

## Install (end users)

1. Open the [download page](https://takbirzaman.github.io/Daily-Cash/) on your phone.
2. Tap **Download APK** (the page shows the version and SHA-256 of the artifact).
3. Android will warn about unknown sources — allow the browser to install apps, then install.
4. Sign up with email + password. No email confirmation round-trip.

Minimum Android version and per-ABI builds are produced by CI (`arm64-v8a` included; the release
APK targets `armeabi-v7a` and `arm64-v8a`).

## Development

```bash
# 1. Generate the Android platform (one time)
flutter create . --org com.dailycash --project-name daily_cash --platforms android

# 2. Configure backend keys (git-ignored; never commit)
cp dart_defines.example.json dart_defines.json      # then fill in SUPABASE_URL / SUPABASE_ANON_KEY

# 3. Install, analyze, test, run
flutter pub get
flutter test
flutter run --dart-define-from-file=dart_defines.json
```

Note on dependencies: `phosphor_flutter` is vendored under `packages/phosphor_flutter` with a
patch (`tools/patch_phosphor.py`) because Flutter 3.44+ marks `IconData` as a `final` class and
the published package no longer compiles. It is wired in via `dependency_overrides`.

## Supabase setup

1. Create a project (region closest to your users — Mumbai for Bangladesh).
2. **SQL Editor** → paste `supabase/schema.sql` → Run.
3. **Authentication → Providers → Email** → **Confirm email** OFF (otherwise sign-up dead-ends).
4. **Auth → Templates → Reset Password** → include `{{ .Token }}` — the app verifies recovery
   with a 6-digit OTP (`verifyOTP(type: OtpType.recovery)`), not a deep link. Template editing
   requires a custom SMTP provider on the free tier (e.g. Gmail app password or Resend).
5. Copy **Project URL** + **anon/publishable** key into `dart_defines.json`. The `service_role`
   key never leaves the server side.

## CI/CD (GitHub Actions)

Every push to `main` runs `.github/workflows` → **Build Android APK**:

1. Checkout → JDK → Flutter stable
2. `flutter create` + `tools/patch_android.py` (INTERNET permission, app label, release signing
   from `key.properties`)
3. Analyze + tests (non-blocking) → `flutter build apk --release`
4. SHA-256 checksum → artifact upload → tagged GitHub release (`build-N`) with `daily-cash.apk`

Required secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`; optional signing secrets
`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` (without them a temporary
key is used and upgrades require uninstall — with them, releases install over each other).
The keystore is **not** in the repo; keep the base64-encoded backup somewhere safe.

One-command bootstrap (Windows): `setup.bat` — installs the GitHub CLI, creates/configures the
Supabase project, saves secrets, pushes, builds, and publishes the download page.

## Download page (`docs/`)

A single static page (GitHub Pages, `main` → `/docs`): version, SHA-256, and the APK link from
`docs/config.js` — Pages redeploys automatically on the next push.
