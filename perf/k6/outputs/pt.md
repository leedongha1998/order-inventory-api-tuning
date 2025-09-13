# Order Write Bench - np

- **Generated at**: 2025-09-13 15:57:41 +09:00
- **Resolved BASE_URL**: http://spring-app:8080
- **Resolved PATH_PREFIX**: /api/v1/orders/np
- **Request Body ?덉떆**:

```json
{ "memberId": 1, "price": 1, "createdAt": "yyyy-MM-dd'T'HH:mm:ss" }
```

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 15.59 |
| http_req_duration p99 (ms) | 0 |
| avg / med / max (ms) | 10.21 / 6.87 / 1736.48 |
| http_reqs count | 120001 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 120001 / 0 |
