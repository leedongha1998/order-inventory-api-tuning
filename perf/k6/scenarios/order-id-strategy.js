// order-id-strategy-seq.js
// k6 script for create-order benchmark with ID strategy comparison
// Sequence 전략 테스트용: 배치 insert 관찰을 위해 아이템 수를 늘리는 옵션 추가
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://spring-app:8080';
const ENDPOINT = '/api/v1/orders';

const DURATION = __ENV.TEST_DURATION || '3m';
const RATE_RPS = Number(__ENV.RATE_RPS || 1000);
const WARMUP_RPS = Number(__ENV.WARMUP_RPS || 100);
const WARMUP_DURATION = __ENV.WARMUP_DURATION || '30s';

const MEMBER_ID_MIN = Number(__ENV.MEMBER_ID_MIN || 1);
const MEMBER_ID_MAX = Number(__ENV.MEMBER_ID_MAX || 10000);

const PRODUCT_ID_MIN = Number(__ENV.PRODUCT_ID_MIN || 1);
const PRODUCT_ID_MAX = Number(__ENV.PRODUCT_ID_MAX || 20000);

// 기본 아이템 범위
const ITEMS_MIN_BASE = Number(__ENV.ITEMS_MIN || 1);
const ITEMS_MAX_BASE = Number(__ENV.ITEMS_MAX || 3);

// 배치 모드: auto|on|off  (auto=SEQUENCE일 때 on)
const BATCH_MODE = (__ENV.BATCH_MODE || 'auto').toLowerCase();
const BATCH_ITEMS_MIN = Number(__ENV.BATCH_ITEMS_MIN || 5);
const BATCH_ITEMS_MAX = Number(__ENV.BATCH_ITEMS_MAX || 12);

const IDEMPOTENCY = (__ENV.IDEMPOTENCY || 'false').toLowerCase() === 'true';
const IDEMPOTENCY_HEADER = __ENV.IDEMPOTENCY_HEADER || 'Idempotency-Key';

// 기본값을 SEQUENCE로 고정. 필요 시 IDENTITY로 덮어쓰기.
const ID_STRATEGY = (__ENV.ID_STRATEGY || 'SEQUENCE').toUpperCase();
const POOL_SIZE = Number(__ENV.POOL_SIZE || 20);
const THREAD_SIZE = Number(__ENV.THREAD_SIZE || 100);

// ---- Metrics ----
const createDuration = new Trend('order_create_duration', true);
const createErrors = new Counter('order_create_errors');
const createSuccess = new Counter('order_create_success');
const status_2xx = new Counter('status_2xx');
const status_4xx = new Counter('status_4xx');
const status_5xx = new Counter('status_5xx');
const status_other = new Counter('status_other');

const isBatchOn = BATCH_MODE === 'on' || (BATCH_MODE === 'auto' && ID_STRATEGY === 'SEQUENCE');

