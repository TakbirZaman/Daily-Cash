import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Loading placeholder shaped like the real content. Animates opacity only.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = Rad.r8,
    this.color,
  });

  final double? width;
  final double height;
  final double radius;
  final Color? color;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _opacity = Tween<double>(begin: 0.35, end: 0.85)
      .animate(CurvedAnimation(parent: _c, curve: AppMotion.base));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
      _c.value = 0.6;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color ?? context.pal.border,
          borderRadius: Rad.all(widget.radius),
        ),
      ),
    );
  }
}

/// Same layout as a transaction row.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.x12),
      decoration: BoxDecoration(
        color: context.pal.card,
        borderRadius: Rad.all(Rad.r16),
      ),
      child: const Row(
        children: <Widget>[
          Skeleton(width: 44, height: 44, radius: 22),
          SizedBox(width: Space.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Skeleton(width: 140, height: 16),
                SizedBox(height: Space.x8),
                Skeleton(width: 90, height: 12),
              ],
            ),
          ),
          SizedBox(width: Space.x8),
          Skeleton(width: 64, height: 16),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          const SkeletonTile(),
          const SizedBox(height: Space.x12),
        ],
      ],
    );
  }
}
