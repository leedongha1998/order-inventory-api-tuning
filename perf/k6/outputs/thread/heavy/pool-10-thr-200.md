# **Benchmark Report - Pool Size 10**

- **Load Level**: Heavy
- **Generated at**: 2025-09-10 13:04:03 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 2164.61 |
| http_req_duration p99 (ms) | 3046.72 |
| avg / med / max (ms) | 540.81 / 17.75 / 4893.60 |
| http_reqs count | 168670 |
| http_reqs rate (req/s) | 793.67 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 168371 / 2 |

## System Metrics (Docker containers)

### spring-app

Samples: **45** over **207s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 305.02 / 530.19 / 538.82 |
| Mem avg / max (%) | 8.32 / 9.05 |
| Mem peak / limit (MiB) | 705.70 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.19 |
| Block I/O throughput (read / write, B/s) | 0 / 951 |

### my-postgres

Samples: **45** over **207s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 77.77 / 106.94 / 110.43 |
| Mem avg / max (%) | 0.91 / 0.95 |
| Mem peak / limit (MiB) | 74.36 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10-thr-200.json`
- system metrics JSON: `pool-10-thr-200.metrics.json`
- system samples CSV: `pool-10-thr-200.samples.csv`
