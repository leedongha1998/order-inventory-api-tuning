# Benchmark Report - Pool Size 30

- **Load Level**: Light
- **Generated at**: 2025-09-09 16:44:07 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 19.10 |
| http_req_duration p99 (ms) | 47.09 |
| avg / med / max (ms) | 13.77 / 10.39 / 5893.68 |
| http_reqs count | 12299 |
| http_reqs rate (req/s) | 73.75 |
| http_req_failed (%) | - |
| checks (passes / fails) | 12001 / 0 |

## System Metrics (Docker containers)

### spring-app

Samples: **34** over **162s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 71.83 / 161.05 / 229.72 |
| Mem avg / max (%) | 6.2 / 6.63 |
| Mem peak / limit (MiB) | 516.50 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.14 |
| Block I/O throughput (read / write, B/s) | 0 / 903 |

### my-postgres

Samples: **34** over **162s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 49.15 / 69.15 / 107.38 |
| Mem avg / max (%) | 2.5 / 2.58 |
| Mem peak / limit (MiB) | 200.90 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-30.json`
- system metrics JSON: `pool-30.metrics.json`
- system samples CSV: `pool-30.samples.csv`
