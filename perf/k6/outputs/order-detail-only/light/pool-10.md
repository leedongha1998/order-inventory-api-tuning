# Benchmark Report - Pool Size 10 (Order Detail Only)

- **Load Level**: Light
- **Generated at**: 2025-09-09 20:04:18 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 11.81 |
| http_req_duration p99 (ms) | 24.32 |
| avg / med / max (ms) | 7.55 / 5.34 / 6050.94 |
| http_reqs count | 12299 |
| http_reqs rate (req/s) | 73.77 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 5.31 | 10.60 | 21.75 | - |

## System Metrics (Docker containers)

### spring-app

Samples: **34** over **162s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 76.77 / 182.45 / 241.29 |
| Mem avg / max (%) | 5.77 / 5.99 |
| Mem peak / limit (MiB) | 467.20 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.13 |
| Block I/O throughput (read / write, B/s) | 0 / 855 |

### my-postgres

Samples: **34** over **162s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 11.51 / 20.42 / 35.37 |
| Mem avg / max (%) | 2.2 / 2.22 |
| Mem peak / limit (MiB) | 173.10 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10.json`
- system metrics JSON: `pool-10.metrics.json`
- system samples CSV: `pool-10.samples.csv`
