# Benchmark Report - Pool Size 20

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 20:38:20 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 6870.39 |
| http_req_duration p99 (ms) | 8547.90 |
| avg / med / max (ms) | 3670.76 / 3275.79 / 11915.46 |
| http_reqs count | 80146 |
| http_reqs rate (req/s) | 339.52 |
| http_req_failed (%) | - |
| checks (passes / fails) | 79795 / 54 |

## System Metrics (Docker containers)

### spring-app

Samples: **47** over **231s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 240.4 / 424.31 / 495.24 |
| Mem avg / max (%) | 8.49 / 9.82 |
| Mem peak / limit (MiB) | 765.30 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.14 |
| Block I/O throughput (read / write, B/s) | 0 / 619 |

### my-postgres

Samples: **47** over **231s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 379.57 / 519.45 / 551.87 |
| Mem avg / max (%) | 2.61 / 2.72 |
| Mem peak / limit (MiB) | 211.80 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-20.json`
- system metrics JSON: `pool-20.metrics.json`
- system samples CSV: `pool-20.samples.csv`
