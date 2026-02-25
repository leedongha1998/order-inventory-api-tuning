# Benchmark Report - Pool Size 20 (Orders/Me Only)

- **Load Level**: Fixed (RPS=1000)
- **Generated at**: 2025-09-11 02:14:17 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 3756.91 |
| http_req_duration p99 (ms) | 5207.80 |
| avg / med / max (ms) | 1790.67 / 1553.59 / 7953.08 |
| http_reqs count | 154876 |
| http_reqs rate (req/s) | 666.08 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 154535 / 48 |

### Orders/Me Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 1554.75 | 3759.38 | 5210.52 | 48 |

## System Metrics (Docker containers)

### spring-app

Samples: **94** over **1331s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 366.94 / 545.94 / 609.24 |
| Mem avg / max (%) | 9.46 / 10.5 |
| Mem peak / limit (MiB) | 818.30 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.18 |
| Block I/O throughput (read / write, B/s) | 0 / 142 |

### my-postgres

Samples: **94** over **1331s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 95.37 / 125.29 / 129.51 |
| Mem avg / max (%) | 1.19 / 1.25 |
| Mem peak / limit (MiB) | 97.65 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

### my-redis

Samples: **94** over **1331s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 0.56 / 1.52 / 9.1 |
| Mem avg / max (%) | 0.08 / 0.09 |
| Mem peak / limit (MiB) | 6.63 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Service Metrics (Prometheus)

### HikariCP

| active | idle | pending | max |
|---:|---:|---:|---:|
| 20 | 0 | 68 | 20 |

### JVM

| heap used (MiB) | heap max (MiB) | GC pause ms/s | GC events/s |
|---:|---:|---:|---:|
| 261.65 | 1950.00 | 9.59 | 1.47 |

### PostgreSQL

| active connections | avg query time (ms) | TPS |
|---:|---:|---:|
| 6 | 0.00 | 5.86 |

### Redis

| used memory (MiB) | hit rate |
|---:|---:|
| 1.10 | 0.000 |

## Artifacts

- k6 JSON: `order-me-20.json`
- system metrics JSON: `order-me-20.metrics.json`
- system samples CSV: `order-me-20.samples.csv`
- prometheus snapshot JSON: `order-me-20.prom.json`
