# Benchmark Report - Pool Size 10 (Order Detail Only)

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 21:49:11 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 2908.63 |
| http_req_duration p99 (ms) | 6310.40 |
| avg / med / max (ms) | 519.47 / 47.60 / 10888.06 |
| http_reqs count | 162440 |
| http_reqs rate (req/s) | 692.59 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 48.04 | 2912.43 | 6315.86 | 27 |

## System Metrics (Docker containers)

### spring-app

Samples: **48** over **233s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 344.81 / 563.2 / 624.29 |
| Mem avg / max (%) | 8.76 / 9.51 |
| Mem peak / limit (MiB) | 741.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.18 |
| Block I/O throughput (read / write, B/s) | 0 / 812 |

### my-postgres

Samples: **48** over **233s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 88.13 / 121.98 / 136.05 |
| Mem avg / max (%) | 2.15 / 2.26 |
| Mem peak / limit (MiB) | 175.80 / 7794.69 |
| Block I/O total (read / write, MiB) | 3.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 13501 / 0 |

## Artifacts

- k6 JSON: `pool-10.json`
- system metrics JSON: `pool-10.metrics.json`
- system samples CSV: `pool-10.samples.csv`
