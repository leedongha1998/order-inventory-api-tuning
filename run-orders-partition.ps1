# run-orders-partition.ps1
# k6 실행(환경변수 미설정) + summary JSON -> MD 변환 (PS 5.1 호환)

$ErrorActionPreference = 'Stop'

# --- 경로 설정 ---
$currentPath = (Get-Location).Path
$scriptPath  = Join-Path $currentPath "perf\k6\scenarios\order-write-bench.js"
if (-not (Test-Path $scriptPath)) { Write-Host "ERROR: $scriptPath not found"; exit 1 }

$outputsPath = Join-Path $currentPath "perf\k6\outputs"
if (-not (Test-Path $outputsPath)) { New-Item -ItemType Directory -Path $outputsPath -Force | Out-Null }

# --- 환경값 해석(없으면 k6 기본 가정) ---
$baseUrl  = if ($env:BASE_URL)   { $env:BASE_URL }   else { "http://spring-app:8080" }
$pathPref = if ($env:PATH_PREFIX){ $env:PATH_PREFIX} else { "/api/v1/orders/np" }

# Impl 태그 추출: /api/v1/orders/{impl}
$impl = $pathPref -replace '^.*/',''
if ([string]::IsNullOrWhiteSpace($impl)) { $impl = 'np' }

# --- 파일 경로 ---
$summaryInContainer = "/outputs/order-write-$impl.json"
$jsonPath = Join-Path $outputsPath ("order-write-$impl.json")
$mdOut    = Join-Path $outputsPath ("$impl.md")

Write-Host "====================================="
Write-Host ("Order Write Test (Impl={0})" -f $impl)
Write-Host "====================================="

# --- k6 실행(환경변수 전달 없음) ---
docker compose run --rm -T `
  -v "$($outputsPath):/outputs" `
  -v "$($scriptPath):/scripts/order-write-bench.js:ro" `
  k6 run --summary-export $summaryInContainer /scripts/order-write-bench.js

if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: k6 run failed"; exit 1 }
if (-not (Test-Path $jsonPath)) { Write-Host "ERROR: $jsonPath not found"; exit 1 }

# --- 결과 파싱 ---
$j = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json
$metrics = $j.metrics

function Get-MetricVal($metrics, [string]$name, [string]$field) {
  if ($null -eq $metrics) { return $null }
  $m = $metrics.$name
  if ($null -eq $m) { return $null }
  if ($m.$field -ne $null) { return $m.$field }
  if ($m.values -and $m.values.$field -ne $null) { return $m.values.$field }
  return $null
}
function F([object]$v, [string]$fmt='0.00') {
  if ($null -eq $v) { return '0' }
  try { return ([double]$v).ToString($fmt, [Globalization.CultureInfo]::InvariantCulture) } catch { '0' }
}

$p95   = F (Get-MetricVal $metrics 'http_req_duration' 'p(95)')
$p99   = F (Get-MetricVal $metrics 'http_req_duration' 'p(99)')
$avg   = F (Get-MetricVal $metrics 'http_req_duration' 'avg')
$med   = F (Get-MetricVal $metrics 'http_req_duration' 'med')
$maxv  = F (Get-MetricVal $metrics 'http_req_duration' 'max')
$count = [int](Get-MetricVal $metrics 'http_reqs' 'count')
$failRate = Get-MetricVal $metrics 'http_req_failed' 'rate'
$failPct  = if ($null -ne $failRate) { F (($failRate) * 100.0) } else { '0.00' }
$passes   = [int](Get-MetricVal $metrics 'checks' 'passes'  ?? 0)
$fails    = [int](Get-MetricVal $metrics 'checks' 'fails'   ?? 0)

# --- MD 생성 ---
$md = @()
$md += "# Order Write Bench - $impl"
$md += ""
$md += ("- **Generated at**: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss K"))
$md += ("- **Resolved BASE_URL**: {0}" -f $baseUrl)
$md += ("- **Resolved PATH_PREFIX**: {0}" -f $pathPref)
$md += "- **Request Body 예시**:"
$md += ""
$md += '```json'
$md += '{ "memberId": 1, "price": 1, "createdAt": "yyyy-MM-dd''T''HH:mm:ss" }'
$md += '```'
$md += ""
$md += "## k6 Results"
$md += ""
$md += "| Metric | Value |"
$md += "|---|---:|"
$md += ("| http_req_duration p95 (ms) | {0} |" -f $p95)
$md += ("| http_req_duration p99 (ms) | {0} |" -f $p99)
$md += ("| avg / med / max (ms) | {0} / {1} / {2} |" -f $avg,$med,$maxv)
$md += ("| http_reqs count | {0} |" -f $count)
$md += ("| http_req_failed (%) | {0} |" -f $failPct)
$md += ("| checks (passes / fails) | {0} / {1} |" -f $passes,$fails)

[string]::Join([Environment]::NewLine, $md) | Set-Content -Encoding UTF8 -Path $mdOut
Write-Host ("Markdown report -> {0}" -f $mdOut)
