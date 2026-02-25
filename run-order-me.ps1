# run-order-me.ps1
# Orders/Me - System/Docker + Prometheus metrics + Markdown Report (PS 5.1)

Write-Host "======================================"
Write-Host "HikariCP Pool Size Test (ORDERS/ME ONLY)"
Write-Host "======================================"

$scriptPath = ".\perf\k6\scenarios\order-me-only.js"
if (-not (Test-Path $scriptPath)) { Write-Host "ERROR: $scriptPath not found"; exit 1 }

$currentPath = (Get-Location).Path
$outputsPath = Join-Path $currentPath "perf\k6\outputs"
if (-not (Test-Path $outputsPath)) { New-Item -ItemType Directory -Path $outputsPath -Force | Out-Null }

# ===== Config =====
$poolSizes = @(20)
$ThreadMax = 100
$RateOrdersMe = 1000
$ResetDb = $false

# compose service names
$ComposeAppServiceCandidates   = @("app")
$ComposeDbServiceCandidates    = @("postgres","my-postgres")
$ComposeRedisServiceCandidates = @("redis","my-redis")

$HealthUrl = "http://app:8080/actuator/health"
$HealthTimeoutSec = 300
$WarmupDuration = "30s"
$DURATION = "3m"
$CoolDownSec = 20

# Prometheus
$EnablePrometheus = $true
$PrometheusUrl    = "http://localhost:9090"
$PgDatnameFilter  = "api-tuning"

Write-Host ("Selected: Fixed Load (RPS={0})" -f $RateOrdersMe)

# -------------------------
# Helpers
# -------------------------
function Wait-For-Container-Health($serviceName, $timeoutSec) {
  $start = Get-Date
  while (((Get-Date) - $start).TotalSeconds -lt $timeoutSec) {
    $cid = (docker compose ps -q $serviceName) 2>$null
    $cid = "$cid".Trim()
    if (-not $cid) { Start-Sleep -Seconds 1; continue }
    try {
      $inspect = docker inspect $cid | ConvertFrom-Json
      $state = $inspect[0].State
      if ($state.Health -and $state.Health.Status -eq "healthy") { return $true }
      if ($state.Status -eq "exited") { return $false }
    } catch {}
    Start-Sleep -Seconds 2
  }
  return $false
}

function Get-Compose-Network([string]$serviceName="app") {
  $cid = (docker compose ps -q $serviceName) 2>$null
  $cid = "$cid".Trim()
  if (-not $cid) { return $null }
  $inspect = docker inspect $cid | ConvertFrom-Json
  return ($inspect[0].NetworkSettings.Networks.PSObject.Properties.Name | Select-Object -First 1)
}

