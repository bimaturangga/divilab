# Setup project DiViLab di Windows.
# Jalankan dari folder project:
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1
$ErrorActionPreference = "Stop"

Write-Host "1/4 Membuat folder platform Android & iOS (file yang sudah ada tidak ditimpa)..."
flutter create . --org com.divilab --project-name divilab --platforms=android,ios

Write-Host "2/4 Menambahkan izin INTERNET & nama aplikasi di AndroidManifest..."
$manifest = "android/app/src/main/AndroidManifest.xml"
$content = Get-Content $manifest -Raw
if ($content -notmatch "android.permission.INTERNET") {
    $content = $content -replace "<application", "<uses-permission android:name=`"android.permission.INTERNET`"/>`r`n    <application"
}
$content = $content -replace 'android:label="divilab"', 'android:label="DiViLab"'
Set-Content -Path $manifest -Value $content -Encoding UTF8

Write-Host "3/4 Mengunduh dependency..."
flutter pub get

Write-Host "4/4 Menjalankan unit test..."
flutter test

Write-Host ""
Write-Host "Selesai! Nyalakan emulator Android lalu jalankan:"
Write-Host "  flutter run"
Write-Host "Opsional (asisten AI online):"
Write-Host "  flutter run --dart-define=GEMINI_API_KEY=API_KEY_ANDA"
