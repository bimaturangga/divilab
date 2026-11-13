#!/usr/bin/env bash
# Setup project DiViLab di macOS/Linux (dibutuhkan untuk build iOS di Mac).
set -euo pipefail

echo "1/4 Membuat folder platform Android & iOS..."
flutter create . --org com.divilab --project-name divilab --platforms=android,ios

echo "2/4 Menambahkan izin INTERNET & nama aplikasi..."
MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
fi
perl -pi -e 's#android:label="divilab"#android:label="DiViLab"#' "$MANIFEST"

echo "3/4 Mengunduh dependency..."
flutter pub get

echo "4/4 Menjalankan unit test..."
flutter test

echo
echo "Selesai! Android: flutter run | iOS Simulator (macOS): open -a Simulator && flutter run"
