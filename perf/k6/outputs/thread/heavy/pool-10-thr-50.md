# **Benchmark Report - Pool Size 10**

- **Load Level**: Heavy
- **Generated at**: 2025-09-10 12:51:36 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 3718.13 |
| http_req_duration p99 (ms) | 5664.79 |
| avg / med / max (ms) | 1742.88 / 1499.50 / 8212.03 |
| http_reqs count | 142404 |
| http_reqs rate (req/s) | 673.75 |
| http_req_failed (%) | 0.10 |
| checks (passes / fails) | 141960 / 147 |

## System Metrics (Docker containers)

### spring-app

Samples: **44** over **210s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 338.06 / 534.40 / 602.13 |
| Mem avg / max (%) | 9.66 / 10.48 |
| Mem peak / limit (MiB) | 816.50 / 7794.69 |
| Block I/O total (read / write, MiB) | 1.00 / 0.18 |
| Block I/O throughput (read / write, B/s) | 4993 / 921 |

### my-postgres

Samples: **44** over **210s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 79.91 / 109.70 / 114.58 |
| Mem avg / max (%) | 0.85 / 0.89 |
| Mem peak / limit (MiB) | 69.16 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10-thr-50.json`
- system metrics JSON: `pool-10-thr-50.metrics.json`
- system samples CSV: `pool-10-thr-50.samples.csv`
