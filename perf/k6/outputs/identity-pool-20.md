# Benchmark Report - IDENTITY Strategy

- **Load Level**: Fixed (RPS=500)
- **Generated at**: 2025-09-12 01:06:10 +09:00
- **PoolSize / ThreadMax**: 20 / 100

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 7506.18 |
| http_req_duration p99 (ms) | 9463.06 |
| avg / med / max (ms) | 2132.35 / 127.19 / 11491.60 |
| http_reqs count | 85424 |
| http_reqs rate (req/s) | 392.87 |
| http_req_failed (%) | 0.00 |

## System Metrics (Docker containers)

### spring-app

Samples: **44** over **217s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 359.03 / 553.24 / 648.46 |
| Mem avg / max (%) | 11.38 / 12.79 |
| Mem peak / limit (MiB) | 997.10 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.20 |
| Block I/O throughput (read / write, B/s) | 0 / 965 |

### my-postgres

Samples: **44** over **217s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 71.59 / 104.05 / 108.65 |
| Mem avg / max (%) | 1.66 / 1.73 |
| Mem peak / limit (MiB) | 134.70 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

### my-redis

Samples: **44** over **217s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 0.69 / 2 / 4.25 |
| Mem avg / max (%) | 0.08 / 0.08 |
| Mem peak / limit (MiB) | 6.56 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Service Metrics (Prometheus)

### HikariCP

| active | idle | pending | max |
|---:|---:|---:|---:|
| 2 | 18 | 0 | 20 |

### JVM

| heap used (MiB) | heap max (MiB) | GC pause ms/s | GC events/s |
|---:|---:|---:|---:|
| 250.41 | 1950.00 | 4.68 | 0.69 |

### PostgreSQL

| active connections | avg query time (ms) | TPS |
|---:|---:|---:|
| 3 | 0.00 | 5.93 |

### Redis

| used memory (MiB) | hit rate |
|---:|---:|
| 1.11 | 0.000 |

## Artifacts

- k6 JSON: `identity-pool-20.json`
- system metrics JSON: `identity-pool-20.metrics.json`
- system samples CSV: `identity-pool-20.samples.csv`
- prometheus snapshot JSON: `identity-pool-20.prom.json`
