# Benchmark Report - Pool Size 20 (Order Detail Only)

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 21:53:57 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 2456.31 |
| http_req_duration p99 (ms) | 6339.50 |
| avg / med / max (ms) | 546.12 / 25.05 / 11052.15 |
| http_reqs count | 166397 |
| http_reqs rate (req/s) | 712.80 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 25.21 | 2457.52 | 6339.83 | 7 |

## System Metrics (Docker containers)

### spring-app

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 340.26 / 597.18 / 699.86 |
| Mem avg / max (%) | 8.81 / 9.72 |
| Mem peak / limit (MiB) | 757.90 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.14 |
| Block I/O throughput (read / write, B/s) | 0 / 656 |

### my-postgres

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 88.19 / 121.39 / 126.02 |
| Mem avg / max (%) | 2.46 / 2.53 |
| Mem peak / limit (MiB) | 197.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-20.json`
- system metrics JSON: `pool-20.metrics.json`
- system samples CSV: `pool-20.samples.csv`
