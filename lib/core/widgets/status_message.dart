import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Inline message. State is shown with an icon and words, never color alone.
class StatusMessage extends StatelessWidget {
  const StatusMessage.error(this.text, {super.key}) : isError = true;
  const StatusMessage.success(this.text, {super.key}) : isError = false;

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;
    final Color color = isError ? pal.expenseText : pal.incomeText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PhosphorIcon(
          isError ? PhosphorIconsRegular.warningCircle : PhosphorIconsRegular.checkCircle,
          size: 20,
          color: color,
        ),
        const SizedBox(width: Space.x8),
        Expanded(child: Text(text, style: AppText.body5(color))),
      ],
    );
  }
}
