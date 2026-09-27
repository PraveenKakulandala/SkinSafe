Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$health = Invoke-RestMethod 'http://127.0.0.1:8000/health'
$health | ConvertTo-Json -Depth 4
