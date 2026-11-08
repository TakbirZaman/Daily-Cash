#!/usr/bin/env python3
"""Run once after `flutter create`.

Gives the generated Android project: the INTERNET permission only, the app name,
and release signing from android/key.properties. Fails loudly if the generated
files do not look as expected, so a wrong build can never slip through.
"""
import pathlib
import re
import sys

MANIFEST = pathlib.Path("android/app/src/main/AndroidManifest.xml")
GRADLE = pathlib.Path("android/app/build.gradle.kts")


def fail(message: str) -> None:
    print(f"PATCH FAILED: {message}")
    sys.exit(1)


if not MANIFEST.exists() or not GRADLE.exists():
    fail("run `flutter create . --platforms android` first (Kotlin DSL project expected)")

# ---- manifest ----
m = MANIFEST.read_text(encoding="utf-8")
if "<application" not in m:
    fail("no <application> tag in AndroidManifest.xml")
if "android.permission.INTERNET" not in m:
    m = m.replace(
        "<application",
        '<uses-permission android:name="android.permission.INTERNET" />\n\n    <application',
        1,
    )
m = re.sub(r'android:label="[^"]*"', 'android:label="Daily Cash"', m, count=1)
MANIFEST.write_text(m, encoding="utf-8")

# ---- gradle ----
g = GRADLE.read_text(encoding="utf-8")
if "signingConfigs.getByName(\"release\")" in g:
    print("gradle already patched")
    sys.exit(0)

if 'signingConfig = signingConfigs.getByName("debug")' not in g:
    fail("release buildType not in the expected shape; see the build log and adjust patch_android.py")
if "buildTypes {" not in g:
    fail("no buildTypes block")

imports = "import java.io.FileInputStream\nimport java.util.Properties\n\n"
if "import java.util.Properties" not in g:
    g = imports + g

plugins_end = re.search(r"plugins\s*\{.*?\n\}\n", g, re.S)
if not plugins_end:
    fail("no plugins block")

props = '''
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
'''
g = g[: plugins_end.end()] + props + g[plugins_end.end():]

signing = '''    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {'''
g = g.replace("    buildTypes {", signing, 1)
g = g.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")',
    1,
)
GRADLE.write_text(g, encoding="utf-8")
print("android project patched")
