# Benchmark Report - Pool Size 30 (Order Detail Only)

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 21:58:45 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 3027.52 |
| http_req_duration p99 (ms) | 6113.66 |
| avg / med / max (ms) | 710.84 / 136.13 / 11512.07 |
| http_reqs count | 162671 |
| http_reqs rate (req/s) | 692.74 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 137.25 | 3028.67 | 6114.26 | 8 |

## System Metrics (Docker containers)

### spring-app

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 354.36 / 553.11 / 724.96 |
| Mem avg / max (%) | 7.97 / 9.3 |
| Mem peak / limit (MiB) | 725.10 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.17 |
| Block I/O throughput (read / write, B/s) | 0 / 768 |

### my-postgres

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 88.62 / 121.64 / 130 |
| Mem avg / max (%) | 2.68 / 2.77 |
| Mem peak / limit (MiB) | 215.90 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-30.json`
- system metrics JSON: `pool-30.metrics.json`
- system samples CSV: `pool-30.samples.csv`
