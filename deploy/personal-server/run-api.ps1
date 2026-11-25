# Runs the API on a Windows personal server without Docker.
#
# 1. Copy api.env.example to api.env in this folder and fill it.
# 2. mvn -f server/pom.xml -DskipTests package
# 3. .\deploy\personal-server\run-api.ps1
#
# The script loads api.env, starts/reuses LibreTranslate on 127.0.0.1:5000,
# then runs the Spring Boot JAR.

$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Resolve-Path (Join-Path $here '..\..')
$envFile = Join-Path $here 'api.env'

if (-not (Test-Path $envFile)) {
    throw "Missing $envFile. Copy api.env.example to api.env and fill it."
}

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { return }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { return }
    $name = $line.Substring(0, $eq).Trim()
    $value = $line.Substring($eq + 1).Trim()
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}

& (Join-Path $repo 'tools\ensure-libretranslate.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'LibreTranslate is required for content translation and could not be started.'
}

$jar = Join-Path $repo 'server\target\truereport-server-0.2.0-SNAPSHOT.jar'
if (-not (Test-Path $jar)) {
    throw "Missing $jar. Build it with: mvn -f server/pom.xml -DskipTests package"
}

Write-Host "Starting TrueReport API (provider=$env:I18N_TRANSLATION_PROVIDER, LibreTranslate=$env:LIBRETRANSLATE_URL)"
& java -jar $jar
