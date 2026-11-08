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

## Build the APK in the cloud (no Flutter install needed)

GitHub builds the signed APK for you every time you push to `main`.

1. Push the project: `git push -u origin main`
2. In the GitHub repo open **Settings → Secrets and variables → Actions → New repository secret**
   and add two secrets: `SUPABASE_URL` and `SUPABASE_ANON_KEY` (Supabase → Project Settings → API).
3. Open the **Actions** tab, choose **Build Android APK**, and click **Run workflow**
   (it also runs on every push). It takes about 10 minutes.
4. When it is green, open the repo's **Releases** page on your Android phone, tap `daily-cash.apk`,
   then open the file to install. If Android warns, tap More details, then Install anyway.

Signing: with no signing secrets, each build uses a temporary key, so a newer build will not
install over an older one (uninstall first; your entries are safe once synced). For a permanent
key, create a keystore once, then add `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` and
`KEY_PASSWORD` as secrets. Keep the repo private if you do this. A red build shows the exact
error in the log.

## Build the APK on your own computer

See `android_setup/ANDROID_RELEASE.md` (custom keystore, signed release build, permission check).
Build command with your keys:

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json
```

## Tests

```bash
flutter test
```

## Download page (docs/)

A one page site where your client downloads the APK. The APK file lives in Supabase Storage and
the page is hosted free on GitHub Pages. Supabase serves HTML files as plain text, so the page
itself cannot be hosted there.

1. **Upload the APK.** Supabase → SQL Editor → run `supabase/releases_bucket.sql`
   (or Storage → New bucket → name `releases`, Public on). Upload your
   `app-arm64-v8a-release.apk` as `daily-cash.apk`. The free plan allows files up to 50 MB.
2. **Point the page at it.** Open `docs/config.js` and set `apkUrl` to
   `https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/releases/daily-cash.apk`.
   Optional: add `version` and the output of `sha256sum daily-cash.apk` as `sha256`.
   Until `apkUrl` is set, the download buttons show as disabled ("Download link coming soon").
3. **Publish the page.** GitHub repo → Settings → Pages → Deploy from a branch →
   `main` and the `/docs` folder. The page appears at `https://TakbirZaman.github.io/Daily-Cash/`.
4. **Fill the placeholders.** Replace `{{contact_email}}` and `{{owner_name}}` in
   `docs/privacy.html` and `docs/terms.html`, and have both pages reviewed.
5. **Optional.** Social previews need an absolute image link: change `og:image` in
   `docs/index.html` to `https://TakbirZaman.github.io/Daily-Cash/og.png`.

To ship an update, upload the new APK under a new name (for example `daily-cash-1.0.1.apk`)
and change `apkUrl`. Public files are cached, so a new name avoids people getting the old file.
