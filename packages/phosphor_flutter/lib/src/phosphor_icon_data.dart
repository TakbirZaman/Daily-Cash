library phosphor_flutter;

import 'package:flutter/widgets.dart';

/// Flutter 3.44+ marks IconData as a final class, so the package can no longer
/// subclass it. The icons below are plain const IconData values, and the old
/// class names are kept as type aliases for compatibility.
typedef PhosphorIconData = IconData;
typedef PhosphorFlatIconData = IconData;
typedef PhosphorDuotoneIconData = IconData;
