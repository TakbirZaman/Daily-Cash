import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/strings.dart';
import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Top bar with a Phosphor back arrow (no Material icons anywhere).
PreferredSizeWidget appBarFor(BuildContext context, String title, {List<Widget>? actions}) {
  final AppPalette pal = context.pal;
  return AppBar(
    backgroundColor: pal.bg,
    scrolledUnderElevation: 0,
    leading: IconButton(
      tooltip: S.t('back'),
      onPressed: () => Navigator.of(context).maybePop(),
      icon: PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 24, color: pal.text),
    ),
    title: Text(title, style: AppText.title1(pal.text)),
    actions: actions,
  );
}
