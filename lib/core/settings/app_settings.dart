import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';

/// Language + theme, remembered on the device.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  bool _bn = false;
  ThemeMode _mode = ThemeMode.system;

  bool get isBangla => _bn;
  ThemeMode get themeMode => _mode;

  Future<void> load() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      _bn = p.getBool('bn') ?? false;
      final String m = p.getString('theme') ?? 'system';
      _mode = ThemeMode.values.firstWhere(
        (ThemeMode e) => e.name == m,
        orElse: () => ThemeMode.system,
      );
      S.bn = _bn;
    } catch (_) {}
  }

  Future<void> setBangla(bool value) async {
    _bn = value;
    S.bn = value;
    notifyListeners();
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool('bn', value);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('theme', mode.name);
    } catch (_) {}
  }
}
