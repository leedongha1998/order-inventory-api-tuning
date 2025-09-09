# Benchmark Report - Pool Size 10

- **Load Level**: Light
- **Generated at**: 2025-09-09 16:36:47 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 18.39 |
| http_req_duration p99 (ms) | 27.70 |
| avg / med / max (ms) | 12.99 / 10.23 / 5866.35 |
| http_reqs count | 12299 |
| http_reqs rate (req/s) | 73.76 |
| http_req_failed (%) | - |
| checks (passes / fails) | 12002 / 0 |

## System Metrics (Docker containers)

### spring-app

Samples: **34** over **161s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 79.79 / 190.8 / 231.57 |
| Mem avg / max (%) | 6.14 / 6.43 |
| Mem peak / limit (MiB) | 501.50 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.35 / 0.14 |
| Block I/O throughput (read / write, B/s) | 2264 / 909 |

### my-postgres

Samples: **34** over **161s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 46.39 / 64.15 / 67.49 |
| Mem avg / max (%) | 2.24 / 2.27 |
| Mem peak / limit (MiB) | 176.80 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10.json`
- system metrics JSON: `pool-10.metrics.json`
- system samples CSV: `pool-10.samples.csv`
