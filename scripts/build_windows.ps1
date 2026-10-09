# Build amakawa for Windows and zip the result.
# Run from the repository root in PowerShell:  .\scripts\build_windows.ps1
$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "flutter not found on PATH. See BUILD.md."
}

flutter config --enable-windows-desktop | Out-Null
flutter pub get
flutter analyze
flutter build windows --release

$out = "build\windows\x64\runner\Release"
if (-not (Test-Path "$out\amakawa_core.dll")) {
    throw "amakawa_core.dll missing from $out - the native plugin build failed."
}
New-Item -ItemType Directory -Force build | Out-Null
$zip = "build\amakawa-windows-x64.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path "$out\*" -DestinationPath $zip
Write-Host "Done. Run: $out\amakawa.exe"
Write-Host "Portable zip: $zip"
