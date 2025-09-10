# **Benchmark Report - Pool Size 10**

- **Load Level**: Heavy
- **Generated at**: 2025-09-10 12:56:12 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 2351.51 |
| http_req_duration p99 (ms) | 3156.26 |
| avg / med / max (ms) | 1120.42 / 1164.18 / 5139.67 |
| http_reqs count | 164306 |
| http_reqs rate (req/s) | 775.95 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 164008 / 0 |

## System Metrics (Docker containers)

### spring-app

Samples: **45** over **211s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 319.53 / 513.52 / 557.20 |
| Mem avg / max (%) | 8.70 / 9.63 |
| Mem peak / limit (MiB) | 750.70 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.16 |
| Block I/O throughput (read / write, B/s) | 0 / 776 |

### my-postgres

Samples: **45** over **211s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 81.85 / 111.65 / 113.48 |
| Mem avg / max (%) | 0.89 / 0.94 |
| Mem peak / limit (MiB) | 73.46 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10-thr-100.json`
- system metrics JSON: `pool-10-thr-100.metrics.json`
- system samples CSV: `pool-10-thr-100.samples.csv`
