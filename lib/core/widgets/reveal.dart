import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Rises a short distance and fades in, once, when first shown.
/// With reduced motion on, it is a plain opacity change.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool reduced = AppMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.reveal,
      curve: AppMotion.base,
      child: child,
      builder: (BuildContext context, double v, Widget? child) {
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, reduced ? 0 : (1 - v) * Space.x24),
            child: child,
          ),
        );
      },
    );
  }
}
