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
- In `android/settings.gradle.kts` plugins block, make sure this exists:
      id("com.google.gms.google-services") version "4.4.2" apply false
- Put `google-services.json` in `android/app/`.

## 5. Build
    flutter clean
    flutter pub get
    flutter build apk --release --split-per-abi

Send the client:  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
(Play Store instead:  flutter build appbundle --release  ->  build/app/outputs/bundle/release/app-release.aab)

## 6. Verify
    apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
    aapt2 dump permissions build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

`apksigner` and `aapt2` live in `$ANDROID_HOME/build-tools/<version>/`.
The signer must show your certificate, not "Android Debug".

## Note on new packages (v3)
Export uses `share_plus` and `path_provider`. They need NO extra permissions; the
share plugin adds an internal FileProvider entry that is merged automatically.
The permission list should still be INTERNET (+ the harmless Firebase/AndroidX ones).
Re-run the `aapt2 dump permissions` check after your first v3 build.
