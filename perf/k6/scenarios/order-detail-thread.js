// order-detail-only.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Counter } from 'k6/metrics';

// ===== Env =====
const BASE_URL = __ENV.BASE_URL || 'http://spring-app:8080';
const POOL_SIZE = __ENV.POOL_SIZE || '10';        // CP
const THREADS = __ENV.THREADS || '50';            // TP
const TEST_DURATION = __ENV.TEST_DURATION || '3m';
const WARMUP_DURATION = __ENV.WARMUP_DURATION || '30s';
const DISABLE_THRESHOLDS = String(__ENV.DISABLE_THRESHOLDS || 'true').toLowerCase() === 'true';
const VERBOSE_ERRORS = String(__ENV.VERBOSE_ERRORS || 'false').toLowerCase() === 'true';
const LOG_4XX = String(__ENV.LOG_4XX || 'false').toLowerCase() === 'true';
const SAMPLE_LIMIT = Number(__ENV.SAMPLE_LIMIT || 20);
let printed = 0;

// Load (req/s)
const RATE_ORDER_DETAIL = Number(__ENV.RATE_ORDER_DETAIL || 150);

// Test data range
const ORDER_ID_MIN = Number(__ENV.ORDER_ID_MIN || 1);
const ORDER_ID_MAX = Number(__ENV.ORDER_ID_MAX || 10000);

// ===== Metrics =====
const orderDetailDuration = new Trend('order_detail_duration', true);
const orderDetailErrors = new Counter('order_detail_errors');
const status_200 = new Counter('status_200');
const status_404 = new Counter('status_404');
const status_4xx = new Counter('status_4xx'); // excluding 404
const status_5xx = new Counter('status_5xx');
const status_other = new Counter('status_other');

export let options = {
  scenarios: {
    warmup: {
      executor: 'constant-arrival-rate',
      rate: 10, timeUnit: '1s',
      duration: WARMUP_DURATION,
      preAllocatedVUs: 10, maxVUs: 20,
      exec: 'warmupScenario', startTime: '0s',
    },
    order_detail: {
      executor: 'constant-arrival-rate',
      rate: RATE_ORDER_DETAIL, timeUnit: '1s',
      duration: TEST_DURATION,
      preAllocatedVUs: Math.ceil(RATE_ORDER_DETAIL * 0.5),
      maxVUs: Math.ceil(RATE_ORDER_DETAIL * 1.5),
      exec: 'orderDetailScenario', startTime: WARMUP_DURATION,
      tags: { scenario: 'order_detail', pool_size: POOL_SIZE, threads: THREADS },
    },
  },
  thresholds: DISABLE_THRESHOLDS ? {} : {
    http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: false }],
    http_req_duration: [
      { threshold: 'p(95)<400', abortOnFail: false },
      { threshold: 'p(99)<600', abortOnFail: false },
    ],
    order_detail_duration: [
      { threshold: 'p(50)<150', abortOnFail: false },
      { threshold: 'p(95)<400', abortOnFail: false },
      { threshold: 'p(99)<600', abortOnFail: false },
    ],
    order_detail_errors: [{ threshold: 'count<10', abortOnFail: false }],
  },
  noConnectionReuse: false,
  userAgent: `K6-OrderDetailOnly-CP${POOL_SIZE}-TP${THREADS}`,
  summaryTrendStats: ['avg','min','med','max','p(50)','p(90)','p(95)','p(99)'],
};

function randInt(min, max){ return Math.floor(Math.random()*(max-min+1))+min; }

export function warmupScenario(){
  http.get(`${BASE_URL}/api/v1/orders/1`); sleep(1);
}

