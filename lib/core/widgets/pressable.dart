import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Physical press feedback: scales to 0.98 while a finger is down.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child});

  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent _) => _set(true),
      onPointerUp: (PointerUpEvent _) => _set(false),
      onPointerCancel: (PointerCancelEvent _) => _set(false),
      child: AnimatedScale(
        scale: _down && !AppMotion.reduced(context) ? 0.98 : 1,
        duration: AppMotion.color,
        curve: AppMotion.base,
        child: widget.child,
      ),
    );
  }
}
