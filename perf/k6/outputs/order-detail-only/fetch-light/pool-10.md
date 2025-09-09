# Benchmark Report - Pool Size 10 (Order Detail Only)

- **Load Level**: Light
- **Generated at**: 2025-09-09 21:36:38 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 13.94 |
| http_req_duration p99 (ms) | 38.12 |
| avg / med / max (ms) | 8.71 / 5.35 / 6165.48 |
| http_reqs count | 12293 |
| http_reqs rate (req/s) | 73.72 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 5.30 | 12.21 | 28.55 | - |

## System Metrics (Docker containers)

### spring-app

Samples: **34** over **163s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 77.51 / 157.33 / 307.1 |
| Mem avg / max (%) | 6.36 / 6.71 |
| Mem peak / limit (MiB) | 522.90 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.13 |
| Block I/O throughput (read / write, B/s) | 0 / 824 |

### my-postgres

Samples: **34** over **163s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 11.69 / 24.21 / 29.57 |
| Mem avg / max (%) | 2.08 / 2.1 |
| Mem peak / limit (MiB) | 163.40 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10.json`
- system metrics JSON: `pool-10.metrics.json`
- system samples CSV: `pool-10.samples.csv`
