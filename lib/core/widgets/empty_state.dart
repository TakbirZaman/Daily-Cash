import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// A composed "nothing here yet" view with a next step, never a blank panel.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: pal.incomeSoft, shape: BoxShape.circle),
                child: PhosphorIcon(icon, size: 32, color: pal.incomeText),
              ),
              const SizedBox(height: Space.x16),
              Text(title,
                  textAlign: TextAlign.center, style: AppText.heading6(pal.text)),
              const SizedBox(height: Space.x8),
              Text(body, textAlign: TextAlign.center, style: AppText.body6(pal.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