export function orderDetailScenario(){
  const orderId = randInt(ORDER_ID_MIN, ORDER_ID_MAX);
  const res = http.get(`${BASE_URL}/api/v1/orders/${orderId}`, {
    tags: { api: 'order_detail', pool_size: POOL_SIZE, threads: THREADS },
    timeout: '10s',
  });

  if (LOG_4XX && res.status >= 400 && res.status < 500 && printed < SAMPLE_LIMIT) {
    const line = `4xx id=${orderId} status=${res.status} hdr=${JSON.stringify(res.headers)} body=${String(res.body).slice(0,200).replace(/\n/g,' ')}`;
    console.log(line); console.error(line); printed++;
  }

  if (res.status === 200) status_200.add(1);
  else if (res.status === 404) status_404.add(1);
  else if (res.status >= 400 && res.status < 500) status_4xx.add(1);
  else if (res.status >= 500) status_5xx.add(1);
  else status_other.add(1);

  const ok = check(res, { 'OrderDetail status OK': (r) => r.status === 200 });
  orderDetailDuration.add(res.timings.duration);
  if (!ok) orderDetailErrors.add(1);
  sleep(Math.random() * 0.1);
}

export function handleSummary(data){
  const poolSize = POOL_SIZE, threads = THREADS;
  const get = (o, path, def = 0) => { try { const v = path.split('.').reduce((a,k)=>a[k], o); return v ?? def; } catch { return def; } };
  const getAny = (paths, def = 0) => { for (const p of paths) { const v = get(data, p, null); if (v !== null && v !== undefined) return v; } return def; };

  const summary = {
    testInfo: { poolSize, threads, baseUrl: BASE_URL, duration: TEST_DURATION, timestamp: new Date().toISOString(), thresholdsEnabled: !DISABLE_THRESHOLDS },
    overall: {
      totalRequests: get(data,'metrics.http_reqs.values.count'),
      requestsPerSecond: get(data,'metrics.http_reqs.values.rate'),
      failureRate: get(data,'metrics.http_req_failed.values.rate') * 100,
      responseTime: {
        avg: get(data,'metrics.http_req_duration.values.avg'),
        min: get(data,'metrics.http_req_duration.values.min'),
        med: get(data,'metrics.http_req_duration.values.med'),
        max: get(data,'metrics.http_req_duration.values.max'),
        p95: get(data,'metrics.http_req_duration.values.p(95)'),
        p99: get(data,'metrics.http_req_duration.values.p(99)'),
      },
    },
    apis: {
      orderDetail: {
        count: get(data,'metrics.order_detail_duration.values.count'),
        errors: get(data,'metrics.order_detail_errors.values.count'),
        responseTime: {
          avg: get(data,'metrics.order_detail_duration.values.avg'),
          p50: get(data,'metrics.order_detail_duration.values.p(50)'),
          p95: get(data,'metrics.order_detail_duration.values.p(95)'),
          p99: get(data,'metrics.order_detail_duration.values.p(99)'),
        },
      },
    },
    status: {
      s200: get(data,'metrics.status_200.values.count'),
      s404: get(data,'metrics.status_404.values.count'),
      s4xx: get(data,'metrics.status_4xx.values.count'),
      s5xx: get(data,'metrics.status_5xx.values.count'),
      other: get(data,'metrics.status_other.values.count'),
    },
    checks: {
      passes: getAny(['metrics.checks.passes','metrics.checks.values.passes'], 0),
      fails:  getAny(['metrics.checks.fails','metrics.checks.values.fails'], 0),
    },
    thresholds: data.thresholds,
  };

  // 이 스크립트는 MD를 생성하지 않습니다(PS1에서 단일 MD 생성).
  const base = `/outputs/pool-${poolSize}-thr-${threads}`;
  return {
    [`${base}.json`]: JSON.stringify(summary, null, 2),
    [`${base}.csv`]: [
      'api,cp,tp,p50_ms,p95_ms,p99_ms,errors,200,404,4xx_else,5xx,other',
      `order_detail,${poolSize},${threads},${summary.apis.orderDetail.responseTime.p50},${summary.apis.orderDetail.responseTime.p95},${summary.apis.orderDetail.responseTime.p99},${summary.apis.orderDetail.errors},${summary.status.s200},${summary.status.s404},${summary.status.s4xx},${summary.status.s5xx},${summary.status.other}`,
    ].join('\n'),
  };
}
