# **Benchmark Report - Pool Size 10**

- **Load Level**: Light
- **Generated at**: 2025-09-10 01:37:55 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 9.90 |
| http_req_duration p99 (ms) | 16.88 |
| avg / med / max (ms) | 5.39 / 4.63 / 418.16 |
| http_reqs count | 18298 |
| http_reqs rate (req/s) | 86.92 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 18000 / 0 |

## System Metrics (Docker containers)

### spring-app

Samples: **46** over **209s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 50.82 / 90.84 / 240.51 |
| Mem avg / max (%) | 5.77 / 5.88 |
| Mem peak / limit (MiB) | 458.30 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.16 |
| Block I/O throughput (read / write, B/s) | 0 / 824 |

### my-postgres

Samples: **46** over **209s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 10.35 / 17.84 / 20.08 |
| Mem avg / max (%) | 2.17 / 2.22 |
| Mem peak / limit (MiB) | 173.10 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10-thr-50.json`
- system metrics JSON: `pool-10-thr-50.metrics.json`
- system samples CSV: `pool-10-thr-50.samples.csv`
