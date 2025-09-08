# Benchmark Report - Pool Size 30

- **Load Level**: Light
- **Generated at**: 2025-09-08 17:02:30 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 25.32 |
| http_req_duration p99 (ms) | 50.89 |
| avg / med / max (ms) | 18.61 / 11.31 / 23904.29 |
| http_reqs count | 12301 |
| http_reqs rate (req/s) | 79.78 |
| http_req_failed (%) | - |
| checks (passes / fails) | 11656 / 347 |

## System Metrics (Docker containers)

### spring-app

Samples: **31** over **150s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 72.16 / 123.02 / 187.86 |
| Mem avg / max (%) | 6.72 / 6.94 |
| Mem peak / limit (MiB) | 541.20 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.13 |
| Block I/O throughput (read / write, B/s) | 0 / 894 |

### my-postgres

Samples: **31** over **150s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 48.65 / 68.82 / 78.57 |
| Mem avg / max (%) | 1.24 / 1.33 |
| Mem peak / limit (MiB) | 103.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-30.json`
- system metrics JSON: `pool-30.metrics.json`
- system samples CSV: `pool-30.samples.csv`
