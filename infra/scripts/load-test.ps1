param(
  [string]$BaseUrl = "http://localhost:8080",
  [string]$PublicUrl = "",
  [int]$Iterations = 30
)
$ErrorActionPreference = "Stop"
$envFile = Get-Content (Join-Path $PSScriptRoot "..\.env") -Raw
$seed = [regex]::Match($envFile, "(?m)^DEV_SEED_PASSWORD=(.*)$").Groups[1].Value.Trim()
function Measure-Step([string]$Name, [scriptblock]$Action) {
  $values = New-Object System.Collections.Generic.List[double]
  $errors = 0
  for ($i = 0; $i -lt $Iterations; $i++) {
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    try { & $Action | Out-Null } catch { $errors++ }
    $watch.Stop()
    $values.Add($watch.Elapsed.TotalMilliseconds)
  }
  $sorted = $values | Sort-Object
  $p50 = $sorted[[int][Math]::Floor($sorted.Count * 0.50)]
  $p95 = $sorted[[Math]::Min($sorted.Count - 1, [int][Math]::Floor($sorted.Count * 0.95))]
  [pscustomobject]@{ Step=$Name; Requests=$Iterations; Errors=$errors; P50ms=[Math]::Round($p50,1); P95ms=[Math]::Round($p95,1) }
}
$login = $null
$loginRow = Measure-Step "login" {
  $script:login = Invoke-RestMethod -Method Post -Uri "$BaseUrl/api/v1/auth/login" -ContentType "application/json" -Body (@{email="admin.a@truereport.test"; password=$seed} | ConvertTo-Json)
}
$headers = @{ Authorization = "Bearer $($login.accessToken)" }
$jobRow = Measure-Step "job list" {
  Invoke-RestMethod -Method Get -Uri "$BaseUrl/api/v1/workshop/jobs" -Headers $headers
}
$rows = @($loginRow, $jobRow)
if ($PublicUrl) {
  $rows += Measure-Step "public report" { Invoke-WebRequest -UseBasicParsing -Uri $PublicUrl }
}
$rows | Format-Table -AutoSize
