param(
  [ValidateSet('optimistic','pessimistic','both')] [string]$Mode = 'both',
  [int]$VUs = 20,
  [string]$Duration = '60s',
  [string]$ComposeFile = "$(Join-Path $PSScriptRoot 'docker-compose.yml')",
  [string]$BaseUrl = 'http://spring-app:8080'   # compose 서비스명 사용
)

$ErrorActionPreference = 'Stop'

# 경로 검증
$scriptRelDir = 'perf/k6/scenarios'
$scriptJs     = 'order-create-optimistic.js'
$scriptPath   = Join-Path $PSScriptRoot (Join-Path $scriptRelDir $scriptJs)
$outDir       = Join-Path $PSScriptRoot 'perf/k6/outputs'

if (!(Test-Path -LiteralPath $scriptPath)) { throw "missing script: $scriptPath" }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Run-One([string]$type, [string]$path) {
  Write-Host "==> start $type ($path)"
  # compose의 k6 서비스는 /scripts, /outputs 볼륨이 이미 연결됨
  docker compose -f "$ComposeFile" run --rm `
    -e BASE_URL=$BaseUrl `
    -e TARGET_PATH=$path `
    -e TEST_TYPE=$type `
    -e VUS=$VUs `
    -e DURATION=$Duration `
    k6 run --summary-export="/outputs/summary_$type.json" "/scripts/$scriptJs"
  Write-Host "==> done  $type  -> $(Join-Path $outDir "summary_$type.json")"
}

switch ($Mode) {
  'optimistic'  { Run-One 'optimistic'  '/api/v1/orders/optimistic' }
  'pessimistic' { Run-One 'pessimistic' '/api/v1/orders/pessimistic' }
  'both' {
    Run-One 'optimistic'  '/api/v1/orders/optimistic'
    Run-One 'pessimistic' '/api/v1/orders/pessimistic'
  }
}

# 결과 요약 출력
Get-ChildItem $outDir -Filter summary_*.json -ErrorAction SilentlyContinue | ForEach-Object {
  $j = ($_ | Get-Content -Raw | ConvertFrom-Json)
  "{0,-13} p50={1}ms p95={2}ms p99={3}ms failRate={4:p2} http_reqs={5}" -f `
    ($_.BaseName.Replace('summary_','')),
    [math]::Round($j.metrics.http_req_duration.values.'p(50)',2),
    [math]::Round($j.metrics.http_req_duration.values.'p(95)',2),
    [math]::Round($j.metrics.http_req_duration.values.'p(99)',2),
    $j.metrics.http_req_failed.values.rate,
    [int]$j.metrics.http_reqs.values.count
}
