# Benchmark Report - Pool Size 30 (Order Detail Only)

- **Load Level**: Light
- **Generated at**: 2025-09-09 21:44:02 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 11.12 |
| http_req_duration p99 (ms) | 20.41 |
| avg / med / max (ms) | 7.29 / 5.31 / 6140.76 |
| http_reqs count | 12298 |
| http_reqs rate (req/s) | 73.75 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 5.27 | 9.77 | 15.92 | - |

## System Metrics (Docker containers)

### spring-app

Samples: **34** over **162s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 74.6 / 164.56 / 364.65 |
| Mem avg / max (%) | 5.81 / 6.18 |
| Mem peak / limit (MiB) | 481.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.14 |
| Block I/O throughput (read / write, B/s) | 0 / 934 |

### my-postgres

Samples: **34** over **162s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 11.53 / 21.4 / 34.36 |
| Mem avg / max (%) | 2.25 / 2.29 |
| Mem peak / limit (MiB) | 178.10 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-30.json`
- system metrics JSON: `pool-30.metrics.json`
- system samples CSV: `pool-30.samples.csv`
