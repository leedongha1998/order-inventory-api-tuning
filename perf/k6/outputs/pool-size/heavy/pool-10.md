# **Benchmark Report - Pool Size 10**

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 20:33:28 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 7417.57 |
| http_req_duration p99 (ms) | 9190.71 |
| avg / med / max (ms) | 3951.27 / 3510.98 / 13500.91 |
| http_reqs count | 74624 |
| http_reqs rate (req/s) | 315.61 |
| http_req_failed (%) | - |
| checks (passes / fails) | 74250 / 78 |

## System Metrics (Docker containers)

### spring-app

Samples: **48** over **235s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 238.65 / 463.64 / 533.47 |
| Mem avg / max (%) | 8.65 / 9.91 |
| Mem peak / limit (MiB) | 772.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.16 |
| Block I/O throughput (read / write, B/s) | 0 / 697 |

### my-postgres

Samples: **48** over **235s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 362.16 / 492.4 / 502.66 |
| Mem avg / max (%) | 2.29 / 2.35 |
| Mem peak / limit (MiB) | 183.10 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-10.json`
- system metrics JSON: `pool-10.metrics.json`
- system samples CSV: `pool-10.samples.csv`
