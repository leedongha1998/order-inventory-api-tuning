# run-thread.ps1 (Order Detail Only, PS 5.1)
# - k6: pool-<CP>-thr-<TP>.json|csv 생성
# - PS1: 단일 MD pool-<CP>-thr-<TP>.md 생성
# - 폴더 스캔으로 낙오 파일(pool-<CP>.*) 정리 + 필요시 자동 리네임

$ErrorActionPreference = 'Stop'

# === 선택값 ===
$poolSizes        = @(10,20,30)
$threadOptions    = @(50,100)
$DURATION         = "3m"
$WarmupDuration   = "30s"
$RATE_ORDER_DETAIL= 150
$LOAD_NAME        = "Custom"
$outputsPath      = ".\perf\k6\outputs"
$scriptPath = ".\perf\k6\scenarios\order-detail-thread.js"
$CoolDownSec      = 20

# === 부하 선택 ===
Write-Host ""
Write-Host "Select Order-Detail Load:"
Write-Host "1) 100 req/s (3m)"
Write-Host "2) 1000 req/s (3m)"
Write-Host "3) Custom"
$choiceLoad = Read-Host "Choice (1-3)"
switch ($choiceLoad) {
  '1' { $RATE_ORDER_DETAIL = 100;  $DURATION = '3m'; $LOAD_NAME = 'Light' }
  '2' { $RATE_ORDER_DETAIL = 1000; $DURATION = '3m'; $LOAD_NAME = 'Heavy' }
  '3' {
    $RATE_ORDER_DETAIL = [int](Read-Host "Enter req/s (e.g. 250)")
    $DURATION = Read-Host "Enter duration (e.g. 3m, 5m, 30s)"; if (-not $DURATION) { $DURATION = '3m' }
    $LOAD_NAME = "$RATE_ORDER_DETAIL rps"
  }
  default { Write-Host "Invalid choice"; exit 1 }
}

Write-Host "`nSelect Connection Pool size (CP): 10/20/30 or Custom (comma)"
$raw = Read-Host "CP list (default: 10,20,30)"
if ($raw) { $poolSizes = @($raw -split ',' | ForEach-Object { [int]($_.Trim()) } | Where-Object { $_ -gt 0 }) }

Write-Host "`nSelect Tomcat Threads (TP): 50/100 or Custom (comma)"
$raw = Read-Host "TP list (default: 50,100)"
if ($raw) { $threadOptions = @($raw -split ',' | ForEach-Object { [int]($_.Trim()) } | Where-Object { $_ -gt 0 }) }

# === 경로 ===
New-Item -ItemType Directory -Force -Path $outputsPath | Out-Null
$absOut    = (Resolve-Path $outputsPath).Path
$absScript = (Resolve-Path $scriptPath).Path

