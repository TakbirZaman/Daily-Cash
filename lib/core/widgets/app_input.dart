import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// One field style for the whole app: border all the way around, 2px ring on focus.
InputDecoration appInput(
  BuildContext context, {
  required String label,
  String? hint,
  String? prefixText,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  final AppPalette pal = context.pal;
  OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
        borderRadius: Rad.all(Rad.r12),
        borderSide: BorderSide(color: c, width: w),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: pal.muted),
    suffixIcon: suffixIcon,
    labelStyle: AppText.body5(pal.muted),
    hintStyle: AppText.body6(pal.muted),
    filled: true,
    fillColor: pal.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: Space.x16, vertical: Space.x16),
    enabledBorder: border(pal.border, 1),
    focusedBorder: border(Brand.income, 2),
    border: border(pal.border, 1),
  );
}
