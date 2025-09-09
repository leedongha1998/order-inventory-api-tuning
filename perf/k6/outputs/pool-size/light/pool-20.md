# Benchmark Report - Pool Size 20

- **Load Level**: Light
- **Generated at**: 2025-09-09 16:40:27 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 18.91 |
| http_req_duration p99 (ms) | 29.90 |
| avg / med / max (ms) | 12.89 / 10.41 / 5871.20 |
| http_reqs count | 12300 |
| http_reqs rate (req/s) | 73.77 |
| http_req_failed (%) | - |
| checks (passes / fails) | 12002 / 0 |

## System Metrics (Docker containers)

### spring-app

Samples: **34** over **161s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 85.31 / 182.63 / 283.25 |
| Mem avg / max (%) | 6.45 / 6.67 |
| Mem peak / limit (MiB) | 519.80 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.14 |
| Block I/O throughput (read / write, B/s) | 0 / 910 |

### my-postgres

Samples: **34** over **161s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 47.51 / 66.55 / 71.83 |
| Mem avg / max (%) | 2.32 / 2.34 |
| Mem peak / limit (MiB) | 182.30 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-20.json`
- system metrics JSON: `pool-20.metrics.json`
- system samples CSV: `pool-20.samples.csv`
