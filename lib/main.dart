import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, User;

import 'controllers/auth_controller.dart';
import 'core/config/supabase_config.dart';
import 'core/l10n/strings.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/colors.dart';
import 'core/theme/tokens.dart';
import 'services/auth_service.dart';
import 'views/auth/auth_screen.dart';
import 'views/auth/name_screen.dart';
import 'views/dashboard/dashboard_screen.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Swallow framework + platform errors so the app never crashes on screen.
    FlutterError.onError = (FlutterErrorDetails _) {};
    PlatformDispatcher.instance.onError = (Object _, StackTrace __) => true;

    bool backendReady = false;
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          anonKey: SupabaseConfig.anonKey,
        );
        backendReady = true;
      } catch (_) {}
    }

    try {
      await initializeDateFormatting('en');
      await initializeDateFormatting('bn');
    } catch (_) {}

    await AppSettings.instance.load();

    runApp(backendReady ? DailyCashApp() : const _SetupNeededApp());
  }, (Object _, StackTrace __) {});
}

ThemeData _buildTheme(Brightness brightness) {
  final AppPalette pal = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Manrope',
    colorSchemeSeed: Brand.income,
    scaffoldBackgroundColor: pal.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: pal.bg,
      foregroundColor: pal.text,
      scrolledUnderElevation: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.ink,
      actionTextColor: const Color(0xFF4ADE9A),
      contentTextStyle: AppText.body5(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: Rad.all(Rad.r12)),
    ),
  );
}

class DailyCashApp extends StatelessWidget {
  DailyCashApp({super.key});

  final AuthController _auth = AuthController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (BuildContext context, Widget? _) {
        final AppSettings settings = AppSettings.instance;
        return MaterialApp(
          // A new key on language change rebuilds every screen with the new text.
          key: ValueKey<bool>(settings.isBangla),
          title: S.t('app_name'),
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: _AuthGate(auth: _auth),
        );
      },
    );
  }
}

/// Decides the first screen. Supabase restores the session from the device,
/// so a logged in user lands straight on the dashboard on every launch.
class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      initialData: auth.currentUser,
      stream: auth.userChanges,
      builder: (BuildContext context, AsyncSnapshot<User?> snap) {
        return ListenableBuilder(
          listenable: auth,
          builder: (BuildContext context, Widget? _) {
            final User? user = snap.data;

            if (user == null || auth.isSigningUp) {
              return AuthScreen(controller: auth);
            }
            final String name = AuthService.nameOf(user);
            if (name.isEmpty) {
              return NameScreen(controller: auth);
            }
            return DashboardScreen(key: ValueKey<String>(user.id), uid: user.id, name: name);
          },
        );
      },
    );
  }
}

/// Shown only while developing, when the Supabase keys have not been added yet.
class _SetupNeededApp extends StatelessWidget {
  const _SetupNeededApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Space.x24),
            child: Center(
              child: Text(
                'Supabase is not set up yet.\n\nOpen lib/core/config/supabase_config.dart and add your '
                'project URL and anon key, or run with --dart-define.',
                textAlign: TextAlign.center,
                style: AppText.body3(AppPalette.light.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
