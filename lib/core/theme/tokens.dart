import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

/// Spacing scale. Nothing between these values, nothing outside them.
class Space {
  Space._();
  static const double x0 = 0;
  static const double x2 = 2;
  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x64 = 64;
  static const double x80 = 80;
  static const double x96 = 96;
}

/// Corner radius scale. Nested shapes: inner = outer − gap (when the result is above 2).
class Rad {
  Rad._();
  static const double r2 = 2;
  static const double r4 = 4;
  static const double r6 = 6;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r24 = 24;

  static BorderRadius all(double r) => BorderRadius.circular(r);
  static BorderRadius top(double r) => BorderRadius.vertical(top: Radius.circular(r));
  static BorderRadius bottom(double r) => BorderRadius.vertical(bottom: Radius.circular(r));
}

class AppMotion {
  AppMotion._();

  /// Weighted ease that decelerates into place. Never the default curves.
  static const Curve base = Cubic(0.22, 1, 0.36, 1);
  static const Duration layout = Duration(milliseconds: 500);
  static const Duration color = Duration(milliseconds: 300);
  static const Duration reveal = Duration(milliseconds: 600);

  static bool reduced(BuildContext context) => MediaQuery.of(context).disableAnimations;
}

/// Named text styles on the Tailwind type scale (12, 14, 16, 18, 20, 24, 30, 36, 48, 60).
/// Weights: Regular 400, Medium 500, Semibold 600. Nothing heavier, no italics.
class AppText {
  AppText._();

  static TextStyle _s(double size, double line, int weight, Color? color) => TextStyle(
        fontFamily: 'Manrope',
        fontSize: size,
        height: line / size,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: <FontVariation>[FontVariation('wght', weight.toDouble())],
        letterSpacing: 0,
        color: color,
      );

  static TextStyle heading1([Color? c]) => _s(60, 60, 600, c);
  static TextStyle heading2([Color? c]) => _s(48, 48, 600, c);
  static TextStyle heading3([Color? c]) => _s(36, 40, 600, c);
  static TextStyle heading4([Color? c]) => _s(30, 36, 600, c);
  static TextStyle heading5([Color? c]) => _s(24, 32, 600, c);
  static TextStyle heading6([Color? c]) => _s(20, 28, 600, c);

  static TextStyle title1([Color? c]) => _s(20, 28, 500, c);
  static TextStyle title2([Color? c]) => _s(18, 28, 500, c);
  static TextStyle title3([Color? c]) => _s(16, 24, 500, c);
  static TextStyle title4([Color? c]) => _s(14, 20, 500, c);
  static TextStyle title5([Color? c]) => _s(12, 16, 500, c);

  static TextStyle body1([Color? c]) => _s(16, 24, 600, c);
  static TextStyle body2([Color? c]) => _s(16, 24, 500, c);
  static TextStyle body3([Color? c]) => _s(16, 24, 400, c);
  static TextStyle body4([Color? c]) => _s(14, 20, 600, c);
  static TextStyle body5([Color? c]) => _s(14, 20, 500, c);
  static TextStyle body6([Color? c]) => _s(14, 20, 400, c);

  static TextStyle buttonLg([Color? c]) => _s(18, 28, 600, c);
  static TextStyle buttonMd([Color? c]) => _s(16, 24, 600, c);
  static TextStyle buttonSm([Color? c]) => _s(14, 20, 600, c);
  static TextStyle buttonXsm([Color? c]) => _s(12, 16, 600, c);

  static TextStyle caption1([Color? c]) => _s(14, 20, 500, c);
  static TextStyle caption2([Color? c]) => _s(14, 20, 400, c);
  static TextStyle caption3([Color? c]) => _s(12, 16, 600, c);
  static TextStyle caption4([Color? c]) => _s(12, 16, 500, c);
  static TextStyle caption5([Color? c]) => _s(12, 16, 400, c);
}
