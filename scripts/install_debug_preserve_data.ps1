param(
  [string]$DeviceId = 'emulator-5554',
  [string]$PackageName = 'com.example.melanoma_skin_cancer'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$fallbackFlutterPath = 'D:\flutter_sdk\bin\flutter.bat'
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$adbCommand = Get-Command adb -ErrorAction SilentlyContinue

if (Test-Path $fallbackFlutterPath) {
  $flutterPath = $fallbackFlutterPath
} elseif ($flutterCommand) {
  $flutterPath = $flutterCommand.Source
} else {
  throw 'Flutter executable was not found on PATH.'
}

if ($adbCommand) {
  $adbPath = $adbCommand.Source
} else {
  $defaultAdbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
  if (Test-Path $defaultAdbPath) {
    $adbPath = $defaultAdbPath
  } else {
    throw 'ADB executable was not found on PATH or in the default Android SDK location.'
  }
}

$apkPath = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-debug.apk'

Push-Location $projectRoot
try {
  & $flutterPath build apk --debug

  if (-not (Test-Path $apkPath)) {
    throw "Debug APK was not created at $apkPath"
  }

  if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    & $adbPath install -r $apkPath
    & $adbPath shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1
  } else {
    & $adbPath -s $DeviceId install -r $apkPath
    & $adbPath -s $DeviceId shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1
  }
} finally {
  Pop-Location
}
