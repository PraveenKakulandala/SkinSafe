param(
  [Parameter(Mandatory = $true)]
  [string]$DeviceId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$fallbackFlutterPath = 'D:\flutter_sdk\bin\flutter.bat'
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue

if (Test-Path $fallbackFlutterPath) {
  $flutterPath = $fallbackFlutterPath
} elseif ($flutterCommand) {
  $flutterPath = $flutterCommand.Source
} else {
  throw 'Flutter executable was not found on PATH.'
}

Push-Location $projectRoot
try {
  & $flutterPath run -d $DeviceId
} finally {
  Pop-Location
}
