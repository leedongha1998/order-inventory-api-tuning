# Benchmark Report - Pool Size 30 (Order Detail Only)

- **Load Level**: Heavy
- **Generated at**: 2025-09-09 21:01:13 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 3045.82 |
| http_req_duration p99 (ms) | 6059.68 |
| avg / med / max (ms) | 791.18 / 302.04 / 9352.10 |
| http_reqs count | 162046 |
| http_reqs rate (req/s) | 690.33 |

### Order Detail Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 303.82 | 3047.60 | 6061.52 | 10 |

## System Metrics (Docker containers)

### spring-app

Samples: **48** over **235s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 356 / 533.53 / 567.7 |
| Mem avg / max (%) | 8.46 / 9.33 |
| Mem peak / limit (MiB) | 727.30 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.20 |
| Block I/O throughput (read / write, B/s) | 0 / 873 |

### my-postgres

Samples: **48** over **235s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 91.07 / 124.21 / 146.46 |
| Mem avg / max (%) | 2.56 / 2.67 |
| Mem peak / limit (MiB) | 208.40 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Artifacts

- k6 JSON: `pool-30.json`
- system metrics JSON: `pool-30.metrics.json`
- system samples CSV: `pool-30.samples.csv`
