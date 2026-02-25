# **Benchmark Report - Pool Size 10**

- **Load Level**: Light
- **Generated at**: 2025-09-10 01:42:23 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 8.66 |
| http_req_duration p99 (ms) | 14.94 |
| avg / med / max (ms) | 5.34 / 4.69 / 468.36 |
| http_reqs count | 18299 |
| http_reqs rate (req/s) | 86.88 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 18001 / 0 |

## System Metrics (Docker containers)

### spring-app

Samples: **46** over **208s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 51.61 / 129.36 / 162.39 |
| Mem avg / max (%) | 6.28 / 6.43 |
| Mem peak / limit (MiB) | 500.90 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.18 |
| Block I/O throughput (read / write, B/s) | 0 / 885 |

### my-postgres

Samples: **46** over **208s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 10.55 / 16.55 / 18.03 |
| Mem avg / max (%) | 2.19 / 2.20 |
| Mem peak / limit (MiB) | 171.20 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10-thr-100.json`
- system metrics JSON: `pool-10-thr-100.metrics.json`
- system samples CSV: `pool-10-thr-100.samples.csv`
