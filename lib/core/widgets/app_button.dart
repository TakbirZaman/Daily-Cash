import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/colors.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// Main button: white label on a flat fill that passes 4.5:1.
/// Padding is 8 vertical and 12 horizontal; the height keeps a 56 touch target.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Brand.income,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            disabledBackgroundColor: context.pal.border,
            disabledForegroundColor: context.pal.muted,
            padding: const EdgeInsets.symmetric(horizontal: Space.x12, vertical: Space.x8),
            shape: RoundedRectangleBorder(borderRadius: Rad.all(Rad.r12)),
            textStyle: AppText.buttonMd(),
          ),
          onPressed: loading ? null : onPressed,
          child: Text(
            loading ? S.t('please_wait') : label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
