import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Selected state uses fill, a check icon and label color, never color alone.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = Brand.income,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;
    return ChoiceChip(
      label: Text(label, style: AppText.buttonSm(selected ? Colors.white : pal.text)),
      avatar: selected ? PhosphorIcon(PhosphorIconsRegular.check, size: 16, color: Colors.white) : null,
      selected: selected,
      selectedColor: color,
      backgroundColor: pal.card,
      side: BorderSide(color: selected ? color : pal.border),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: Space.x8, vertical: Space.x8),
      onSelected: (_) => onTap(),
    );
  }
}
