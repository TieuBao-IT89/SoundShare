param([string]$FlutterExecutable = 'flutter')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot
try {
  node scripts/prepare-web-config.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Client configuration failed.' }
  & $FlutterExecutable build web --release --dart-define-from-file=.local/web-config.json --no-web-resources-cdn
  if ($LASTEXITCODE -ne 0) { throw 'Flutter web build failed.' }
  Push-Location backend
  try {
    $env:SERVE_FLUTTER_WEB = 'true'
    npm start
  } finally { Remove-Item Env:SERVE_FLUTTER_WEB -ErrorAction SilentlyContinue; Pop-Location }
} finally { Pop-Location }
