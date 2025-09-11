import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';

// ===== Env =====
const BASE_URL = __ENV.BASE_URL || 'http://spring-app:8080';
const MEMBER_ID_MIN = Number(__ENV.MEMBER_ID_MIN || 1);
const MEMBER_ID_MAX = Number(__ENV.MEMBER_ID_MAX || 1000);
const RATE_ORDER_ME = Number(__ENV.RATE_ORDER_ME || 1000);
const TEST_DURATION = __ENV.TEST_DURATION || '3m';
const WARMUP_DURATION = __ENV.WARMUP_DURATION || '30s';
const POOL_SIZE = String(__ENV.POOL_SIZE || '20');
const THREAD_SIZE = String(__ENV.THREAD_SIZE || '100');
const DISABLE_THRESHOLDS = String(__ENV.DISABLE_THRESHOLDS || 'true').toLowerCase() === 'true';

// ===== Metrics =====
const orderMeDuration = new Trend('order_me_duration', true);
const orderMeErrors = new Counter('order_me_errors');
const status_200 = new Counter('status_200');
const status_404 = new Counter('status_404');
const status_4xx = new Counter('status_4xx');
const status_5xx = new Counter('status_5xx');

export const options = {
  scenarios: {
    warmup: {
      executor: 'constant-arrival-rate',
      rate: 10,
      timeUnit: '1s',
      duration: WARMUP_DURATION,
      preAllocatedVUs: 10,
      maxVUs: 20,
      exec: 'warmupScenario',
      startTime: '0s',
    },
    order_me: {
      executor: 'constant-arrival-rate',
      rate: RATE_ORDER_ME,
      timeUnit: '1s',
      duration: TEST_DURATION,
      preAllocatedVUs: Math.ceil(RATE_ORDER_ME * 0.5),
      maxVUs: Math.ceil(RATE_ORDER_ME * 1.5),
      exec: 'orderMeScenario',
      startTime: WARMUP_DURATION,
      tags: { scenario: 'order_me' },
    },
  },
  thresholds: DISABLE_THRESHOLDS
      ? {}
      : {
        http_req_failed: [{ threshold: 'rate<0.01' }],
        order_me_duration: [{ threshold: 'p(95)<400' }, { threshold: 'p(99)<600' }],
      },
  userAgent: `K6-OrderMeOnly-${POOL_SIZE}-${THREAD_SIZE}`,
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(50)', 'p(90)', 'p(95)', 'p(99)'],
};

// ===== Utils =====
function randInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function nz(v, d = 0) { return Number.isFinite(v) ? v : d; }

// ===== Scenarios =====
export function warmupScenario() {
  http.get(`${BASE_URL}/api/v1/orders/me/1`);
  sleep(1);
}

export function orderMeScenario() {
  const memberId = randInt(MEMBER_ID_MIN, MEMBER_ID_MAX);
  const res = http.get(
      `${BASE_URL}/api/v1/orders/me/${memberId}`,
      { tags: { api: 'order_me', pool_size: POOL_SIZE, thread_size: THREAD_SIZE }, timeout: '10s' }
  );

  if (res.status === 200) status_200.add(1);
  else if (res.status === 404) status_404.add(1);
  else if (res.status >= 400 && res.status < 500) status_4xx.add(1);
  else if (res.status >= 500) status_5xx.add(1);

  const ok = check(res, { 'OrderMe status OK': (r) => r.status === 200 });
  orderMeDuration.add(res.timings.duration);
  if (!ok) orderMeErrors.add(1);
  sleep(Math.random() * 0.1);
}

// ===== Summary Writer =====
export function handleSummary(data) {
  const get = (o, path, def = 0) => { try { const v = path.split('.').reduce((a, k) => a[k], o); return v ?? def; } catch { return def; } };

  const overall = {
    totalRequests: get(data, 'metrics.http_reqs.values.count'),
    requestsPerSecond: get(data, 'metrics.http_reqs.values.rate'),
    failureRate: get(data, 'metrics.http_req_failed.values.rate') * 100,
    responseTime: {
      avg: get(data, 'metrics.http_req_duration.values.avg'),
      med: get(data, 'metrics.http_req_duration.values.med'),
      max: get(data, 'metrics.http_req_duration.values.max'),
      p95: get(data, 'metrics.http_req_duration.values["p(95)"]'),
      p99: get(data, 'metrics.http_req_duration.values["p(99)"]'),
    },
    checks: {
      passes: get(data, 'metrics.checks.values.passes'),
      fails: get(data, 'metrics.checks.values.fails'),
    },
  };

  const api = {
    p50: get(data, 'metrics.order_me_duration.values["p(50)"]'),
    p95: get(data, 'metrics.order_me_duration.values["p(95)"]'),
    p99: get(data, 'metrics.order_me_duration.values["p(99)"]'),
    errors: get(data, 'metrics.order_me_errors.values.count'),
  };

  const md = [
    `# Benchmark Report - Pool Size ${POOL_SIZE} (Orders/Me Only)

- **Load Level**: Fixed (RPS=${RATE_ORDER_ME})
- **Generated at**: ${new Date().toLocaleString('sv-SE', { timeZone: 'Asia/Seoul' })} +09:00

## k6 Results

| Metric | Value |
|---|---:|
| http_req_duration p95 (ms) | ${nz(overall.responseTime.p95).toFixed(2)} |
| http_req_duration p99 (ms) | ${nz(overall.responseTime.p99).toFixed(2)} |
| avg / med / max (ms) | ${nz(overall.responseTime.avg).toFixed(2)} / ${nz(overall.responseTime.med).toFixed(2)} / ${nz(overall.responseTime.max).toFixed(2)} |
| http_reqs count | ${overall.totalRequests} |
| http_reqs rate (req/s) | ${nz(overall.requestsPerSecond).toFixed(2)} |
| http_req_failed (%) | ${Number.isFinite(overall.failureRate) ? overall.failureRate.toFixed(2) : '-'} |
| checks (passes / fails) | ${overall.checks.passes || 0} / ${overall.checks.fails || 0} |

### Orders/Me Latency (ms)

| p50 | p95 | p99 | errors |
|---:|---:|---:|---:|
| ${nz(api.p50).toFixed(2)} | ${nz(api.p95).toFixed(2)} | ${nz(api.p99).toFixed(2)} | ${api.errors} |
`
  ].join('');

  const csv = [
    'api,p50_ms,p95_ms,p99_ms,errors',
    `orders_me,${nz(api.p50)},${nz(api.p95)},${nz(api.p99)},${api.errors}`,
  ].join('\n');

  return {
    [`/outputs/order-me-${POOL_SIZE}.json`]: JSON.stringify(data, null, 2),
    [`/outputs/order-me-${POOL_SIZE}.md`]: md,
    [`/outputs/order-me-${POOL_SIZE}.csv`]: csv,
  };
}