# === 유틸 ===
function Wait-For-Container-Health($serviceName, $timeoutSec=180) {
  $start = Get-Date
  while (((Get-Date)-$start).TotalSeconds -lt $timeoutSec) {
    $cid = (docker compose ps -q $serviceName).Trim()
    if ($cid) {
      $st = (docker inspect $cid | ConvertFrom-Json)[0].State
      if ($st.Health -and $st.Health.Status -eq "healthy") { return $true }
      if ($st.Status -eq "exited") { return $false }
    }
    Start-Sleep 2
  }
  return $false
}
function Get-ContainerName-ForService([string]$service) {
  $lines = docker compose ps --format "{{.Name}} {{.Service}}"
  foreach ($l in $lines) { $p = $l -split "\s+"; if ($p.Length -ge 2 -and $p[1] -eq $service) { return $p[0] } }
  return $null
}
function Start-Stats-Sampler([string[]]$services, [int]$intervalSec, [string]$csvPath) {
  $containers = @(); foreach ($s in $services) { $n = Get-ContainerName-ForService $s; if ($n) { $containers += $n } }
  if ($containers.Count -eq 0) { return $null }
  try { $dockerExe = (Get-Command docker -ErrorAction Stop).Source } catch { return $null }

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
function Convert-ToBytes([string]$s){ if(-not $s){return 0}; $s=($s -replace ',', '').Trim(); if($s -match '^(?<num>[0-9]*\.?[0-9]+)\s*(?<unit>[A-Za-z]+)?$'){ $num=[double]$matches['num']; $unit=$matches['unit']; switch -Regex ($unit){ '^B$'{return $num}; '^(?:[Kk]B|KiB)$'{return $num*1KB}; '^(?:[Mm]B|MiB)$'{return $num*1MB}; '^(?:[Gg]B|GiB)$'{return $num*1GB}; default{return $num} } } 0 }
while($true){ try{ $fmt='{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}'; $raw=& "$docker" stats --no-stream --format $fmt 2>$null; $ts=(Get-Date).ToString('o'); foreach($line in $raw){ $c=$line -split ','; if($c.Count -lt 7){continue}; $name=$c[0].Trim(); if($containers -notcontains $name){continue}; $cpuPct=($c[1] -replace '%','').Trim(); $mu=$c[2] -split '/'; $memUsedStr=$mu[0].Trim(); $memLimitStr= if($mu.Count -ge 2){$mu[1].Trim()}else{"0B"}; $memUsedB=Convert-ToBytes $memUsedStr; $memLimitB=Convert-ToBytes $memLimitStr; $memPct=($c[3] -replace '%','').Trim(); $net=$c[4] -split '/'; $netRxStr=$net[0].Trim(); $netTxStr= if($net.Count -ge 2){$net[1].Trim()}else{"0B"}; $netRxB=Convert-ToBytes $netRxStr; $netTxB=Convert-ToBytes $netTxStr; $bio=$c[5] -split '/'; $blkReadStr=$bio[0].Trim(); $blkWriteStr= if($bio.Count -ge 2){$bio[1].Trim()}else{"0B"}; $blkReadB=Convert-ToBytes $blkReadStr; $blkWriteB=Convert-ToBytes $blkWriteStr; $pids=[int]($c[6].Trim()); "$ts,$name,$cpuPct,$([long]$memUsedB),$([long]$memLimitB),$memPct,$([long]$netRxB),$([long]$netTxB),$([long]$blkReadB),$([long]$blkWriteB),$pids" | Add-Content -Path $csv -Encoding utf8 } }catch{}; Start-Sleep -Seconds $interval }
'@
  $psCode = $psTemplate.Replace('__CONTAINERS__',$containersLiteral).Replace('__INTERVAL__',[string]$intervalSec).Replace('__CSV__',$csvEsc).Replace('__DOCKER__',$dockerEsc)
  $tmp = Join-Path $env:TEMP ("stats-sampler-{0}-{1}.ps1" -f $PID,(Get-Random))
  Set-Content -Path $tmp -Value $psCode -Encoding UTF8
  $psExe = Join-Path $PSHOME 'powershell.exe'
  Start-Process -FilePath $psExe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', $tmp) -WindowStyle Hidden -PassThru
}
function Stop-Stats-Sampler($proc){ if($proc){ try{ if(-not $proc.HasExited){ Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue } }catch{} } }

function Summarize-Metrics([string]$csvPath, [string]$jsonPath) {
  if (-not (Test-Path $csvPath)) { '[{"samples":0,"note":"metrics CSV not found"}]' | Out-File -FilePath $jsonPath -Encoding utf8; return }
  $rows = Import-Csv -Path $csvPath
  if (-not $rows -or $rows.Count -eq 0) { '[{"samples":0,"note":"no samples"}]' | Out-File -FilePath $jsonPath -Encoding utf8; return }
  $by = $rows | Group-Object container
  $out=@()
  foreach($g in $by){
    $arr=$g.Group
    $cpu = $arr | % {[double]$_.cpu_percent}
    $memP= $arr | % {[double]$_.mem_percent}
    $mu  = $arr | % {[double]$_.mem_used_b}
    $ml  = $arr | % {[double]$_.mem_limit_b}
    $br  = $arr | % {[double]$_.blk_read_b}
    $bw  = $arr | % {[double]$_.blk_write_b}
    $t0 = Get-Date ($arr[0].timestamp); $tN = Get-Date ($arr[$arr.Count-1].timestamp)
    $secs = [math]::Max(1,[int](($tN-$t0).TotalSeconds))
    function P([double[]]$xs,[double]$p){ if(-not $xs -or $xs.Count -eq 0){return 0}; $s=$xs|Sort-Object; $i=[int][math]::Round(($s.Count-1)*$p); $s[$i] }
    $read  = [math]::Max(0, ($br[$br.Count-1]-$br[0]))
    $write = [math]::Max(0, ($bw[$bw.Count-1]-$bw[0]))
    $out += [pscustomobject]@{
      container=$g.Name; samples=$arr.Count; window_seconds=$secs
      cpu_percent_avg=[math]::Round(($cpu|Measure-Object -Average).Average,2)
      cpu_percent_p95=[math]::Round((P $cpu 0.95),2)
      cpu_percent_max=[math]::Round(($cpu|Measure-Object -Maximum).Maximum,2)
      mem_percent_avg=[math]::Round(($memP|Measure-Object -Average).Average,2)
      mem_percent_max=[math]::Round(($memP|Measure-Object -Maximum).Maximum,2)
      mem_used_peak_bytes=[long]($mu|Measure-Object -Maximum).Maximum
      mem_limit_bytes=[long]($ml|Select-Object -First 1)
      block_io_total_read_bytes=[long]$read
      block_io_total_write_bytes=[long]$write
      block_io_read_bps=[int]([math]::Round($read/$secs))
      block_io_write_bps=[int]([math]::Round($write/$secs))
    }
  }
  if($out.Count -eq 0){ '[{"samples":0}]' | Out-File -FilePath $jsonPath -Encoding utf8 }
  else { $out | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8 }
}

