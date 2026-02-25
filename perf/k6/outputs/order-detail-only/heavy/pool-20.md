# Benchmark Report - Pool Size 20 (Order Detail Only)

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 20:56:26 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 2228.41 |
| http_req_duration p99 (ms) | 5603.67 |
| avg / med / max (ms) | 549.45 / 90.81 / 9211.15 |
| http_reqs count | 170450 |
| http_reqs rate (req/s) | 725.31 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 91.69 | 2229.16 | 5605.23 | 2 |

## System Metrics (Docker containers)

### spring-app

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 347.87 / 557.67 / 590.53 |
| Mem avg / max (%) | 8.69 / 9.46 |
| Mem peak / limit (MiB) | 737.10 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.12 |
| Block I/O throughput (read / write, B/s) | 0 / 546 |

### my-postgres

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 88.46 / 127.93 / 129.28 |
| Mem avg / max (%) | 2.36 / 2.44 |
| Mem peak / limit (MiB) | 190.20 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-20.json`
- system metrics JSON: `pool-20.metrics.json`
- system samples CSV: `pool-20.samples.csv`
