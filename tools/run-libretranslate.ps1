# Runs LibreTranslate locally on http://127.0.0.1:5000 for the content
# translation worker.
#
# First run installs the package into tools/.libretranslate-venv and downloads
# the en/es/fr language models (several hundred MB, one time).
#
# Then start the backend with:
#   $env:I18N_TRANSLATION_PROVIDER = 'libretranslate'
#   $env:LIBRETRANSLATE_URL = 'http://localhost:5000'
#   $env:LIBRETRANSLATE_TIMEOUT = '30s'
#
# Verify:
#   curl.exe http://127.0.0.1:5000/languages

$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$venv = Join-Path $here '.libretranslate-venv'
$python = Join-Path $venv 'Scripts\python.exe'

if (-not (Test-Path $python)) {
    Write-Host "Creating Python 3.12 virtual environment at $venv ..."
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        uv venv $venv --python 3.12
    } else {
        py -3.12 -m venv $venv
    }
}

Write-Host "Installing/updating libretranslate ..."
if (Get-Command uv -ErrorAction SilentlyContinue) {
    uv pip install --python $python --quiet libretranslate
} else {
    & $python -m pip install --quiet --upgrade pip
    & $python -m pip install --quiet libretranslate
}

$exe = Join-Path $venv 'Scripts\libretranslate.exe'
if (-not (Test-Path $exe)) {
    throw "libretranslate entry point was not installed at $exe"
}

Write-Host "Starting LibreTranslate on http://127.0.0.1:5000 (models download on first use) ..."
& $exe --host 127.0.0.1 --port 5000 --load-only en,es,fr
