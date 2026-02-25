# Order Write Bench - np

- **Generated at**: 2025-09-13 16:09:34 +09:00
- **Resolved BASE_URL**: http://spring-app:8080
- **Resolved PATH_PREFIX**: /api/v1/orders/np
- **Request Body ?덉떆**:

```json
{ "memberId": 1, "price": 1, "createdAt": "yyyy-MM-dd'T'HH:mm:ss" }
```

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | 18.44 |
| http_req_duration p99 (ms) | 0 |
| avg / med / max (ms) | 12.19 / 8.07 / 1573.77 |
| http_reqs count | 119958 |
| http_req_failed (%) | 0.00 |
| checks (passes / fails) | 119958 / 0 |
