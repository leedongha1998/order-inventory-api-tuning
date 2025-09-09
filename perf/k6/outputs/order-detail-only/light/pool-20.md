# Benchmark Report - Pool Size 20 (Order Detail Only)

- **Load Level**: Light
- **Generated at**: 2025-09-09 20:08:04 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 12.51 |
| http_req_duration p99 (ms) | 34.61 |
| avg / med / max (ms) | 8.50 / 5.20 / 6046.91 |
| http_reqs count | 12299 |
| http_reqs rate (req/s) | 73.75 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 5.16 | 10.14 | 25.22 | - |

## System Metrics (Docker containers)

### spring-app

Samples: **35** over **168s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 72.71 / 154.85 / 180.28 |
| Mem avg / max (%) | 5.91 / 6.41 |
| Mem peak / limit (MiB) | 499.80 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.14 |
| Block I/O throughput (read / write, B/s) | 0 / 876 |

### my-postgres

Samples: **35** over **168s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 10.88 / 18.37 / 19.8 |
| Mem avg / max (%) | 2.29 / 2.33 |
| Mem peak / limit (MiB) | 181.40 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-20.json`
- system metrics JSON: `pool-20.metrics.json`
- system samples CSV: `pool-20.samples.csv`
