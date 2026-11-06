import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color ink = Color(0xFF12332B);
  static const Color income = Color(0xFF16A36A);
  static const Color expense = Color(0xFFE5484D);
}

/// Colors that change between light and dark mode.
/// Use `context.pal` inside build methods.
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.text,
    required this.muted,
    required this.incomeSoft,
    required this.expenseSoft,
  });

  final Color bg;
  final Color card;
  final Color text;
  final Color muted;
  final Color incomeSoft;
  final Color expenseSoft;

  static const AppPalette light = AppPalette(
    bg: Color(0xFFF2F6F4),
    card: Colors.white,
    text: Color(0xFF1B2B27),
    muted: Color(0xFF6B7C77),
    incomeSoft: Color(0xFFE3F6EC),
    expenseSoft: Color(0xFFFCE7E8),
  );

  static const AppPalette dark = AppPalette(
    bg: Color(0xFF0E1714),
    card: Color(0xFF182420),
    text: Color(0xFFE8F0ED),
    muted: Color(0xFF93A59F),
    incomeSoft: Color(0xFF14352A),
    expenseSoft: Color(0xFF3A1C1E),
  );
}

extension PaletteContext on BuildContext {
  AppPalette get pal =>
      Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
}
