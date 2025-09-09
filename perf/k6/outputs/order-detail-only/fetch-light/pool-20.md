# Benchmark Report - Pool Size 20 (Order Detail Only)

- **Load Level**: Light
- **Generated at**: 2025-09-09 21:40:17 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 19.58 |
| http_req_duration p99 (ms) | 43.65 |
| avg / med / max (ms) | 10.19 / 5.85 / 6158.87 |
| http_reqs count | 12299 |
| http_reqs rate (req/s) | 73.77 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 5.80 | 17.19 | 38.74 | - |

## System Metrics (Docker containers)

### spring-app

Samples: **34** over **164s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 91.55 / 182.59 / 608.62 |
| Mem avg / max (%) | 5.51 / 5.7 |
| Mem peak / limit (MiB) | 444.20 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.13 |
| Block I/O throughput (read / write, B/s) | 0 / 820 |

### my-postgres

Samples: **34** over **164s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 12.04 / 20.36 / 37.51 |
| Mem avg / max (%) | 2.19 / 2.23 |
| Mem peak / limit (MiB) | 174.20 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-20.json`
- system metrics JSON: `pool-20.metrics.json`
- system samples CSV: `pool-20.samples.csv`
