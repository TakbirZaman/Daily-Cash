#!/usr/bin/env python3
"""Patch the vendored phosphor_flutter package for Flutter 3.44+ (IconData is final).

- PhosphorIconData / PhosphorFlatIconData / PhosphorDuotoneIconData become typedefs to IconData.
- Generated icon constants emit plain const IconData(...) values.
- PhosphorIcon drops the duotone stacked rendering (duotone still renders as a flat glyph).
"""
import pathlib
import re
import sys

SRC = pathlib.Path("packages/phosphor_flutter/lib/src")

NEW_ICON_DATA = """library phosphor_flutter;

import 'package:flutter/widgets.dart';

/// Flutter 3.44+ marks IconData as a final class, so the package can no longer
/// subclass it. The icons below are plain const IconData values, and the old
/// class names are kept as type aliases for compatibility.
typedef PhosphorIconData = IconData;
typedef PhosphorFlatIconData = IconData;
typedef PhosphorDuotoneIconData = IconData;
"""


def fail(message: str) -> None:
    print(f"PATCH FAILED: {message}")
    sys.exit(1)


def patch_flat(path: pathlib.Path) -> None:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(r"PhosphorFlatIconData\((0x[0-9a-fA-F]+), '(\w+)'\)")
    new_text, n = pattern.subn(
        r"const IconData(\1, fontFamily: 'Phosphor\2', fontPackage: 'phosphor_flutter', matchTextDirection: true)",
        text,
    )
    if n == 0:
        if re.search(r"IconData\(0x[0-9a-fA-F]+, fontFamily: 'Phosphor\w+', fontPackage: 'phosphor_flutter'", text):
            print(f"{path.name}: already patched")
            return
        fail(f"no PhosphorFlatIconData matches in {path.name}")
    path.write_text(new_text, encoding="utf-8")
    print(f"{path.name}: {n} flat icons converted")


def patch_duotone(path: pathlib.Path) -> None:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(
        r"PhosphorDuotoneIconData\(\s*(0x[0-9a-fA-F]+),\s*PhosphorIconData\((0x[0-9a-fA-F]+), 'Duotone'\),?\s*\)",
        re.S,
    )
    new_text, n = pattern.subn(
        r"const IconData(\1, fontFamily: 'PhosphorDuotone', fontPackage: 'phosphor_flutter', matchTextDirection: true)",
        text,
    )
    if n == 0:
        if re.search(r"IconData\(0x[0-9a-fA-F]+, fontFamily: 'PhosphorDuotone', fontPackage: 'phosphor_flutter'", text):
            print(f"{path.name}: already patched")
            return
        fail(f"no PhosphorDuotoneIconData matches in {path.name}")
    path.write_text(new_text, encoding="utf-8")
    print(f"{path.name}: {n} duotone icons converted")


def patch_phosphor_icon(path: pathlib.Path) -> None:
    text = path.read_text(encoding="utf-8")
    start = text.find("  @override\n  Widget build(BuildContext context) {")
    if start == -1:
        fail("build method not found in phosphor_icon.dart")
    new_text = text[:start] + "  @override\n  Widget build(BuildContext context) {\n    return super.build(context);\n  }\n}\n"
    path.write_text(new_text, encoding="utf-8")
    print("phosphor_icon.dart: duotone branch removed")


(SRC / "phosphor_icon_data.dart").write_text(NEW_ICON_DATA, encoding="utf-8")
print("phosphor_icon_data.dart: rewritten as typedefs")

for name in [
    "phosphor_icons_regular.dart",
    "phosphor_icons_thin.dart",
    "phosphor_icons_light.dart",
    "phosphor_icons_bold.dart",
    "phosphor_icons_fill.dart",
    "phosphor_icons_duotone.dart",
]:
    patch_flat(SRC / name)

patch_duotone(SRC / "phosphor_icons_duotone.dart")
patch_phosphor_icon(SRC / "phosphor_icon.dart")
print("phosphor_flutter patched")
