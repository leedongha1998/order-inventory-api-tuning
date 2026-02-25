# **Benchmark Report - Pool Size 10**

- **Load Level**: Light
- **Generated at**: 2025-09-10 01:46:49 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 9.59 |
| http_req_duration p99 (ms) | 16.55 |
| avg / med / max (ms) | 5.54 / 4.76 / 469.05 |
| http_reqs count | 18299 |
| http_reqs rate (req/s) | 86.89 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 18001 / 0 |

## System Metrics (Docker containers)

### spring-app

Samples: **46** over **208s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 57.52 / 137.90 / 170.17 |
| Mem avg / max (%) | 6.02 / 6.46 |
| Mem peak / limit (MiB) | 503.30 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.18 |
| Block I/O throughput (read / write, B/s) | 0 / 885 |

### my-postgres

Samples: **46** over **208s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 10.01 / 16.08 / 21.94 |
| Mem avg / max (%) | 2.18 / 2.20 |
| Mem peak / limit (MiB) | 171.20 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10-thr-200.json`
- system metrics JSON: `pool-10-thr-200.metrics.json`
- system samples CSV: `pool-10-thr-200.samples.csv`
