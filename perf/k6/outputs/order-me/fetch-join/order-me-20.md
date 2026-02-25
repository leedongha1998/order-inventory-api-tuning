# Benchmark Report - Pool Size 20 (Orders/Me Only)

- **Load Level**: Fixed (RPS=1000)
- **Generated at**: 2025-09-11 14:05:50 +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 4691.41 |
| http_req_duration p99 (ms) | 6057.44 |
| avg / med / max (ms) | 1980.35 / 1693.71 / 8098.33 |
| http_reqs count | 144186 |
| http_reqs rate (req/s) | 613.56 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 143809 / 83 |

### Orders/Me Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| 1695.07 | 4692.85 | 6058.04 | 83 |

## System Metrics (Docker containers)

### spring-app

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 369.75 / 562.75 / 608.96 |
| Mem avg / max (%) | 9.68 / 10.56 |
| Mem peak / limit (MiB) | 823.40 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.04 / 0.18 |
| Block I/O throughput (read / write, B/s) | 182 / 801 |

### my-postgres

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 97.46 / 127.41 / 131.46 |
| Mem avg / max (%) | 1.19 / 1.25 |
| Mem peak / limit (MiB) | 97.69 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

### my-redis

Samples: **47** over **230s**

| Metric | Value |
|---|---:|
| CPU avg / p95 / max (%) | 0.56 / 1.58 / 1.82 |
| Mem avg / max (%) | 0.08 / 0.08 |
| Mem peak / limit (MiB) | 6.48 / 7794.69 |
| Block I/O total (read / write, MiB) | 0.00 / 0.00 |
| Block I/O throughput (read / write, B/s) | 0 / 0 |

## Service Metrics (Prometheus)

### HikariCP

| active | idle | pending | max |
|---:|---:|---:|---:|
| 19 | 1 | 170 | 20 |

### JVM

| heap used (MiB) | heap max (MiB) | GC pause ms/s | GC events/s |
|---:|---:|---:|---:|
| 261.37 | 1950.00 | 8.06 | 1.33 |

### PostgreSQL

| active connections | avg query time (ms) | TPS |
|---:|---:|---:|
| 4 | 0.00 | 5.79 |

### Redis

| used memory (MiB) | hit rate |
|---:|---:|
| 1.12 | 0.000 |

## Artifacts

- k6 JSON: `order-me-20.json`
- system metrics JSON: `order-me-20.metrics.json`
- system samples CSV: `order-me-20.samples.csv`
- prometheus snapshot JSON: `order-me-20.prom.json`