function Fmt([object]$v,[string]$f='0.00'){ try{$d=[double]$v}catch{return '-'}; $d.ToString($f,[Globalization.CultureInfo]::InvariantCulture) }
function B2MiB([object]$bytes,[string]$f='0.00'){ try{$d=[double]$bytes}catch{return '-'}; ($d/1MB).ToString($f,[Globalization.CultureInfo]::InvariantCulture) }

# === 보조: 산출물 정규화(리네임/정리) ===
function Normalize-Artifacts([int]$cp,[int]$tp,[string]$dir) {
  $expectedJson = Join-Path $dir ("pool-{0}-thr-{1}.json" -f $cp,$tp)
  $expectedCsv  = Join-Path $dir ("pool-{0}-thr-{1}.csv"  -f $cp,$tp)

  $legacyJson = Join-Path $dir ("pool-{0}.json" -f $cp)
  $legacyCsv  = Join-Path $dir ("pool-{0}.csv"  -f $cp)
  $legacyMd   = Join-Path $dir ("pool-{0}.md"   -f $cp)

  if (-not (Test-Path $expectedJson) -and (Test-Path $legacyJson)) {
    Move-Item -Force $legacyJson $expectedJson
  }
  if (-not (Test-Path $expectedCsv) -and (Test-Path $legacyCsv)) {
    Move-Item -Force $legacyCsv $expectedCsv
  }

  # 낙오 파일 제거
  if (Test-Path $legacyMd) { Remove-Item -Force $legacyMd }
}

