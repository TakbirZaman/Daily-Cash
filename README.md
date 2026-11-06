# Daily Cash

1. `flutter create . --org com.dailycash --project-name daily_cash`  (run inside this folder)
2. Add your Firebase app:
   - Android: put `google-services.json` in `android/app/`
   - iOS: put `GoogleService-Info.plist` in `ios/Runner/`
   - Or run `flutterfire configure` and use `Firebase.initializeApp(options: ...)`
3. Firebase Console: enable **Authentication > Email/Password**, create **Firestore**, paste `firestore.rules`.
4. `flutter pub get && flutter run`
