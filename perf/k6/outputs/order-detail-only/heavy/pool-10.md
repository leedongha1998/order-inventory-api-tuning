# Benchmark Report - Pool Size 10 (Order Detail Only)

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 20:51:39 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 3956.07 |
| http_req_duration p99 (ms) | 6021.26 |
| avg / med / max (ms) | 1408.00 / 1386.07 / 10297.58 |
| http_reqs count | 149051 |
| http_reqs rate (req/s) | 634.79 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 1387.92 | 3961.68 | 6026.09 | 14 |

## System Metrics (Docker containers)

### spring-app

Samples: **47** over **234s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 368.78 / 550.22 / 630.16 |
| Mem avg / max (%) | 8.73 / 9.61 |
| Mem peak / limit (MiB) | 749.40 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.20 |
| Block I/O throughput (read / write, B/s) | 0 / 878 |

### my-postgres

Samples: **47** over **234s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 95.45 / 132.14 / 157.49 |
| Mem avg / max (%) | 2.15 / 2.18 |
| Mem peak / limit (MiB) | 169.90 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10.json`
- system metrics JSON: `pool-10.metrics.json`
- system samples CSV: `pool-10.samples.csv`
