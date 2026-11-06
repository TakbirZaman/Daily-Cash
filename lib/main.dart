import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'controllers/auth_controller.dart';
import 'core/constants/app_colors.dart';
import 'core/l10n/strings.dart';
import 'core/settings/app_settings.dart';
import 'services/firestore_service.dart';
import 'views/auth/auth_screen.dart';
import 'views/auth/name_screen.dart';
import 'views/dashboard/dashboard_screen.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Swallow framework + platform errors so the app never crashes on screen.
    FlutterError.onError = (FlutterErrorDetails _) {};
    PlatformDispatcher.instance.onError = (Object _, StackTrace __) => true;

    try {
      await Firebase.initializeApp();
      FirestoreService.enableOfflinePersistence();
    } catch (_) {}

    try {
      await initializeDateFormatting('en');
      await initializeDateFormatting('bn');
    } catch (_) {}

    await AppSettings.instance.load();

    runApp(DailyCashApp());
  }, (Object _, StackTrace __) {});
}

ThemeData _buildTheme(Brightness brightness) {
  final AppPalette pal = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: AppColors.income,
    scaffoldBackgroundColor: pal.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: pal.bg,
      foregroundColor: pal.text,
      scrolledUnderElevation: 0,
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

/// Decides the first screen. Because Firebase restores the session from the
/// device, a logged-in user lands straight on the dashboard on every launch.
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
            if ((user.displayName ?? '').trim().isEmpty) {
              return NameScreen(controller: auth);
            }
            return DashboardScreen(
              key: ValueKey<String>(user.uid),
              uid: user.uid,
              name: user.displayName!.trim(),
            );
          },
        );
      },
    );
  }
}
