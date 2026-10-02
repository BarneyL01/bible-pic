#!/usr/bin/env bash
# One-time (idempotent) Android setup: generates the Android project with
# `flutter create`, installs the home-screen widget files, and patches the
# manifest. Run from app/ on a machine with the Flutter SDK.
set -euo pipefail
cd "$(dirname "$0")/.."

PKG=com.biblepic.bible_pic
flutter create --platforms=android --org com.biblepic --project-name bible_pic .

KT_DIR="android/app/src/main/kotlin/${PKG//./\/}"
mkdir -p "$KT_DIR" android/app/src/main/res/layout android/app/src/main/res/xml
cp android_widget/kotlin/VerseWidgetProvider.kt "$KT_DIR/"
cp android_widget/res/layout/verse_widget.xml android/app/src/main/res/layout/
cp android_widget/res/xml/verse_widget_info.xml android/app/src/main/res/xml/

python3 - <<'PY'
import re
path = "android/app/src/main/AndroidManifest.xml"
s = open(path).read()
if "VerseWidgetProvider" not in s:
    receiver = '''
        <receiver android:name=".VerseWidgetProvider" android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data android:name="android.appwidget.provider"
                android:resource="@xml/verse_widget_info" />
        </receiver>
'''
    s = s.replace("</application>", receiver + "    </application>")
    open(path, "w").write(s)
PY

echo "Next: flutter pub get && dart run build_runner build --delete-conflicting-outputs"
echo "Confirm android/app/build.gradle(.kts) applicationId is ${PKG}."
