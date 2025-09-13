# Benchmark Report - SEQUENCE Strategy

- **Load Level**: Fixed (RPS=500)
- **Generated at**: 2025-09-12 00:49:21 +09:00
- **PoolSize / ThreadMax**: 20 / 100

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 2850.44 |
| http_req_duration p99 (ms) | 3683.19 |
| avg / med / max (ms) | 543.55 / 33.70 / 5226.68 |
| http_reqs count | 90587 |
| http_reqs rate (req/s) | 413.50 |
| http_req_failed (%) | 0.00 |

## System Metrics (Docker containers)

### spring-app

Samples: **44** over **219s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 352.05 / 588.03 / 732.95 |
| Mem avg / max (%) | 11.01 / 12.03 |
| Mem peak / limit (MiB) | 937.80 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.19 |
| Block I/O throughput (read / write, B/s) | 0 / 898 |

### my-postgres

Samples: **44** over **219s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 72.16 / 103.19 / 132.78 |
| Mem avg / max (%) | 1.66 / 1.73 |
| Mem peak / limit (MiB) | 134.60 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

### my-redis

Samples: **44** over **219s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 0.6 / 1.48 / 2.14 |
| Mem avg / max (%) | 0.08 / 0.08 |
| Mem peak / limit (MiB) | 6.56 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Service Metrics (Prometheus)

### HikariCP

| active | idle | pending | max |
|---:|---:|---:|---:|
| 20 | 0 | 176 | 20 |

### JVM

| heap used (MiB) | heap max (MiB) | GC pause ms/s | GC events/s |
|---:|---:|---:|---:|
| 301.52 | 1950.00 | 6.07 | 0.74 |

### PostgreSQL

| active connections | avg query time (ms) | TPS |
|---:|---:|---:|
| 0 | 0.00 | 4.28 |

### Redis

| used memory (MiB) | hit rate |
|---:|---:|
| 1.11 | 0.000 |

## Artifacts

- k6 JSON: `identity-pool-20.json`
- system metrics JSON: `identity-pool-20.metrics.json`
- system samples CSV: `identity-pool-20.samples.csv`
- prometheus snapshot JSON: `identity-pool-20.prom.json`
