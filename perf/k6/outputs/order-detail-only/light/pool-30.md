# Benchmark Report - Pool Size 30 (Order Detail Only)

- **Load Level**: Light
- **Generated at**: 2025-09-09 20:11:49 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 11.23 |
| http_req_duration p99 (ms) | 19.04 |
| avg / med / max (ms) | 7.39 / 5.30 / 6062.95 |
| http_reqs count | 12299 |
| http_reqs rate (req/s) | 73.76 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 5.25 | 10.03 | 16.90 | - |

## System Metrics (Docker containers)

### spring-app

Samples: **35** over **167s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 69.53 / 151.78 / 187.15 |
| Mem avg / max (%) | 5.89 / 6.13 |
| Mem peak / limit (MiB) | 477.50 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.14 |
| Block I/O throughput (read / write, B/s) | 0 / 881 |

### my-postgres

Samples: **35** over **167s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 10.19 / 17.39 / 20.47 |
| Mem avg / max (%) | 2.37 / 2.39 |
| Mem peak / limit (MiB) | 186.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-30.json`
- system metrics JSON: `pool-30.metrics.json`
- system samples CSV: `pool-30.samples.csv`