# === 실행 ===
foreach($cp in $poolSizes){
  foreach($tp in $threadOptions){
    Write-Host "`n=== Testing CP=$cp / TP=$tp ==="

    # 앱 재기동 & 헬스
    $env:HIKARI_MAX_POOL_SIZE = $cp
    $env:HIKARI_MIN_IDLE      = [Math]::Floor($cp/2)
    docker compose stop app | Out-Null
    docker compose rm -f app | Out-Null
    docker compose up -d --force-recreate --renew-anon-volumes app
    if (-not (Wait-For-Container-Health app 180)) { Write-Host "ERROR: app not healthy"; docker compose logs app --tail=200; exit 1 }

    # 샘플러
    $samplesCsv = Join-Path $outputsPath ("pool-{0}-thr-{1}.samples.csv" -f $cp,$tp)
    $metricsJson= Join-Path $outputsPath ("pool-{0}-thr-{1}.metrics.json" -f $cp,$tp)
    $sampler = Start-Stats-Sampler -services @("app","postgres") -intervalSec 2 -csvPath $samplesCsv
    if ($sampler) { Write-Host ("Metrics sampler -> {0}" -f $samplesCsv) }

    # k6 (MD는 생성 안 함)
    docker compose run --rm `
      -e BASE_URL=http://app:8080 `
      -e POOL_SIZE=$cp `
      -e THREADS=$tp `
      -e TEST_DURATION=$DURATION `
      -e WARMUP_DURATION=$WarmupDuration `
      -e RATE_ORDER_DETAIL=$RATE_ORDER_DETAIL `
      -e ORDER_ID_MIN=1 -e ORDER_ID_MAX=10000 `
      -e DISABLE_THRESHOLDS=true -e VERBOSE_ERRORS=false `
      -v "$($absOut):/outputs" `
      -v "$($absScript):/scripts/order-detail-only.js:ro" `
      k6 run /scripts/order-detail-only.js
    $k6Exit = $LASTEXITCODE

    Stop-Stats-Sampler $sampler
    if (Test-Path $samplesCsv) { Summarize-Metrics -csvPath $samplesCsv -jsonPath $metricsJson }

    # 산출물 정규화(리네임/정리)
    Normalize-Artifacts -cp $cp -tp $tp -dir $outputsPath

    if ($k6Exit -ne 0) { Write-Host ("ERROR: k6 run failed for CP={0}, TP={1}" -f $cp,$tp); exit 1 }

    # === 단일 MD 생성 ===
    $sumPath = Join-Path $outputsPath ("pool-{0}-thr-{1}.json" -f $cp,$tp)
    if (-not (Test-Path $sumPath)) {
      Write-Host "ERROR: Expected k6 summary not found: $sumPath"
      Write-Host "Existing files:"; Get-ChildItem $outputsPath | Select-Object Name | Format-Table -AutoSize
      exit 1
    }
    $k6 = Get-Content -Raw -Path $sumPath | ConvertFrom-Json

    $mdPath  = Join-Path $outputsPath ("pool-{0}-thr-{1}.md"   -f $cp,$tp)
    $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss K")

    $p95 = $k6.overall.responseTime.p95
    $p99 = $k6.overall.responseTime.p99
    $avg = $k6.overall.responseTime.avg
    $med = $k6.overall.responseTime.med
    $max = $k6.overall.responseTime.max
    $cnt = $k6.overall.totalRequests
    $rps = $k6.overall.requestsPerSecond
    $failPct = $k6.overall.failureRate
    $checksPass = $k6.checks.passes
    $checksFail = $k6.checks.fails

    $md = @()
    $md += ("# **Benchmark Report - Pool Size {0}**" -f $cp)
    $md += ""
    $md += ("- **Load Level**: {0}" -f $LOAD_NAME)
    $md += ("- **Generated at**: {0}" -f $now)
    $md += ""
    $md += "## k6 Results"
    $md += ""
    $md += "| Metric | Value |"
    $md += "|---|---:|"
    $md += ("| http_req_duration p95 (ms) | {0} |" -f (Fmt $p95))
    $md += ("| http_req_duration p99 (ms) | {0} |" -f (Fmt $p99))
    $md += ("| avg / med / max (ms) | {0} / {1} / {2} |" -f (Fmt $avg),(Fmt $med),(Fmt $max))
    $md += ("| http_reqs count | {0} |" -f (Fmt $cnt '0'))
    $md += ("| http_reqs rate (req/s) | {0} |" -f (Fmt $rps))
    $md += ("| http_req_failed (%) | {0} |" -f ($(if($failPct -ne $null){ (Fmt $failPct '0.00') } else { '-' })))
    if ($checksPass -ne $null -or $checksFail -ne $null) {
      $md += ("| checks (passes / fails) | {0} / {1} |" -f (Fmt $checksPass '0'), (Fmt $checksFail '0'))
    }
    $md += ""
    $md += "## System Metrics (Docker containers)"
    if (Test-Path $metricsJson) {
      $arr = Get-Content -Raw -Path $metricsJson | ConvertFrom-Json
      foreach ($c in $arr) {
        $md += ""
        $md += ("### {0}" -f $c.container)
        $md += ""
        $md += ("Samples: **{0}** over **{1}s**" -f $c.samples, $c.window_seconds)
        $md += ""
        $md += "| Metric | Value |"
        $md += "|---|---:|"
        $md += ("| CPU avg / p95 / max (%) | {0} / {1} / {2} |" -f (Fmt $c.cpu_percent_avg), (Fmt $c.cpu_percent_p95), (Fmt $c.cpu_percent_max))
        $md += ("| Mem avg / max (%) | {0} / {1} |" -f (Fmt $c.mem_percent_avg), (Fmt $c.mem_percent_max))
        $md += ("| Mem peak / limit (MiB) | {0} / {1} |" -f (B2MiB $c.mem_used_peak_bytes), (B2MiB $c.mem_limit_bytes))
        $md += ("| Block I/O total (read / write, MiB) | {0} / {1} |" -f (B2MiB $c.block_io_total_read_bytes), (B2MiB $c.block_io_total_write_bytes))
        $md += ("| Block I/O throughput (read / write, B/s) | {0} / {1} |" -f (Fmt $c.block_io_read_bps '0'), (Fmt $c.block_io_write_bps '0'))
      }
    } else {
      $md += "_metrics summary not found_"
    }
    $md += ""
    $md += "## Artifacts"
    $md += ""
    $md += ("- k6 JSON: ``pool-{0}-thr-{1}.json``" -f $cp,$tp)
    $md += ("- system metrics JSON: ``pool-{0}-thr-{1}.metrics.json``" -f $cp,$tp)
    $md += ("- system samples CSV: ``pool-{0}-thr-{1}.samples.csv``" -f $cp,$tp)

    Set-Content -Path $mdPath -Value ([string]::Join("`r`n",$md)) -Encoding UTF8
    Write-Host ("MD -> {0}" -f $mdPath)

    # 마지막으로 stray 전부 제거
    Get-ChildItem $outputsPath -Filter ("pool-{0}.*" -f $cp) | Where-Object {
      $_.Name -notlike ("pool-{0}-thr-*.*" -f $cp)
    } | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host ("Cooling down ({0} s)..." -f $CoolDownSec)
    Start-Sleep -Seconds $CoolDownSec
  }
}

Write-Host "`n=== Generated ==="
Get-ChildItem $outputsPath -Filter "pool-*-thr-*.md" | ForEach-Object { Write-Host ("- {0}" -f $_.Name) }