export const options = {
  tags: {
    idStrategy: ID_STRATEGY,
    poolSize: String(POOL_SIZE),
    batchMode: isBatchOn ? 'on' : 'off',
  },
  scenarios: {
    warmup: {
      executor: 'constant-arrival-rate',
      startTime: '0s',
      duration: WARMUP_DURATION,
      rate: WARMUP_RPS,
      timeUnit: '1s',
      preAllocatedVUs: Math.max(50, Math.ceil(WARMUP_RPS * 0.5)),
      maxVUs: Math.max(200, WARMUP_RPS * 2),
      exec: 'createOrder',
      tags: { phase: 'warmup' },
    },
    main: {
      executor: 'constant-arrival-rate',
      startTime: WARMUP_DURATION,
      duration: DURATION,
      rate: RATE_RPS,
      timeUnit: '1s',
      preAllocatedVUs: Math.max(200, Math.ceil(RATE_RPS * 0.6)),
      maxVUs: Math.max(4000, RATE_RPS * 3),
      exec: 'createOrder',
      tags: { phase: 'main' },
    },
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(50)', 'p(90)', 'p(95)', 'p(99)'],
  noConnectionReuse: false,
  userAgent: `K6-OrderCreate-${ID_STRATEGY}-Pool${POOL_SIZE}-Batch${isBatchOn ? 'On' : 'Off'}`,
};

// ---- Helpers ----
function rnd(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function genItems() {
  const min = isBatchOn ? BATCH_ITEMS_MIN : ITEMS_MIN_BASE;
  const max = isBatchOn ? BATCH_ITEMS_MAX : ITEMS_MAX_BASE;
  const n = rnd(min, max);

  const seen = new Set();
  const items = [];
  for (let i = 0; i < n; i++) {
    // 중복 productId를 피하려고 간단히 재시도
    let pid = rnd(PRODUCT_ID_MIN, PRODUCT_ID_MAX);
    let tries = 0;
    while (seen.has(pid) && tries < 5) {
      pid = rnd(PRODUCT_ID_MIN, PRODUCT_ID_MAX);
      tries++;
    }
    seen.add(pid);
    items.push({ productId: pid, quantity: 1, couponId: 1 });
  }
  return items;
}

// ---- VU exec ----
export function createOrder() {
  const memberId = rnd(MEMBER_ID_MIN, MEMBER_ID_MAX);
  const payload = JSON.stringify({ memberId, items: genItems() });

  const headers = { 'Content-Type': 'application/json' };
  if (IDEMPOTENCY) headers[IDEMPOTENCY_HEADER] = `${memberId}-${Date.now()}-${Math.random()}`;
  if (isBatchOn) headers['X-Batch-Hint'] = 'true'; // 서버 로깅/필터에서 참고용(미사용이면 무해)

  const res = http.post(`${BASE_URL}${ENDPOINT}`, payload, {
    headers,
    tags: {
      api: 'order_create',
      strategy: ID_STRATEGY,
      pool_size: POOL_SIZE,
      batch_mode: isBatchOn ? 'on' : 'off',
    },
    timeout: '30s',
  });

  if (res.status >= 200 && res.status < 300) status_2xx.add(1);
  else if (res.status >= 400 && res.status < 500) status_4xx.add(1);
  else if (res.status >= 500) status_5xx.add(1);
  else status_other.add(1);

  const ok = check(res, {
    'status 2xx/201': (r) => r.status === 201 || r.status === 200,
    'response time < 30s': (r) => r.timings.duration < 30000,
    'has order id': (r) => {
      try {
        const b = r.json();
        return !!(b && (b.orderId || b.id));
      } catch {
        return false;
      }
    },
  });

  createDuration.add(res.timings.duration);
  if (ok) createSuccess.add(1);
  else {
    createErrors.add(1);
    if (createErrors.count <= 10) {
      console.log(`Error ${createErrors.count}: Status ${res.status}, Duration ${res.timings.duration}ms`);
      if (res.body && res.body.length < 500) console.log(`Body: ${res.body.slice(0, 200)}`);
    }
  }

  sleep(Math.random() * 0.02);
}

// ---- Summary ----
export function handleSummary(data) {
  const strategy = ID_STRATEGY || 'unknown';
  const poolSize = POOL_SIZE || 'unknown';
  const batchFlag = isBatchOn ? 'on' : 'off';

  const getMetric = (name, field, def = 0) => {
    try {
      const m = data.metrics[name];
      if (!m) return def;
      if (m[field] !== undefined) return m[field];
      if (m.values && m.values[field] !== undefined) return m.values[field];
      return def;
    } catch { return def; }
  };

  const summary = {
    testInfo: {
      strategy,
      poolSize,
      batchMode: batchFlag,
      duration: DURATION,
      rateRps: RATE_RPS,
      itemsRange: isBatchOn ? [BATCH_ITEMS_MIN, BATCH_ITEMS_MAX] : [ITEMS_MIN_BASE, ITEMS_MAX_BASE],
      timestamp: new Date().toISOString(),
    },
    performance: {
      totalRequests: getMetric('http_reqs', 'count'),
      requestsPerSecond: getMetric('http_reqs', 'rate'),
      failureRate: getMetric('http_req_failed', 'rate') * 100,
      responseTime: {
        avg: getMetric('http_req_duration', 'avg'),
        min: getMetric('http_req_duration', 'min'),
        med: getMetric('http_req_duration', 'med'),
        max: getMetric('http_req_duration', 'max'),
        p50: getMetric('http_req_duration', 'p(50)'),
        p90: getMetric('http_req_duration', 'p(90)'),
        p95: getMetric('http_req_duration', 'p(95)'),
        p99: getMetric('http_req_duration', 'p(99)'),
      },
      orderCreate: {
        duration: {
          avg: getMetric('order_create_duration', 'avg'),
          p50: getMetric('order_create_duration', 'p(50)'),
          p95: getMetric('order_create_duration', 'p(95)'),
          p99: getMetric('order_create_duration', 'p(99)'),
        },
        success: getMetric('order_create_success', 'count'),
        errors: getMetric('order_create_errors', 'count'),
      },
    },
    statusCodes: {
      '2xx': getMetric('status_2xx', 'count'),
      '4xx': getMetric('status_4xx', 'count'),
      '5xx': getMetric('status_5xx', 'count'),
      other: getMetric('status_other', 'count'),
    },
  };

  const outputs = {};
  const base = `/outputs/${strategy.toLowerCase()}-batch-${batchFlag}-pool-${poolSize}`;
  outputs[`${base}.json`] = JSON.stringify(summary, null, 2);
  outputs[`${base}.csv`] =
      [
        'strategy,batch_mode,pool_size,rps,total_requests,requests_per_sec,failure_rate_pct,avg_ms,p50_ms,p95_ms,p99_ms,max_ms,success_count,error_count,status_2xx,status_4xx,status_5xx',
        `${strategy},${batchFlag},${poolSize},${RATE_RPS},${summary.performance.totalRequests},${summary.performance.requestsPerSecond.toFixed(2)},${summary.performance.failureRate.toFixed(2)},${summary.performance.responseTime.avg.toFixed(2)},${summary.performance.responseTime.p50.toFixed(2)},${summary.performance.responseTime.p95.toFixed(2)},${summary.performance.responseTime.p99.toFixed(2)},${summary.performance.responseTime.max.toFixed(2)},${summary.performance.orderCreate.success},${summary.performance.orderCreate.errors},${summary.statusCodes['2xx']},${summary.statusCodes['4xx']},${summary.statusCodes['5xx']}`,
      ].join('\n');

  return outputs;
}
