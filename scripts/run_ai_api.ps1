Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pythonPath = Join-Path $projectRoot '.python\python311\python.exe'

if (-not (Test-Path $pythonPath)) {
  throw "Project-local Python was not found at $pythonPath"
}

Push-Location $projectRoot
try {
  & $pythonPath -m uvicorn ml.predict_api:app --host 0.0.0.0 --port 8000
} finally {
  Pop-Location
}
