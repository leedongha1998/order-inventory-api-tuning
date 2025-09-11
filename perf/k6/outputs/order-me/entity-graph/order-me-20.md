# Benchmark Report - Pool Size 20 (Orders/Me Only)

- **Load Level**: Fixed (RPS=1000)
- **Generated at**: 2025-09-11 15:17:56 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 3341.46 |
| http_req_duration p99 (ms) | 4413.51 |
| avg / med / max (ms) | 2096.15 / 1948.48 / 6216.47 |
| http_reqs count | 124765 |
| http_reqs rate (req/s) | 588.50 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 124254 / 217 |

### Orders/Me Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 1950.13 | 3343.43 | 4414.08 | 217 |

## System Metrics (Docker containers)

### spring-app

Samples: **44** over **210s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 326.93 / 498.21 / 515.53 |
| Mem avg / max (%) | 9.64 / 10.6 |
| Mem peak / limit (MiB) | 826.40 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.03 / 0.19 |
| Block I/O throughput (read / write, B/s) | 161 / 938 |

### my-postgres

Samples: **44** over **210s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 86.37 / 114.89 / 116.66 |
| Mem avg / max (%) | 1.22 / 1.28 |
| Mem peak / limit (MiB) | 99.72 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

### my-redis

Samples: **44** over **210s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 0.68 / 1.74 / 2.13 |
| Mem avg / max (%) | 0.08 / 0.08 |
| Mem peak / limit (MiB) | 6.62 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Service Metrics (Prometheus)

### HikariCP

| active | idle | pending | max |
|---:|---:|---:|---:|
| 18 | 2 | 179 | 20 |

### JVM

| heap used (MiB) | heap max (MiB) | GC pause ms/s | GC events/s |
|---:|---:|---:|---:|
| 168.38 | 1950.00 | 9.42 | 1.40 |

### PostgreSQL

| active connections | avg query time (ms) | TPS |
|---:|---:|---:|
| 3 | 0.00 | 6.20 |

### Redis

| used memory (MiB) | hit rate |
|---:|---:|
| 1.12 | 0.000 |

## Artifacts

- k6 JSON: `order-me-20.json`
- system metrics JSON: `order-me-20.metrics.json`
- system samples CSV: `order-me-20.samples.csv`
- prometheus snapshot JSON: `order-me-20.prom.json`
