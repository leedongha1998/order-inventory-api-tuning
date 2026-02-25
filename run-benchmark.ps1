# run-benchmark.ps1
# Isolation-Friendly + System Metrics + Markdown Report
# PS 5.1 compatible, robust quoting & k6 latest summary-export support

Write-Host "======================================"
Write-Host "HikariCP Pool Size Performance Test (Isolated)"
Write-Host "======================================"

$scriptPath = ".\perf\k6\scenarios\pool-performance-test.js"
if (-not (Test-Path $scriptPath)) { Write-Host "ERROR: $scriptPath not found"; exit 1 }

$currentPath = (Get-Location).Path
$outputsPath = Join-Path $currentPath "perf\k6\outputs"
if (-not (Test-Path $outputsPath)) { New-Item -ItemType Directory -Path $outputsPath -Force | Out-Null }

# ===== Config =====
$poolSizes = @(10, 20, 30)      # 필요시 라운드로빈/셔플 권장
$ResetDb = $false                # true면 매 런 DB 재시작(테스트 전용)
$HealthUrl = "http://app:8080/actuator/health"  # compose 네트워크 내부 DNS명(app)
$HealthTimeoutSec = 300
$WarmupDuration = "30s"
$CoolDownSec = 20

Write-Host ""
Write-Host "Select Load Level:"
Write-Host "1. Light (100 req/s)"
Write-Host "2. Medium (500 req/s)"
Write-Host "3. Heavy (1000 req/s)"
$choice = Read-Host "Choice (1-3)"

switch ($choice) {
  "1" { $RATE_PRODUCTS=60;  $RATE_ORDER_DETAIL=30;  $RATE_ORDER_CREATE=10; $DURATION="2m"; $LOAD_NAME="Light" }
  "2" { $RATE_PRODUCTS=300; $RATE_ORDER_DETAIL=150; $RATE_ORDER_CREATE=50; $DURATION="3m"; $LOAD_NAME="Medium" }
  "3" { $RATE_PRODUCTS=600; $RATE_ORDER_DETAIL=300; $RATE_ORDER_CREATE=100; $DURATION="3m"; $LOAD_NAME="Heavy" }
  default { Write-Host "Invalid choice"; exit 1 }
}

Write-Host ("Selected: {0} Load" -f $LOAD_NAME)
Write-Host ("Total: {0} req/s" -f ($RATE_PRODUCTS + $RATE_ORDER_DETAIL + $RATE_ORDER_CREATE))

# -------------------------
# Helper Functions
# -------------------------

function Wait-For-Container-Health($serviceName, $timeoutSec) {
  $start = Get-Date
  while (((Get-Date) - $start).TotalSeconds -lt $timeoutSec) {
    $cid = (docker compose ps -q $serviceName).Trim()
    if (-not $cid) { Start-Sleep -Seconds 1; continue }
    try {
      $inspect = docker inspect $cid | ConvertFrom-Json
      $state = $inspect[0].State
      if ($state.Health -and $state.Health.Status -eq "healthy") { return $true }
      if ($state.Status -eq "exited") { return $false }
    } catch { }
    Start-Sleep -Seconds 2
  }
  return $false
}

function Get-Compose-Network() {
  $cid = (docker compose ps -q app).Trim()
  if (-not $cid) { return $null }
  $inspect = docker inspect $cid | ConvertFrom-Json
  return ($inspect[0].NetworkSettings.Networks.PSObject.Properties.Name | Select-Object -First 1)
}

