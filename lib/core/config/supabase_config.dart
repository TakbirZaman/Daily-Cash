/// Paste your project's values here (Supabase → Project Settings → API),
/// or pass them at build time:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// The anon key is designed to be public: your data is protected by the
/// row-level-security rules in supabase/schema.sql, not by hiding this key.
/// Never put the "service_role" key in the app.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_ID.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      !url.contains('YOUR_PROJECT_ID') && !anonKey.contains('YOUR_SUPABASE');
}
