# Benchmark Report - Pool Size 20

- **Load Level**: Light
- **Generated at**: 2025-09-08 16:59:04 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 45.31 |
| http_req_duration p99 (ms) | 206.31 |
| avg / med / max (ms) | 28.28 / 11.83 / 23886.35 |
| http_reqs count | 12298 |
| http_reqs rate (req/s) | 79.88 |
| http_req_failed (%) | - |
| checks (passes / fails) | 11631 / 371 |

## System Metrics (Docker containers)

### spring-app

Samples: **32** over **152s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 95.86 / 203.68 / 418.61 |
| Mem avg / max (%) | 6.13 / 6.54 |
| Mem peak / limit (MiB) | 510.10 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.12 |
| Block I/O throughput (read / write, B/s) | 0 / 854 |

### my-postgres

Samples: **32** over **152s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 54.35 / 90.07 / 109.36 |
| Mem avg / max (%) | 1.31 / 1.41 |
| Mem peak / limit (MiB) | 109.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-20.json`
- system metrics JSON: `pool-20.metrics.json`
- system samples CSV: `pool-20.samples.csv`
