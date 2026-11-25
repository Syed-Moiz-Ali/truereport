# Ensures a local LibreTranslate is listening on 127.0.0.1:5000.
#
# Called by run-backend.ps1, run-local.bat and start-mysql-backend.ps1 so the
# backend never silently falls back to the fake translation provider.
#
# First run installs LibreTranslate into tools/.libretranslate-venv (see
# run-libretranslate.ps1). Models download on first translation.

$ErrorActionPreference = 'Stop'

$port = 5000

function Test-LibreTranslatePort {
    try {
        $client = New-Object Net.Sockets.TcpClient
        $client.Connect('127.0.0.1', $port)
        $client.Close()
        return $true
    } catch {
        return $false
    }
}

if (Test-LibreTranslatePort) {
    Write-Host "LibreTranslate is already running on 127.0.0.1:$port"
    exit 0
}

Write-Host "Starting LibreTranslate on 127.0.0.1:$port ..."
$runner = Join-Path $PSScriptRoot 'run-libretranslate.ps1'
if (-not (Test-Path $runner)) {
    throw "Missing $runner"
}
Start-Process -FilePath 'powershell.exe' `
    -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$runner`"") `
    -WorkingDirectory $PSScriptRoot `
    -WindowStyle Minimized

for ($i = 0; $i -lt 300; $i++) {
    Start-Sleep -Seconds 1
    if (Test-LibreTranslatePort) {
        Write-Host "LibreTranslate is up on 127.0.0.1:$port"
        exit 0
    }
}

Write-Error "LibreTranslate did not start within 300 seconds. Run tools\run-libretranslate.ps1 to see the error."
exit 1
