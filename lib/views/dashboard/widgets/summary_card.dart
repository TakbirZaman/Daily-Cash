import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/skeleton.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.loading = false,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.x16),
      decoration: BoxDecoration(color: color, borderRadius: Rad.all(Rad.r16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PhosphorIcon(icon, size: 24, color: Colors.white),
          const SizedBox(height: Space.x12),
          Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption1(Colors.white)),
          const SizedBox(height: Space.x4),
          if (loading)
            const Skeleton(width: 96, height: 32, color: Color(0x29FFFFFF))
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(Money.format(amount), style: AppText.heading5(Colors.white)),
            ),
        ],
      ),
    );
  }
}
