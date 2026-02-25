# Benchmark Report - Pool Size 30

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 20:43:11 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 7787.27 |
| http_req_duration p99 (ms) | 10136.76 |
| avg / med / max (ms) | 3929.99 / 3189.98 / 15077.33 |
| http_reqs count | 75020 |
| http_reqs rate (req/s) | 317.53 |
| http_req_failed (%) | - |
| checks (passes / fails) | 74408 / 316 |

## System Metrics (Docker containers)

### spring-app

Samples: **48** over **233s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 260.21 / 499.38 / 592.98 |
| Mem avg / max (%) | 8.58 / 9.68 |
| Mem peak / limit (MiB) | 754.40 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.20 |
| Block I/O throughput (read / write, B/s) | 0 / 883 |

### my-postgres

Samples: **48** over **233s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 357.85 / 520.82 / 529.85 |
| Mem avg / max (%) | 2.9 / 3.07 |
| Mem peak / limit (MiB) | 239.50 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-30.json`
- system metrics JSON: `pool-30.metrics.json`
- system samples CSV: `pool-30.samples.csv`