function Wait-For-Health-InDocker($url, $timeoutSec, [string]$serviceName="app") {
  $net = Get-Compose-Network -serviceName $serviceName
  if (-not $net) { Write-Host "ERROR: compose network not found"; return $false }
  $start = Get-Date
  while (((Get-Date) - $start).TotalSeconds -lt $timeoutSec) {
    $code = docker run --rm --network $net curlimages/curl:8.10.1 `
      sh -lc "curl -s -o /dev/null -w '%{http_code}' $url" 2>$null
    if ($LASTEXITCODE -eq 0 -and $code -eq "200") { Write-Host "App is healthy (HTTP 200)."; return $true }
    Start-Sleep -Seconds 2
  }
  return $false
}

function Convert-ToBytes([string]$s) {
  if (-not $s) { return 0 }
  $s = ($s -replace ',', '').Trim()
  if ($s -match '^(?<num>[0-9]*\.?[0-9]+)\s*(?<unit>[A-Za-z]+)?$') {
    $num = [double]$matches['num']; $unit = $matches['unit']
    switch -Regex ($unit) {
      '^B$'             { return [double]$num }
      '^(?:[Kk]B|KiB)$' { return [double]($num * 1KB) }
      '^(?:[Mm]B|MiB)$' { return [double]($num * 1MB) }
      '^(?:[Gg]B|GiB)$' { return [double]($num * 1GB) }
      default           { return [double]$num }
    }
  }
  return 0
}
function To-Double($v) { try { return [double]::Parse("$v", [Globalization.CultureInfo]::InvariantCulture) } catch { return $null } }
function Fmt([object]$v, [string]$format = '0.##') { $d = To-Double $v; if ($null -eq $d) { return '0' } $d.ToString($format, [Globalization.CultureInfo]::InvariantCulture) }
function B2MiB([object]$bytes, [string]$format = '0.00') { $d = To-Double $bytes; if ($null -eq $d) { return '0.00' } ($d / 1MB).ToString($format, [Globalization.CultureInfo]::InvariantCulture) }

# compose maps
function Get-Compose-Maps() {
  $lines = docker compose ps --format "{{.Service}} {{.Name}}" 2>$null
  $serviceToName = @{}
  $nameToService = @{}
  foreach ($line in $lines) {
    if (-not $line) { continue }
    $parts = $line -split "\s+"
    if ($parts.Length -ge 2) {
      $svc = $parts[0]; $name = $parts[1]
      $serviceToName[$svc] = $name
      $nameToService[$name] = $svc
    }
  }
  return @{ serviceToName = $serviceToName; nameToService = $nameToService }
}

function Resolve-Service([string[]]$candidates, $maps) {
  foreach ($c in $candidates) {
    if ($maps.serviceToName.ContainsKey($c)) { return $c }
    if ($maps.nameToService.ContainsKey($c)) { return $maps.nameToService[$c] }
  }
  return $null
}

function Resolve-ContainersForServices([string[]]$serviceNames, $maps) {
  $out = @()
  foreach ($svc in $serviceNames) {
    if ($maps.serviceToName.ContainsKey($svc)) { $out += $maps.serviceToName[$svc] }
  }
  $out | Select-Object -Unique
}

# -------------------------
# Prometheus helpers (always numeric; fallback=0)
# -------------------------
Add-Type -AssemblyName System.Web
function UrlEncode([string]$s) { [System.Web.HttpUtility]::UrlEncode($s) }

function Get-PromQL([string]$q, [string]$base=$PrometheusUrl) {
  try {
    $u = "$base/api/v1/query?query=$(UrlEncode $q)"
    $r = Invoke-RestMethod -Uri $u -Method GET -TimeoutSec 5
    if ($r.status -ne 'success') { return @() }
    return @($r.data.result)
  } catch { return @() }
}

function Sum-Prom([string]$q) {
  $res = Get-PromQL $q
  if ($res.Count -eq 0) { return 0.0 }
  ($res | ForEach-Object { [double]$_.value[1] } | Measure-Object -Sum).Sum
}

function First-Prom([string]$q) {
  $res = Get-PromQL $q
  if ($res.Count -eq 0) { return 0.0 }
  return [double]$res[0].value[1]
}

function Get-ApplicationMetrics() {
  # Hikari
  $hk_active  = Sum-Prom 'hikaricp_connections_active'
  $hk_idle    = Sum-Prom 'hikaricp_connections_idle'
  $hk_pending = Sum-Prom 'hikaricp_connections_pending'
  $hk_max     = First-Prom 'max(hikaricp_connections_max)'

  # JVM
  $heap_used_mb = (Sum-Prom 'jvm_memory_used_bytes{area="heap"}') / 1MB
  $heap_max_mb  = (Sum-Prom 'jvm_memory_max_bytes{area="heap"}') / 1MB
  $gc_ms_s      = (Sum-Prom 'rate(jvm_gc_pause_seconds_sum[1m])') * 1000
  $gc_cnt_s     = (Sum-Prom 'rate(jvm_gc_pause_seconds_count[1m])')

  # PostgreSQL
  $pg_active = Sum-Prom "pg_stat_activity_count{state='active'} or pg_stat_activity{state='active'} or sum(pg_stat_database_numbackends{datname='$PgDatnameFilter'})"
  $pg_tps    = Sum-Prom "rate(pg_stat_database_xact_commit{datname='$PgDatnameFilter'}[1m]) + rate(pg_stat_database_xact_rollback{datname='$PgDatnameFilter'}[1m])"
  $calls     = Sum-Prom 'pg_stat_statements_calls'
  $total_s   = Sum-Prom 'pg_stat_statements_total_time_seconds'
  $pg_avg_ms = if ($calls -gt 0) { ($total_s / $calls) * 1000 } else { 0.0 }

  # Redis
  $redis_mb  = (Sum-Prom 'redis_memory_used_bytes') / 1MB
  $hits      = Sum-Prom 'rate(redis_keyspace_hits_total[1m])'
  $miss      = Sum-Prom 'rate(redis_keyspace_misses_total[1m])'
  $den       = [Math]::Max(1e-9, $hits + $miss)
  $hit_rate  = $hits / $den

  return [pscustomobject]@{
    timestamp_utc          = (Get-Date).ToUniversalTime().ToString('o')
    hikari_active          = [double]$hk_active
    hikari_idle            = [double]$hk_idle
    hikari_pending         = [double]$hk_pending
    hikari_max             = [double]$hk_max
    jvm_heap_used_mb       = [double]$heap_used_mb
    jvm_heap_max_mb        = [double]$heap_max_mb
    gc_pause_ms_per_s      = [double]$gc_ms_s
    gc_pause_events_per_s  = [double]$gc_cnt_s
    pg_active_connections  = [double]$pg_active
    pg_avg_query_time_ms   = [double]$pg_avg_ms
    pg_tps                 = [double]$pg_tps
    redis_used_memory_mb   = [double]$redis_mb
    redis_hit_rate         = [double]$hit_rate
  }
}

# -------------------------
# Sampler (external process)
# -------------------------
function Start-Stats-Sampler([string[]]$serviceNames, [int]$intervalSec, [string]$csvPath) {
  $maps = Get-Compose-Maps
  $containers = @()
  if ($serviceNames -and $serviceNames.Count -gt 0) { $containers = Resolve-ContainersForServices $serviceNames $maps }
  if ($containers.Count -eq 0) {
    $containers = @($maps.serviceToName.Values) | Select-Object -Unique
    if ($containers.Count -gt 0) { Write-Host ("INFO: fallback to all compose containers: {0}" -f ($containers -join ', ')) } else { Write-Host "WARN: no containers found for sampling."; return $null }
  }

  try { $dockerExe = (Get-Command docker -ErrorAction Stop).Source } catch { Write-Host "ERROR: docker CLI not found in PATH"; return $null }

  if ([string]::IsNullOrWhiteSpace($csvPath)) { throw "csvPath is empty" }
  $csvDir = Split-Path -Parent $csvPath
  if (-not (Test-Path $csvDir)) { New-Item -ItemType Directory -Path $csvDir -Force | Out-Null }
  if (-not (Test-Path $csvPath)) {
    "timestamp,container,cpu_percent,mem_used_b,mem_limit_b,mem_percent,net_rx_b,net_tx_b,blk_read_b,blk_write_b,pids" | Out-File -FilePath $csvPath -Encoding utf8
  }

  $containersLiteral = ($containers | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ', '
  $csvEsc = $csvPath -replace "'", "''"
  $dockerEsc = $dockerExe -replace "'", "''"

  $psTemplate = @'
$containers = @(__CONTAINERS__)
$interval = __INTERVAL__
$csv = '__CSV__'
$docker = '__DOCKER__'

function Convert-ToBytes([string]$s) {
  if (-not $s) { return 0 }
  $s = ($s -replace ',', '').Trim()
  if ($s -match '^(?<num>[0-9]*\.?[0-9]+)\s*(?<unit>[A-Za-z]+)?$') {
    $num = [double]$matches['num']; $unit = $matches['unit']
    switch -Regex ($unit) {
      '^B$'             { return [double]$num }
      '^(?:[Kk]B|KiB)$' { return [double]($num * 1KB) }
      '^(?:[Mm]B|MiB)$' { return [double]($num * 1MB) }
      '^(?:[Gg]B|GiB)$' { return [double]($num * 1GB) }
      default           { return [double]$num }
    }
  }
  return 0
}

while ($true) {
  try {
    $fmt = '{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}'
    $raw = & "$docker" stats --no-stream --format $fmt 2>$null
    $ts = (Get-Date).ToString('o')

    foreach ($line in $raw) {
      $cols = $line -split ','
      if ($cols.Count -lt 7) { continue }
      $name = $cols[0].Trim()
      if ($containers -notcontains $name) { continue }

      $cpuPct = ($cols[1] -replace '%','').Trim()

      $mu = $cols[2] -split '/'
      $memUsedStr  = $mu[0].Trim()
      $memLimitStr = if ($mu.Count -ge 2) { $mu[1].Trim() } else { "0B" }
      $memUsedB  = Convert-ToBytes $memUsedStr
      $memLimitB = Convert-ToBytes $memLimitStr

      $memPct = ($cols[3] -replace '%','').Trim()

      $net = $cols[4] -split '/'
      $netRxStr = $net[0].Trim()
      $netTxStr = if ($net.Count -ge 2) { $net[1].Trim() } else { "0B" }
      $netRxB = Convert-ToBytes $netRxStr
      $netTxB = Convert-ToBytes $netTxStr

      $bio = $cols[5] -split '/'
      $blkReadStr  = $bio[0].Trim()
      $blkWriteStr = if ($bio.Count -ge 2) { $bio[1].Trim() } else { "0B" }
      $blkReadB  = Convert-ToBytes $blkReadStr
      $blkWriteB = Convert-ToBytes $blkWriteStr

      $pids = [int]($cols[6].Trim())

      "$ts,$name,$cpuPct,$memUsedB,$memLimitB,$memPct,$netRxB,$netTxB,$blkReadB,$blkWriteB,$pids" | Add-Content -Path $csv -Encoding utf8
    }
  } catch {}
  Start-Sleep -Seconds $interval
}
'@

  $psCode = $psTemplate.
    Replace('__CONTAINERS__', $containersLiteral).
    Replace('__INTERVAL__', [string]$intervalSec).
    Replace('__CSV__', $csvEsc).
    Replace('__DOCKER__', $dockerEsc)

  $tmpScript = Join-Path $env:TEMP ("stats-sampler-{0}-{1}.ps1" -f $PID, (Get-Random))
  Set-Content -Path $tmpScript -Value $psCode -Encoding UTF8

  $psExe = Join-Path $PSHOME 'powershell.exe'
  $proc = Start-Process -FilePath $psExe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', $tmpScript) -WindowStyle Hidden -PassThru
  return $proc
}

function Stop-Stats-Sampler($proc) { if ($proc) { try { if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } } catch {} } }

# -------------------------
# Metrics summarizer
# -------------------------
function Summarize-Metrics([string]$csvPath, [string]$jsonPath) {
  if ([string]::IsNullOrWhiteSpace($csvPath))  { throw "csvPath is empty" }
  if ([string]::IsNullOrWhiteSpace($jsonPath)) { throw "jsonPath is empty" }

  if (-not (Test-Path $csvPath)) {
    '[{"samples":0,"note":"metrics CSV not found"}]' | Out-File -FilePath $jsonPath -Encoding utf8
    return
  }
  $rows = Import-Csv -Path $csvPath
  if (-not $rows -or $rows.Count -eq 0) {
    '[{"samples":0,"note":"no samples"}]' | Out-File -FilePath $jsonPath -Encoding utf8
    return
  }

  $byContainer = $rows | Group-Object container
  $summary = @()

  foreach ($g in $byContainer) {
    $arr = $g.Group
    if (-not $arr -or $arr.Count -eq 0) { continue }

    $cpu = $arr | ForEach-Object { [double]$_.cpu_percent }
    $memPct = $arr | ForEach-Object { [double]$_.mem_percent }
    $memUsed = $arr | ForEach-Object { [double]$_.mem_used_b }
    $memLimit = $arr | ForEach-Object { [double]$_.mem_limit_b }
    $blkRead = $arr | ForEach-Object { [double]$_.blk_read_b }
    $blkWrite = $arr | ForEach-Object { [double]$_.blk_write_b }

    $t0 = Get-Date ($arr[0].timestamp)
    $tN = Get-Date ($arr[$arr.Count-1].timestamp)
    $secs = [math]::Max(1, [int](($tN - $t0).TotalSeconds))

    function Percentile([double[]]$xs, [double]$p) {
      if (-not $xs -or $xs.Count -eq 0) { return 0 }
      $sorted = $xs | Sort-Object
      $idx = [int][math]::Round(($sorted.Count - 1) * $p)
      return $sorted[$idx]
    }

    $totalRead  = [math]::Max(0, ($blkRead[$blkRead.Count-1]  - $blkRead[0]))
    $totalWrite = [math]::Max(0, ($blkWrite[$blkWrite.Count-1] - $blkWrite[0]))

    $summary += [pscustomobject]@{
      container                  = $g.Name
      samples                    = $arr.Count
      window_seconds             = $secs
      cpu_percent_avg            = [math]::Round(($cpu | Measure-Object -Average).Average, 2)
      cpu_percent_p95            = [math]::Round((Percentile $cpu 0.95), 2)
      cpu_percent_max            = [math]::Round(($cpu | Measure-Object -Maximum).Maximum, 2)
      mem_percent_avg            = [math]::Round(($memPct | Measure-Object -Average).Average, 2)
      mem_percent_max            = [math]::Round(($memPct | Measure-Object -Maximum).Maximum, 2)
      mem_used_peak_bytes        = [long]($memUsed | Measure-Object -Maximum).Maximum
      mem_limit_bytes            = [long]($memLimit | Select-Object -First 1)
      block_io_total_read_bytes  = [long]$totalRead
      block_io_total_write_bytes = [long]$totalWrite
      block_io_read_bps          = [int]([math]::Round($totalRead / $secs))
      block_io_write_bps         = [int]([math]::Round($totalWrite / $secs))
    }
  }

  ,$summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8
}

# -------------------------
# k6 JSON helpers + MD report
# -------------------------
function Get-JsonSafe([string]$path) { if (-not (Test-Path $path)) { return $null } try { return (Get-Content -Raw -Path $path | ConvertFrom-Json) } catch { return $null } }
function Get-MetricField($metricsObj, [string]$metricName, [string]$fieldName) {
  if ($null -eq $metricsObj) { return $null }
  $mProp = $metricsObj.PSObject.Properties[$metricName]; if ($null -eq $mProp) { return $null }
  $m = $mProp.Value
  $top = $m.PSObject.Properties[$fieldName]; if ($null -ne $top) { return $top.Value }
  $valuesProp = $m.PSObject.Properties['values']
  if ($null -ne $valuesProp) { $vals = $valuesProp.Value; $f = $vals.PSObject.Properties[$fieldName]; if ($null -ne $f) { return $f.Value } }
  return $null
}

function Generate-MarkdownReport([int]$poolSize, [string]$outputsDir) {
  $k6Path        = Join-Path $outputsDir ("order-me-{0}.json" -f $poolSize)
  $metricsPath   = Join-Path $outputsDir ("order-me-{0}.metrics.json" -f $poolSize)   # 기본
  $metricsAlt    = Join-Path $outputsDir ("order-me-{0}.metric.json"  -f $poolSize)   # 대체(단수)
  $csvPath       = Join-Path $outputsDir ("order-me-{0}.samples.csv" -f $poolSize)
  $promPath      = Join-Path $outputsDir ("order-me-{0}.prom.json" -f $poolSize)
  $mdPath        = Join-Path $outputsDir ("order-me-{0}.md" -f $poolSize)

  $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss K")
  $md = @()
  $md += ('# Benchmark Report - Pool Size {0} (Orders/Me Only)' -f $poolSize)
  $md += ''
  $md += ('- **Load Level**: Fixed (RPS={0})' -f $RateOrdersMe)
  $md += ('- **Generated at**: {0}' -f $now)
  $md += ''

  # ---------- k6 ----------
  $md += '## k6 Results'
  if (Test-Path $k6Path) {
    $k6 = Get-JsonSafe $k6Path
    if ($null -ne $k6 -and $null -ne $k6.metrics) {
      $m = $k6.metrics
      $avg = Get-MetricField $m 'http_req_duration' 'avg'
      $med = Get-MetricField $m 'http_req_duration' 'med'
      $max = Get-MetricField $m 'http_req_duration' 'max'
      $p95 = Get-MetricField $m 'http_req_duration' 'p(95)'
      $p99 = Get-MetricField $m 'http_req_duration' 'p(99)'
      $reqCount = Get-MetricField $m 'http_reqs' 'count'
      $reqRate  = Get-MetricField $m 'http_reqs' 'rate'
      $failRate = Get-MetricField $m 'http_req_failed' 'rate'
      $checksPass = Get-MetricField $m 'checks' 'passes'
      $checksFail = Get-MetricField $m 'checks' 'fails'
      $orderP50 = Get-MetricField $m 'order_me_duration' 'p(50)'
      $orderP95 = Get-MetricField $m 'order_me_duration' 'p(95)'
      $orderP99 = Get-MetricField $m 'order_me_duration' 'p(99)'
      $orderErr = Get-MetricField $m 'order_me_errors' 'count'

      $md += ''
      $md += '| Metric | Value |'
      $md += '|---|---:|'
      $md += ('| http_req_duration p95 (ms) | {0} |' -f (Fmt $p95 '0.00'))
      $md += ('| http_req_duration p99 (ms) | {0} |' -f (Fmt $p99 '0.00'))
      $md += ('| avg / med / max (ms) | {0} / {1} / {2} |' -f (Fmt $avg '0.00'), (Fmt $med '0.00'), (Fmt $max '0.00'))
      $md += ('| http_reqs count | {0} |' -f (Fmt $reqCount '0'))
      $md += ('| http_reqs rate (req/s) | {0} |' -f (Fmt $reqRate '0.00'))
      $md += ('| http_req_failed (%) | {0} |' -f ($(if ($null -ne $failRate) { (Fmt (([double]$failRate) * 100.0) '0.00') } else { '0.00' })))
      $md += ('| checks (passes / fails) | {0} / {1} |' -f ($(if ($checksPass) { $checksPass } else { 0 })), ($(if ($checksFail) { $checksFail } else { 0 })))

      $md += ''
      $md += '### Orders/Me Latency (ms)'
      $md += ''
      $md += '| p50 | p95 | p99 | errors |'
      $md += '|---:|---:|---:|---:|'
      $md += ('| {0} | {1} | {2} | {3} |' -f (Fmt $orderP50 '0.00'), (Fmt $orderP95 '0.00'), (Fmt $orderP99 '0.00'), (Fmt $orderErr '0'))
      $md += ''
    } else { $md += '_k6 JSON parsed but no metrics found_'; $md += '' }
  } else { $md += ('_k6 summary file not found: `{0}`_' -f (Split-Path -Leaf $k6Path)); $md += '' }

  # ---------- System Metrics ----------
  $md += '## System Metrics (Docker containers)'

  $metricsPathToUse = $(if (Test-Path $metricsAlt) { $metricsAlt } else { $metricsPath })
  if (Test-Path $metricsPathToUse) {
    $raw = Get-JsonSafe $metricsPathToUse
    $arr = $null
    if ($null -ne $raw) {
      if ($raw.PSObject.Properties.Name -contains 'value' -and $raw.value) {
        $arr = @($raw.value)   # 래핑형식 { value:[...] }
      } elseif ($raw -is [System.Array]) {
        $arr = @($raw)         # 배열형식 [...]
      } elseif ($raw.samples -or $raw.container) {
        $arr = @($raw)         # 단일 객체
      }
    }
    if ($arr -and $arr.Count -gt 0) {
      foreach ($c in $arr) {
        $md += ''
        $md += ('### {0}' -f $c.container)
        $md += ''
        $md += ('Samples: **{0}** over **{1}s**' -f $c.samples, $c.window_seconds)
        $md += ''
        $md += '| Metric | Value |'
        $md += '|---|---:|'
        $md += ('| CPU avg / p95 / max (%) | {0} / {1} / {2} |' -f (Fmt $c.cpu_percent_avg), (Fmt $c.cpu_percent_p95), (Fmt $c.cpu_percent_max))
        $md += ('| Mem avg / max (%) | {0} / {1} |' -f (Fmt $c.mem_percent_avg), (Fmt $c.mem_percent_max))
        $md += ('| Mem peak / limit (MiB) | {0} / {1} |' -f (B2MiB $c.mem_used_peak_bytes), (B2MiB $c.mem_limit_bytes))
        $md += ('| Block I/O total (read / write, MiB) | {0} / {1} |' -f (B2MiB $c.block_io_total_read_bytes), (B2MiB $c.block_io_total_write_bytes))
        $md += ('| Block I/O throughput (read / write, B/s) | {0} / {1} |' -f (Fmt $c.block_io_read_bps '0'), (Fmt $c.block_io_write_bps '0'))
      }
      $md += ''
    } else {
      $md += '_no container samples in window_'
      $md += ''
    }
  } else {
    $md += ('_metrics summary not found: `{0}` or `{1}`_' -f (Split-Path -Leaf $metricsPath), (Split-Path -Leaf $metricsAlt))
    $md += ''
  }

  # ---------- Service Metrics (Prometheus) ----------
  $md += '## Service Metrics (Prometheus)'
  $pm = $null
  if (Test-Path $promPath) { $pm = Get-JsonSafe $promPath }
  if ($null -eq $pm) {
    $pm = [pscustomobject]@{
      hikari_active=0; hikari_idle=0; hikari_pending=0; hikari_max=0;
      jvm_heap_used_mb=0; jvm_heap_max_mb=0; gc_pause_ms_per_s=0; gc_pause_events_per_s=0;
      pg_active_connections=0; pg_avg_query_time_ms=0; pg_tps=0;
      redis_used_memory_mb=0; redis_hit_rate=0
    }
  }
  $md += ''
  $md += '### HikariCP'
  $md += ''
  $md += '| active | idle | pending | max |'
  $md += '|---:|---:|---:|---:|'
  $md += ('| {0} | {1} | {2} | {3} |' -f (Fmt $pm.hikari_active '0'), (Fmt $pm.hikari_idle '0'), (Fmt $pm.hikari_pending '0'), (Fmt $pm.hikari_max '0'))
  $md += ''
  $md += '### JVM'
  $md += ''
  $md += '| heap used (MiB) | heap max (MiB) | GC pause ms/s | GC events/s |'
  $md += '|---:|---:|---:|---:|'
  $md += ('| {0} | {1} | {2} | {3} |' -f (Fmt $pm.jvm_heap_used_mb '0.00'), (Fmt $pm.jvm_heap_max_mb '0.00'), (Fmt $pm.gc_pause_ms_per_s '0.00'), (Fmt $pm.gc_pause_events_per_s '0.00'))
  $md += ''
  $md += '### PostgreSQL'
  $md += ''
  $md += '| active connections | avg query time (ms) | TPS |'
  $md += '|---:|---:|---:|'
  $md += ('| {0} | {1} | {2} |' -f (Fmt $pm.pg_active_connections '0'), (Fmt $pm.pg_avg_query_time_ms '0.00'), (Fmt $pm.pg_tps '0.00'))
  $md += ''
  $md += '### Redis'
  $md += ''
  $md += '| used memory (MiB) | hit rate |'
  $md += '|---:|---:|'
  $md += ('| {0} | {1} |' -f (Fmt $pm.redis_used_memory_mb '0.00'), (Fmt $pm.redis_hit_rate '0.000'))
  $md += ''

  # ---------- Artifacts ----------
  $md += '## Artifacts'
  $md += ''
  $md += ('- k6 JSON: `{0}`' -f (Split-Path -Leaf $k6Path))
  if (Test-Path $metricsPath) { $md += ('- system metrics JSON: `{0}`' -f (Split-Path -Leaf $metricsPath)) }
  if (Test-Path $metricsAlt)  { $md += ('- system metrics JSON: `{0}`' -f (Split-Path -Leaf $metricsAlt)) }
  $md += ('- system samples CSV: `{0}`' -f (Split-Path -Leaf $csvPath))
  if (Test-Path $promPath) { $md += ('- prometheus snapshot JSON: `{0}`' -f (Split-Path -Leaf $promPath)) }

  $mdStr = [string]::Join([System.Environment]::NewLine, $md)
  Set-Content -Path $mdPath -Value $mdStr -Encoding UTF8
  Write-Host ("Markdown report -> {0}" -f $mdPath)
}

# -------------------------
# Main Test Loop
# -------------------------
foreach ($poolSize in $poolSizes) {
  Write-Host ""
  Write-Host "========================================="
  Write-Host ("Testing Pool Size: {0} (ORDERS/ME ONLY)" -f $poolSize)
  Write-Host "========================================="

  $env:HIKARI_MAX_POOL_SIZE = $poolSize
  $env:HIKARI_MIN_IDLE      = [Math]::Floor($poolSize / 2)
  $env:SERVER_MAX_THREADS   = $ThreadMax

  $maps = Get-Compose-Maps
  $appService = Resolve-Service $ComposeAppServiceCandidates $maps
  if (-not $appService) { $appService = "app" }  # fallback

  if ($ResetDb) {
    $dbService = Resolve-Service $ComposeDbServiceCandidates $maps
    if ($dbService) {
      Write-Host "Recreating DB container..."
      docker compose stop $dbService | Out-Null
      docker compose rm -f $dbService | Out-Null
      docker compose up -d --force-recreate --renew-anon-volumes $dbService
      Write-Host ("Waiting for {0} health..." -f $dbService)
      if (-not (Wait-For-Container-Health -serviceName $dbService -timeoutSec 180)) {
        Write-Host ("ERROR: {0} not healthy" -f $dbService); docker compose logs $dbService --tail 200; exit 1
      }
    }
  }

  Write-Host "Recreating app container..."
  docker compose stop $appService | Out-Null
  docker compose rm -f $appService | Out-Null
  docker compose up -d --force-recreate --renew-anon-volumes $appService

  Write-Host "Waiting for app (compose health)..."
  if (-not (Wait-For-Container-Health -serviceName $appService -timeoutSec 180)) {
    Write-Host "=== App logs ==="; docker compose logs $appService --tail 200
    Write-Host "ERROR: app not healthy by compose"; exit 1
  }

  Write-Host "Verifying actuator health (in-docker)..."
  if (-not (Wait-For-Health-InDocker -url $HealthUrl -timeoutSec $HealthTimeoutSec -serviceName $appService)) {
    Write-Host "=== App logs ==="; docker compose logs $appService --tail 200
    Write-Host "ERROR: Actuator health not UP"; exit 1
  }

  # Start sampler (app + db + redis), 2s
  $root = (Resolve-Path $outputsPath).Path
  $samplesCsv  = Join-Path $root ("order-me-{0}.samples.csv" -f $poolSize)
  $metricsJson = Join-Path $root ("order-me-{0}.metrics.json" -f $poolSize)
  $promJson    = Join-Path $root ("order-me-{0}.prom.json" -f $poolSize)

  $dbService    = Resolve-Service $ComposeDbServiceCandidates $maps
  $redisService = Resolve-Service $ComposeRedisServiceCandidates $maps

  $servicesForSampling = @()
  $servicesForSampling += $appService
  if ($dbService)    { $servicesForSampling += $dbService }
  if ($redisService) { $servicesForSampling += $redisService }

  $samplerProc = Start-Stats-Sampler -serviceNames $servicesForSampling -intervalSec 2 -csvPath $samplesCsv
  if ($samplerProc) { Write-Host ("Metrics sampler started (2s interval) -> {0}" -f $samplesCsv) }

  # Run k6
  $summaryFile = "/outputs/order-me-$poolSize.json"
  Write-Host "Running k6 (orders/me only)..."
  docker compose run --rm `
    -e BASE_URL=http://app:8080 `
    -e POOL_SIZE=$poolSize `
    -e THREAD_SIZE=$ThreadMax `
    -e TEST_DURATION=$DURATION `
    -e WARMUP_DURATION=$WarmupDuration `
    -e RATE_ORDER_ME=$RateOrdersMe `
    -e MEMBER_ID_MIN=1 -e MEMBER_ID_MAX=10000 `
    -e DISABLE_THRESHOLDS=true `
    -e VERBOSE_ERRORS=false `
    -e LOG_4XX=true `
    -e SAMPLE_LIMIT=100 `
    -e K6_LOG_LEVEL=info `
    -v "$($outputsPath):/outputs" `
    k6 run --summary-export $summaryFile /scripts/order-me-only.js

  $k6Exit = $LASTEXITCODE

  # Stop sampler and summarize
  Stop-Stats-Sampler $samplerProc
  Summarize-Metrics -csvPath $samplesCsv -jsonPath $metricsJson
  if (Test-Path $metricsJson) { Write-Host ("Metrics summary -> {0}" -f $metricsJson) }

  # Prometheus snapshot (always write numbers; fallback=0)
  if ($EnablePrometheus) {
    try {
      $snapshot = Get-ApplicationMetrics
      if (-not $snapshot) {
        $snapshot = [pscustomobject]@{
          timestamp_utc=(Get-Date).ToUniversalTime().ToString('o')
          hikari_active=0; hikari_idle=0; hikari_pending=0; hikari_max=0;
          jvm_heap_used_mb=0; jvm_heap_max_mb=0; gc_pause_ms_per_s=0; gc_pause_events_per_s=0;
          pg_active_connections=0; pg_avg_query_time_ms=0; pg_tps=0;
          redis_used_memory_mb=0; redis_hit_rate=0
        }
      }
      $snapshot | ConvertTo-Json -Depth 4 | Out-File -FilePath $promJson -Encoding utf8
      Write-Host ("Prometheus snapshot -> {0}" -f $promJson)
    } catch {
      [pscustomobject]@{
        timestamp_utc=(Get-Date).ToUniversalTime().ToString('o')
        hikari_active=0; hikari_idle=0; hikari_pending=0; hikari_max=0;
        jvm_heap_used_mb=0; jvm_heap_max_mb=0; gc_pause_ms_per_s=0; gc_pause_events_per_s=0;
        pg_active_connections=0; pg_avg_query_time_ms=0; pg_tps=0;
        redis_used_memory_mb=0; redis_hit_rate=0
      } | ConvertTo-Json -Depth 3 | Out-File -FilePath $promJson -Encoding utf8
      Write-Host "WARN: Prometheus snapshot fallback -> zeros"
    }
  }

  if ($k6Exit -ne 0) { Write-Host ("ERROR: k6 run failed for pool {0}" -f $poolSize); exit 1 }

  # Markdown
  Generate-MarkdownReport -poolSize $poolSize -outputsDir $outputsPath

  Write-Host ("Cooling down ({0} s)..." -f $CoolDownSec)
  Start-Sleep -Seconds $CoolDownSec
}

Write-Host ""
Write-Host "======================================"
Write-Host "All tests completed!"
Write-Host "======================================"

Write-Host "Checking results..."
foreach ($poolSize in $poolSizes) {
  $resultFile   = ".\perf\k6\outputs\order-me-$poolSize.json"
  $metricsFile  = ".\perf\k6\outputs\order-me-$poolSize.metrics.json"
  $metricsFile2 = ".\perf\k6\outputs\order-me-$poolSize.metric.json"
  $samplesFile  = ".\perf\k6\outputs\order-me-$poolSize.samples.csv"
  $promFile     = ".\perf\k6\outputs\order-me-$poolSize.prom.json"
  $mdFile       = ".\perf\k6\outputs\order-me-$poolSize.md"

  $ok1 = if (Test-Path $resultFile)  { "OK" } else { "MISS" }
  $ok2 = if (Test-Path $metricsFile -or Test-Path $metricsFile2) { "OK" } else { "MISS" }
  $ok3 = if (Test-Path $samplesFile) { "OK" } else { "MISS" }
  $ok5 = if (Test-Path $promFile)    { "OK" } else { "MISS" }
  $ok4 = if (Test-Path $mdFile)      { "OK" } else { "MISS" }

  Write-Host ("[ {0} ] order-me-{1}.json"         -f $ok1, $poolSize)
  Write-Host ("[ {0} ] order-me-{1}.metrics(.metric).json" -f $ok2, $poolSize)
  Write-Host ("[ {0} ] order-me-{1}.samples.csv"  -f $ok3, $poolSize)
  Write-Host ("[ {0} ] order-me-{1}.prom.json"    -f $ok5, $poolSize)
  Write-Host ("[ {0} ] order-me-{1}.md"           -f $ok4, $poolSize)
}