function Wait-For-Health-InDocker($url, $timeoutSec) {
  $net = Get-Compose-Network
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

# Size string -> bytes (e.g., "10.5MiB", "1.2kB", "512B", "1.3GiB")
function Convert-ToBytes([string]$s) {
  if (-not $s) { return 0 }
  $s = ($s -replace ',', '').Trim()
  if ($s -match '^(?<num>[0-9]*\.?[0-9]+)\s*(?<unit>[A-Za-z]+)?$') {
    $num = [double]$matches['num']
    $unit = $matches['unit']
    switch -Regex ($unit) {
      '^B$'                     { return [double]$num }
      '^(?:[Kk]B|KiB)$'         { return [double]($num * 1KB) }
      '^(?:[Mm]B|MiB)$'         { return [double]($num * 1MB) }
      '^(?:[Gg]B|GiB)$'         { return [double]($num * 1GB) }
      default                   { return [double]$num }
    }
  }
  return 0
}

# -------- Formatting & Safe Number Helpers --------
function To-Double($v) {
  if ($null -eq $v) { return $null }
  try {
    if ($v -is [double]) { return $v }
    if ($v -is [single] -or $v -is [decimal] -or $v -is [int] -or $v -is [long]) { return [double]$v }
    return [double]::Parse("$v", [System.Globalization.CultureInfo]::InvariantCulture)
  } catch { return $null }
}

function Fmt([object]$v, [string]$format = '0.##') {
  $d = To-Double $v
  if ($null -eq $d) { return '-' }
  return $d.ToString($format, [System.Globalization.CultureInfo]::InvariantCulture)
}
function B2MiB([object]$bytes, [string]$format = '0.00') {
  $d = To-Double $bytes
  if ($null -eq $d) { return '-' }
  $mib = $d / 1MB
  return $mib.ToString($format, [System.Globalization.CultureInfo]::InvariantCulture)
}
function Try-GetProp($obj, [string]$prop) {
  if ($null -eq $obj) { return $null }
  $p = $obj.PSObject.Properties[$prop]
  if ($null -ne $p) { return $p.Value }
  return $null
}

# service -> container name
function Get-ContainerName-ForService([string]$service) {
  $lines = docker compose ps --format "{{.Name}} {{.Service}}"
  foreach ($line in $lines) {
    $parts = $line -split "\s+"
    if ($parts.Length -ge 2 -and $parts[1] -eq $service) {
      return $parts[0]
    }
  }
  return $null
}

# (manual check helper)
function Get-Docker-StatsSample([string[]]$containerNames) {
  if (-not $containerNames -or $containerNames.Count -eq 0) { return @() }
  $fmt = '{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}'
  $raw = docker stats --no-stream --format $fmt 2>$null
  $ts = (Get-Date).ToString('o')
  $rows = @()
  foreach ($line in $raw) {
    $cols = $line -split ','
    if ($cols.Count -lt 7) { continue }
    $name = $cols[0].Trim()
    if ($containerNames -notcontains $name) { continue }

    $cpuPct = ($cols[1] -replace '%','').Trim()

    $mu = $cols[2] -split '/'
    $memUsedStr  = $mu[0].Trim()
    $memLimitStr = "0B"
    if ($mu.Count -ge 2) { $memLimitStr = $mu[1].Trim() }
    $memUsedB  = Convert-ToBytes $memUsedStr
    $memLimitB = Convert-ToBytes $memLimitStr

    $memPct = ($cols[3] -replace '%','').Trim()

    $net = $cols[4] -split '/'
    $netRxStr = $net[0].Trim()
    $netTxStr = "0B"
    if ($net.Count -ge 2) { $netTxStr = $net[1].Trim() }
    $netRxB = Convert-ToBytes $netRxStr
    $netTxB = Convert-ToBytes $netTxStr

    $bio = $cols[5] -split '/'
    $blkReadStr  = $bio[0].Trim()
    $blkWriteStr = "0B"
    if ($bio.Count -ge 2) { $blkWriteStr = $bio[1].Trim() }
    $blkReadB  = Convert-ToBytes $blkReadStr
    $blkWriteB = Convert-ToBytes $blkWriteStr

    $pids = [int]($cols[6].Trim())

    $rows += [pscustomobject]@{
      timestamp   = $ts
      container   = $name
      cpu_percent = [double]$cpuPct
      mem_used_b  = [double]$memUsedB
      mem_limit_b = [double]$memLimitB
      mem_percent = [double]$memPct
      net_rx_b    = [double]$netRxB
      net_tx_b    = [double]$netTxB
      blk_read_b  = [double]$blkReadB
      blk_write_b = [double]$blkWriteB
      pids        = $pids
    }
  }
  return $rows
}

# =========================
# Sampler (external process)
# =========================
function Start-Stats-Sampler([string[]]$services, [int]$intervalSec, [string]$csvPath) {
  # services -> container names
  $containers = @()
  foreach ($s in $services) {
    $n = Get-ContainerName-ForService $s
    if ($n) { $containers += $n }
  }
  if ($containers.Count -eq 0) {
    Write-Host "WARN: no containers found for sampling."
    return $null
  }

  # docker.exe absolute path
  try {
    $dockerExe = (Get-Command docker -ErrorAction Stop).Source
  } catch {
    Write-Host "ERROR: docker CLI not found in PATH"; return $null
  }

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
    $num = [double]$matches['num']
    $unit = $matches['unit']
    switch -Regex ($unit) {
      '^B$'                   { return [double]$num }
      '^(?:[Kk]B|KiB)$'       { return [double]($num * 1KB) }
      '^(?:[Mm]B|MiB)$'       { return [double]($num * 1MB) }
      '^(?:[Gg]B|GiB)$'       { return [double]($num * 1GB) }
      default                 { return [double]$num }
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
      $memLimitStr = "0B"
      if ($mu.Count -ge 2) { $memLimitStr = $mu[1].Trim() }
      $memUsedB  = Convert-ToBytes $memUsedStr
      $memLimitB = Convert-ToBytes $memLimitStr

      $memPct = ($cols[3] -replace '%','').Trim()

      $net = $cols[4] -split '/'
      $netRxStr = $net[0].Trim()
      $netTxStr = "0B"
      if ($net.Count -ge 2) { $netTxStr = $net[1].Trim() }
      $netRxB = Convert-ToBytes $netRxStr
      $netTxB = Convert-ToBytes $netTxStr

      $bio = $cols[5] -split '/'
      $blkReadStr  = $bio[0].Trim()
      $blkWriteStr = "0B"
      if ($bio.Count -ge 2) { $blkWriteStr = $bio[1].Trim() }
      $blkReadB  = Convert-ToBytes $blkReadStr
      $blkWriteB = Convert-ToBytes $blkWriteStr

      $pids = [int]($cols[6].Trim())

      # numeric cast pre-computed
      $memUsedBLong  = [long]$memUsedB
      $memLimitBLong = [long]$memLimitB
      $netRxBLong    = [long]$netRxB
      $netTxBLong    = [long]$netTxB
      $blkReadBLong  = [long]$blkReadB
      $blkWriteBLong = [long]$blkWriteB

      "$ts,$name,$cpuPct,$memUsedBLong,$memLimitBLong,$memPct,$netRxBLong,$netTxBLong,$blkReadBLong,$blkWriteBLong,$pids" | Add-Content -Path $csv -Encoding utf8
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

  $psExe = Join-Path $PSHOME 'powershell.exe'   # PS 5.1
  $proc = Start-Process -FilePath $psExe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', $tmpScript) -WindowStyle Hidden -PassThru
  return $proc
}

function Stop-Stats-Sampler($proc) {
  if ($proc) {
    try {
      if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
    } catch {}
  }
}

# -------------------------
# Metrics -> JSON Summary
# -------------------------
function Summarize-Metrics([string]$csvPath, [string]$jsonPath) {
  if (-not (Test-Path $csvPath)) {
    '[{"samples":0,"note":"metrics CSV not found"}]' | Out-File -FilePath $jsonPath -Encoding utf8
    return
  }
  $rows = Import-Csv -Path $csvPath
  if (-not $rows -or $rows.Count -eq 0) {
    '[{"samples":0,"note":"no samples in CSV (sampler could not read docker?)"}]' | Out-File -FilePath $jsonPath -Encoding utf8
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

  if ($summary.Count -eq 0) {
    '[{"samples":0,"note":"no per-container data"}]' | Out-File -FilePath $jsonPath -Encoding utf8
  } else {
    $summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8
  }
}

# -------------------------
# k6 JSON helpers
# -------------------------
function Get-JsonSafe([string]$path) {
  if (-not (Test-Path $path)) { return $null }
  try { return (Get-Content -Raw -Path $path | ConvertFrom-Json) } catch { return $null }
}
# k6 metrics.*.values.* 접근 지원
function Get-MetricField($metricsObj, [string]$metricName, [string]$fieldName) {
  if ($null -eq $metricsObj) { return $null }
  $mProp = $metricsObj.PSObject.Properties[$metricName]
  if ($null -eq $mProp) { return $null }
  $m = $mProp.Value

  $top = $m.PSObject.Properties[$fieldName]
  if ($null -ne $top) { return $top.Value }

  $valuesProp = $m.PSObject.Properties['values']
  if ($null -ne $valuesProp) {
    $vals = $valuesProp.Value
    $f = $vals.PSObject.Properties[$fieldName]
    if ($null -ne $f) { return $f.Value }
  }
  return $null
}

# -------------------------
# Markdown Report Generator
# -------------------------
function Generate-MarkdownReport([int]$poolSize, [string]$outputsDir, [string]$loadName) {
  $k6Path      = Join-Path $outputsDir ("pool-{0}.json" -f $poolSize)
  $metricsPath = Join-Path $outputsDir ("pool-{0}.metrics.json" -f $poolSize)
  $csvPath     = Join-Path $outputsDir ("pool-{0}.samples.csv" -f $poolSize)
  $mdPath      = Join-Path $outputsDir ("pool-{0}.md" -f $poolSize)

  $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss K")
  $md = @()
  $md += ('# Benchmark Report - Pool Size {0}' -f $poolSize)
  $md += ''
  $md += ('- **Load Level**: {0}' -f $loadName)
  $md += ('- **Generated at**: {0}' -f $now)
  $md += ''

  # ---------- k6 ----------
  $md += '## k6 Results'
  if (Test-Path $k6Path) {
    $k6 = Get-JsonSafe $k6Path
    if ($null -ne $k6 -and $null -ne $k6.metrics) {
      $m = $k6.metrics

      # 현행 포맷: metrics.http_req_duration.values."p(95)" 등
      $avg = Get-MetricField $m 'http_req_duration' 'avg'
      $p90 = Get-MetricField $m 'http_req_duration' 'p(90)'
      $p95 = Get-MetricField $m 'http_req_duration' 'p(95)'
      $p99 = Get-MetricField $m 'http_req_duration' 'p(99)'
      $max = Get-MetricField $m 'http_req_duration' 'max'
      $min = Get-MetricField $m 'http_req_duration' 'min'
      $med = Get-MetricField $m 'http_req_duration' 'med'

      $reqCount = Get-MetricField $m 'http_reqs' 'count'
      $reqRate  = Get-MetricField $m 'http_reqs' 'rate'

      $failRate = Get-MetricField $m 'http_req_failed' 'rate'  # 0.01 => 1%
      $checksPass = Get-MetricField $m 'checks' 'passes'
      $checksFail = Get-MetricField $m 'checks' 'fails'
      if ($null -eq $checksPass -and $null -eq $checksFail) {
        $cObj = $m.PSObject.Properties['checks']
        if ($null -ne $cObj) {
          $checksPass = Try-GetProp $cObj.Value 'passes'
          $checksFail = Try-GetProp $cObj.Value 'fails'
        }
      }

      $md += ''
      $md += '| Metric | Value |'
      $md += '|---|---:|'
      $md += ('| http_req_duration p95 (ms) | {0} |' -f (Fmt $p95 '0.00'))
      $md += ('| http_req_duration p99 (ms) | {0} |' -f (Fmt $p99 '0.00'))
      $md += ('| avg / med / max (ms) | {0} / {1} / {2} |' -f (Fmt $avg '0.00'), (Fmt $med '0.00'), (Fmt $max '0.00'))
      $md += ('| http_reqs count | {0} |' -f (Fmt $reqCount '0'))
      $md += ('| http_reqs rate (req/s) | {0} |' -f (Fmt $reqRate '0.00'))
      if ($null -ne $failRate) {
        $md += ('| http_req_failed (%) | {0} |' -f (Fmt ((To-Double $failRate) * 100.0) '0.00'))
      } else {
        $md += '| http_req_failed (%) | - |'
      }
      if ($null -ne $checksPass -or $null -ne $checksFail) {
        $md += ('| checks (passes / fails) | {0} / {1} |' -f (Fmt $checksPass '0'), (Fmt $checksFail '0'))
      }
      $md += ''
    } else {
      $md += ('_k6 JSON parsed but no metrics found_')
      $md += ''
    }
  } else {
    $md += ('_k6 summary file not found: `{0}`_' -f (Split-Path -Leaf $k6Path))
    $md += ''
  }

  # ---------- System Metrics ----------
  $md += '## System Metrics (Docker containers)'
  if (Test-Path $metricsPath) {
    $arr = Get-JsonSafe $metricsPath
    if ($null -ne $arr -and $arr.Count -gt 0) {
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
      $md += '_metrics JSON parsed but no container entries_'
      $md += ''
    }
  } else {
    $md += ('_metrics summary not found: `{0}`_' -f (Split-Path -Leaf $metricsPath))
    $md += ''
  }

  # ---------- Artifacts ----------
  $md += '## Artifacts'
  $md += ''
  $md += ('- k6 JSON: `{0}`' -f (Split-Path -Leaf $k6Path))
  $md += ('- system metrics JSON: `{0}`' -f (Split-Path -Leaf $metricsPath))
  $md += ('- system samples CSV: `{0}`' -f (Split-Path -Leaf $csvPath))

  # Write MD
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
  Write-Host ("Testing Pool Size: {0}" -f $poolSize)
  Write-Host "========================================="

  # Compose env for app
  $env:HIKARI_MAX_POOL_SIZE = $poolSize
  $env:HIKARI_MIN_IDLE      = [Math]::Floor($poolSize / 2)

  if ($ResetDb) {
    Write-Host "Recreating DB container..."
    docker compose stop postgres | Out-Null
    docker compose rm -f postgres | Out-Null
    docker compose up -d --force-recreate --renew-anon-volumes postgres
    Write-Host "Waiting for postgres health..."
    if (-not (Wait-For-Container-Health -serviceName "postgres" -timeoutSec 180)) {
      Write-Host "ERROR: postgres not healthy"; docker compose logs postgres --tail 200; exit 1
    }
  }

  Write-Host "Recreating app container..."
  docker compose stop app | Out-Null
  docker compose rm -f app | Out-Null
  docker compose up -d --force-recreate --renew-anon-volumes app

  Write-Host "Waiting for app (compose health)..."
  if (-not (Wait-For-Container-Health -serviceName "app" -timeoutSec 180)) {
    Write-Host "=== App logs ==="; docker compose logs app --tail 200
    Write-Host "ERROR: app not healthy by compose"; exit 1
  }

  Write-Host "Verifying actuator health (in-docker)..."
  if (-not (Wait-For-Health-InDocker -url $HealthUrl -timeoutSec $HealthTimeoutSec)) {
    Write-Host "=== App logs ==="; docker compose logs app --tail 200
    Write-Host "ERROR: Actuator health not UP"; exit 1
  }

  # (Optional) Print Hikari metrics if exposed
  try {
    $net = Get-Compose-Network
    $payload = docker run --rm --network $net curlimages/curl:8.10.1 `
      sh -lc "curl -s http://app:8080/actuator/metrics/hikaricp.connections.max"
    if ($payload) { Write-Host ("Hikari max metric: {0}" -f $payload) }
  } catch {}

  # Start system metrics sampler (app + postgres), 2s interval
  $samplesCsv = Join-Path $outputsPath ("pool-{0}.samples.csv" -f $poolSize)
  $metricsJson = Join-Path $outputsPath ("pool-{0}.metrics.json" -f $poolSize)
  $samplerProc = Start-Stats-Sampler -services @("app","postgres") -intervalSec 2 -csvPath $samplesCsv
  if ($samplerProc) { Write-Host ("Metrics sampler started (2s interval) -> {0}" -f $samplesCsv) }

  # Run k6 with per-pool summary export
  $summaryFile = "/outputs/pool-$poolSize.json"
  Write-Host "Running k6 ..."
  docker compose run --rm `
    -e BASE_URL=http://app:8080 `
    -e POOL_SIZE=$poolSize `
    -e TEST_DURATION=$DURATION `
    -e WARMUP_DURATION=$WarmupDuration `
    -e RATE_PRODUCTS=$RATE_PRODUCTS `
    -e RATE_ORDER_DETAIL=$RATE_ORDER_DETAIL `
    -e RATE_ORDER_CREATE=$RATE_ORDER_CREATE `
    -e ORDER_ID_MIN=1 -e ORDER_ID_MAX=10000 `
    -e PRODUCT_ID_MIN=1 -e PRODUCT_ID_MAX=20000 `
    -e MEMBER_ID_MIN=1 -e MEMBER_ID_MAX=100 `
    -e DISABLE_THRESHOLDS=true -e VERBOSE_ERRORS=false `
    -v "$($outputsPath):/outputs" `
    k6 run --summary-export $summaryFile /scripts/pool-performance-test.js

  $k6Exit = $LASTEXITCODE

  # Stop sampler and summarize
  Stop-Stats-Sampler $samplerProc
  if (Test-Path $samplesCsv) {
    Summarize-Metrics -csvPath $samplesCsv -jsonPath $metricsJson
    if (Test-Path $metricsJson) {
      Write-Host ("Metrics summary -> {0}" -f $metricsJson)
    }
  }

  if ($k6Exit -ne 0) {
    Write-Host ("ERROR: k6 run failed for pool {0}" -f $poolSize); exit 1
  }

  # Generate Markdown report
  Generate-MarkdownReport -poolSize $poolSize -outputsDir $outputsPath -loadName $LOAD_NAME

  Write-Host ("Cooling down ({0} s)..." -f $CoolDownSec)
  Start-Sleep -Seconds $CoolDownSec
}

Write-Host ""
Write-Host "======================================"
Write-Host "All tests completed!"
Write-Host "======================================"

Write-Host "Checking results..."
foreach ($poolSize in $poolSizes) {
  $resultFile  = ".\perf\k6\outputs\pool-$poolSize.json"
  $metricsFile = ".\perf\k6\outputs\pool-$poolSize.metrics.json"
  $samplesFile = ".\perf\k6\outputs\pool-$poolSize.samples.csv"
  $mdFile      = ".\perf\k6\outputs\pool-$poolSize.md"

  $ok1 = if (Test-Path $resultFile)  { "OK" } else { "MISS" }
  $ok2 = if (Test-Path $metricsFile) { "OK" } else { "MISS" }
  $ok3 = if (Test-Path $samplesFile) { "OK" } else { "MISS" }
  $ok4 = if (Test-Path $mdFile)      { "OK" } else { "MISS" }

  Write-Host ("[ {0} ] pool-{1}.json"         -f $ok1, $poolSize)
  Write-Host ("[ {0} ] pool-{1}.metrics.json" -f $ok2, $poolSize)
  Write-Host ("[ {0} ] pool-{1}.samples.csv"  -f $ok3, $poolSize)
  Write-Host ("[ {0} ] pool-{1}.md"           -f $ok4, $poolSize)
}
