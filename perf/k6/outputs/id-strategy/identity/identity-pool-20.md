# Benchmark Report - IDENTITY Strategy

- **Load Level**: Fixed (RPS=500)
- **Generated at**: 2025-09-12 00:23:33 +09:00
- **PoolSize / ThreadMax**: 20 / 100

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 3985.98 |
| http_req_duration p99 (ms) | 4937.75 |
| avg / med / max (ms) | 743.07 / 19.14 / 6392.16 |
| http_reqs count | 89191 |
| http_reqs rate (req/s) | 411.22 |
| http_req_failed (%) | 0.00 |

## System Metrics (Docker containers)

### spring-app

Samples: **44** over **215s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 346.33 / 594.53 / 718.13 |
| Mem avg / max (%) | 10.15 / 10.92 |
| Mem peak / limit (MiB) | 851.30 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.18 |
| Block I/O throughput (read / write, B/s) | 0 / 877 |

### my-postgres

Samples: **44** over **215s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 65.53 / 92.28 / 94.89 |
| Mem avg / max (%) | 1.59 / 1.65 |
| Mem peak / limit (MiB) | 128.40 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

### my-redis

Samples: **44** over **215s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 0.5 / 1.65 / 1.96 |
| Mem avg / max (%) | 0.08 / 0.08 |
| Mem peak / limit (MiB) | 6.32 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Service Metrics (Prometheus)

### HikariCP

| active | idle | pending | max |
|---:|---:|---:|---:|
| 5 | 15 | 0 | 20 |

### JVM

| heap used (MiB) | heap max (MiB) | GC pause ms/s | GC events/s |
|---:|---:|---:|---:|
| 260.07 | 1950.00 | 4.46 | 0.67 |

### PostgreSQL

| active connections | avg query time (ms) | TPS |
|---:|---:|---:|
| 3 | 0.00 | 6.10 |

### Redis

| used memory (MiB) | hit rate |
|---:|---:|
| 1.11 | 0.000 |

## Artifacts

- k6 JSON: `identity-pool-20.json`
- system metrics JSON: `identity-pool-20.metrics.json`
- system samples CSV: `identity-pool-20.samples.csv`
- prometheus snapshot JSON: `identity-pool-20.prom.json`
