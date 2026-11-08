# Daily Cash: Safe Android Release Build

## 1. Manifest
Replace `android/app/src/main/AndroidManifest.xml` with `AndroidManifest.xml` from this folder.
Only INTERNET is declared.

## 2. Create the keystore (once, keep it forever)
Linux/macOS:
    mkdir -p ~/keys
    keytool -genkey -v -keystore ~/keys/daily-cash-upload.jks -storetype JKS \
      -keyalg RSA -keysize 2048 -validity 10000 -alias upload

Windows PowerShell:
    keytool -genkey -v -keystore $env:USERPROFILE\keys\daily-cash-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

Back the .jks and its passwords up somewhere safe. Lose it and you can never update the app.

## 3. key.properties
Copy `key.properties.example` to `android/key.properties`, fill in the real values.
Add the lines from `gitignore_additions.txt` to `android/.gitignore`.

## 4. Gradle
- Replace `android/app/build.gradle.kts` with `build.gradle.kts` from this folder.
- Create an empty rules file:  `touch android/app/proguard-rules.pro`
- No Google services plugin or `google-services.json` is needed (the backend is Supabase).

## 5. Build
    flutter clean
    flutter pub get
    flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json

Send the client:  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
(Play Store instead:  flutter build appbundle --release  ->  build/app/outputs/bundle/release/app-release.aab)

## 6. Verify
    apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
    aapt2 dump permissions build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

`apksigner` and `aapt2` live in `$ANDROID_HOME/build-tools/<version>/`.
The signer must show your certificate, not "Android Debug".

## Permissions
The app needs INTERNET only. Export uses `share_plus` and `path_provider`, which add no
permissions (the share plugin merges an internal FileProvider entry). Re-run the
`aapt2 dump permissions` check after your first build.
