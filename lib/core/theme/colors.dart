import 'package:flutter/material.dart';

/// Layer 1: raw brand colors.
/// One accent only (green, 75% saturation). Red is the semantic error/expense color.
/// Both pass 4.5:1 with white text.
class Brand {
  Brand._();
  static const Color income = Color(0xFF12805A);
  static const Color expense = Color(0xFFC12B31);
  static const Color ink = Color(0xFF12332B);
}

/// Layer 2: roles that change with light and dark mode. Use `context.pal`.
/// Dark surfaces use only: 131209, 1F1F1F, 272727, 313131.
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.field,
    required this.border,
    required this.text,
    required this.muted,
    required this.header,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.incomeText,
    required this.expenseText,
    required this.incomeSoft,
    required this.expenseSoft,
  });

  final Color bg; // Surface/Primary
  final Color card; // Surface/Secondary
  final Color field; // Surface/Input
  final Color border; // Border/Primary
  final Color text; // Text/Primary
  final Color muted; // Text/Secondary
  final Color header; // Surface/Brand
  final Color onHeader;
  final Color onHeaderMuted;
  final Color incomeText; // Text/Success
  final Color expenseText; // Text/Error
  final Color incomeSoft; // Surface/Success-subtle
  final Color expenseSoft; // Surface/Error-subtle

  static const AppPalette light = AppPalette(
    bg: Color(0xFFF6F7F6),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFFFFFFF),
    border: Color(0xFFDDE3E0),
    text: Color(0xFF1B2B27),
    muted: Color(0xFF5B6B66),
    header: Brand.ink,
    onHeader: Color(0xFFFFFFFF),
    onHeaderMuted: Color(0xFFB8C2BF),
    incomeText: Brand.income,
    expenseText: Brand.expense,
    incomeSoft: Color(0xFFE3F6EC),
    expenseSoft: Color(0xFFFCE7E8),
  );

  static const AppPalette dark = AppPalette(
    bg: Color(0xFF131209),
    card: Color(0xFF1F1F1F),
    field: Color(0xFF272727),
    border: Color(0xFF313131),
    text: Color(0xFFE8F0ED),
    muted: Color(0xFFA3AFAA),
    header: Color(0xFF1F1F1F),
    onHeader: Color(0xFFFFFFFF),
    onHeaderMuted: Color(0xFFB3B3B3),
    incomeText: Color(0xFF4ADE9A),
    expenseText: Color(0xFFFF7A7F),
    incomeSoft: Color(0xFF272727),
    expenseSoft: Color(0xFF272727),
  );
}

extension PaletteContext on BuildContext {
  AppPalette get pal =>
      Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
}
