# Benchmark Report - Pool Size 10

- **Load Level**: Light
- **Generated at**: 2025-09-08 16:55:37 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 25.09 |
| http_req_duration p99 (ms) | 48.26 |
| avg / med / max (ms) | 28.29 / 11.19 / 23907.31 |
| http_reqs count | 12300 |
| http_reqs rate (req/s) | 79.85 |
| http_req_failed (%) | - |
| checks (passes / fails) | 11678 / 325 |

## System Metrics (Docker containers)

### spring-app

Samples: **34** over **153s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 72.94 / 144.01 / 218.44 |
| Mem avg / max (%) | 6.16 / 6.58 |
| Mem peak / limit (MiB) | 512.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.14 |
| Block I/O throughput (read / write, B/s) | 0 / 957 |

### my-postgres

Samples: **34** over **153s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 48.15 / 69.99 / 71.6 |
| Mem avg / max (%) | 1.04 / 1.13 |
| Mem peak / limit (MiB) | 88.12 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10.json`
- system metrics JSON: `pool-10.metrics.json`
- system samples CSV: `pool-10.samples.csv`
