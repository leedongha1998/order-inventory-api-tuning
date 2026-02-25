// perf/k6/scenarios/pool-performance-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Counter, Gauge } from 'k6/metrics';

/**
 * Data-first run: thresholds can be disabled to focus on raw measurements.
 * Toggle via env: DISABLE_THRESHOLDS=true (default true in this file).
 */

// ===== Env =====
const BASE_URL = __ENV.BASE_URL || 'http://spring-app:8080';
const POOL_SIZE = __ENV.POOL_SIZE || '10';
const TEST_DURATION = __ENV.TEST_DURATION || '3m';
const WARMUP_DURATION = __ENV.WARMUP_DURATION || '30s';
const COOLDOWN_DURATION = __ENV.COOLDOWN_DURATION || '30s';
const DISABLE_THRESHOLDS = String(__ENV.DISABLE_THRESHOLDS || 'true').toLowerCase() === 'true';
const VERBOSE_ERRORS = String(__ENV.VERBOSE_ERRORS || 'false').toLowerCase() === 'true';

// Load mix (req/s)
const RATE_PRODUCTS = Number(__ENV.RATE_PRODUCTS || 300);       // 60% - 제품 조회
const RATE_ORDER_DETAIL = Number(__ENV.RATE_ORDER_DETAIL || 150); // 30% - 주문 조회
const RATE_ORDER_CREATE = Number(__ENV.RATE_ORDER_CREATE || 50);   // 10% - 주문 생성

// Test data ranges
const ORDER_ID_MIN = Number(__ENV.ORDER_ID_MIN || 1);
const ORDER_ID_MAX = Number(__ENV.ORDER_ID_MAX || 10000);
const PRODUCT_ID_MIN = Number(__ENV.PRODUCT_ID_MIN || 1);
const PRODUCT_ID_MAX = Number(__ENV.PRODUCT_ID_MAX || 20000);
const MEMBER_ID_MIN = Number(__ENV.MEMBER_ID_MIN || 1);
const MEMBER_ID_MAX = Number(__ENV.MEMBER_ID_MAX || 100);

// ===== Custom Metrics =====
const productListDuration = new Trend('product_list_duration', true);
const orderDetailDuration = new Trend('order_detail_duration', true);
const orderCreateDuration = new Trend('order_create_duration', true);

const productListErrors = new Counter('product_list_errors');
const orderDetailErrors = new Counter('order_detail_errors');
const orderCreateErrors = new Counter('order_create_errors');

// ===== Scenarios & Options =====
export let options = {
  scenarios: {
    // Warm-up (JVM, pool ready)
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

    // Read: product list
    product_list: {
      executor: 'constant-arrival-rate',
      rate: RATE_PRODUCTS,
      timeUnit: '1s',
      duration: TEST_DURATION,
      preAllocatedVUs: Math.ceil(RATE_PRODUCTS * 0.5),
      maxVUs: Math.ceil(RATE_PRODUCTS * 1.5),
      exec: 'productListScenario',
      startTime: WARMUP_DURATION,
      tags: { scenario: 'product_list' },
    },

    // Read: order detail
    order_detail: {
      executor: 'constant-arrival-rate',
      rate: RATE_ORDER_DETAIL,
      timeUnit: '1s',
      duration: TEST_DURATION,
      preAllocatedVUs: Math.ceil(RATE_ORDER_DETAIL * 0.5),
      maxVUs: Math.ceil(RATE_ORDER_DETAIL * 1.5),
      exec: 'orderDetailScenario',
      startTime: WARMUP_DURATION,
      tags: { scenario: 'order_detail' },
    },

    // Write: order create
    order_create: {
      executor: 'constant-arrival-rate',
      rate: RATE_ORDER_CREATE,
      timeUnit: '1s',
      duration: TEST_DURATION,
      preAllocatedVUs: Math.ceil(RATE_ORDER_CREATE * 0.5),
      maxVUs: Math.ceil(RATE_ORDER_CREATE * 1.5),
      exec: 'orderCreateScenario',
      startTime: WARMUP_DURATION,
      tags: { scenario: 'order_create' },
    },
  },

  // Thresholds are conditionally disabled for data-first runs
  thresholds: DISABLE_THRESHOLDS
      ? {}
      : {
        http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: false }],
        http_req_duration: [
          { threshold: 'p(95)<1000', abortOnFail: false },
          { threshold: 'p(99)<2000', abortOnFail: false },
        ],
        product_list_duration: [
          { threshold: 'p(50)<100', abortOnFail: false },
          { threshold: 'p(95)<300', abortOnFail: false },
          { threshold: 'p(99)<500', abortOnFail: false },
        ],
        order_detail_duration: [
          { threshold: 'p(50)<150', abortOnFail: false },
          { threshold: 'p(95)<400', abortOnFail: false },
          { threshold: 'p(99)<600', abortOnFail: false },
        ],
        order_create_duration: [
          { threshold: 'p(50)<200', abortOnFail: false },
          { threshold: 'p(95)<500', abortOnFail: false },
          { threshold: 'p(99)<1000', abortOnFail: false },
        ],
        product_list_errors: [{ threshold: 'count<10', abortOnFail: false }],
        order_detail_errors: [{ threshold: 'count<10', abortOnFail: false }],
        order_create_errors: [{ threshold: 'count<10', abortOnFail: false }],
      },

  // Network/client
  noConnectionReuse: false, // keep-alive
  userAgent: `K6-PoolTest-${POOL_SIZE}`,

  // Trend stats exported in summary
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(50)', 'p(90)', 'p(95)', 'p(99)'],
};

// ===== Utils =====
function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function handleResponse(response, metricTrend, errorCounter, apiName) {
  // record latency
  metricTrend.add(response.timings.duration);

  // success check
  const success = check(response, {
    [`${apiName} status OK`]: (r) => r.status >= 200 && r.status < 300,
  });

  if (!success) {
    errorCounter.add(1);
    if (VERBOSE_ERRORS) {
      console.error(`${apiName} failed: Status ${response.status}`);
    }
  }

  // Optional: read server-provided pool header
  if (response.headers['X-DB-Pool-Active']) {
    if (VERBOSE_ERRORS) {
      console.log(`Pool Active: ${response.headers['X-DB-Pool-Active']}`);
    }
  }

  return success;
}

// ===== Scenarios =====
export function warmupScenario() {
  http.get(`${BASE_URL}/api/v1/products?page=0&size=1`);
  sleep(1);
}

export function productListScenario() {
  const page = randomInt(0, 10);
  const size = randomInt(10, 50);

  const res = http.get(`${BASE_URL}/api/v1/products?page=${page}&size=${size}`,
      { tags: { api: 'product_list', pool_size: POOL_SIZE }, timeout: '10s' },
  );

  handleResponse(res, productListDuration, productListErrors, 'ProductList');
  sleep(Math.random() * 0.1);
}

export function orderDetailScenario() {
  const orderId = randomInt(ORDER_ID_MIN, ORDER_ID_MAX);

  const res = http.get(`${BASE_URL}/api/v1/orders/${orderId}`,
      { tags: { api: 'order_detail', pool_size: POOL_SIZE }, timeout: '10s' },
  );

  // 404 is acceptable if the order id doesn't exist
  const ok = check(res, {
    'OrderDetail status OK': (r) => r.status === 200 || r.status === 404,
  });

  orderDetailDuration.add(res.timings.duration);
  if (!ok) {
    orderDetailErrors.add(1);
    if (VERBOSE_ERRORS) {
      console.error(`OrderDetail failed: Status ${res.status}`);
    }
  }

  sleep(Math.random() * 0.1);
}

export function orderCreateScenario() {
  const memberId = randomInt(MEMBER_ID_MIN, MEMBER_ID_MAX);
  const itemCount = randomInt(1, 3);
  const items = [];
  const used = new Set();

  for (let i = 0; i < itemCount; i++) {
    let productId;
    do {
      productId = randomInt(PRODUCT_ID_MIN, PRODUCT_ID_MAX);
    } while (used.has(productId));
    used.add(productId);
    items.push({ productId, quantity: randomInt(1, 5) });
  }

  const payload = JSON.stringify({ memberId, items });

  const res = http.post(`${BASE_URL}/api/v1/orders`, payload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { api: 'order_create', pool_size: POOL_SIZE },
    timeout: '15s',
  });

  handleResponse(res, orderCreateDuration, orderCreateErrors, 'OrderCreate');
  sleep(Math.random() * 0.2);
}

// ===== Summary Writer =====
export function handleSummary(data) {
  const poolSize = __ENV.POOL_SIZE || 'unknown';

  const get = (o, path, def = 0) => {
    try {
      const v = path.split('.').reduce((a, k) => a[k], o);
      return v ?? def;
    } catch {
      return def;
    }
  };

  const summary = {
    testInfo: {
      poolSize,
      baseUrl: BASE_URL,
      duration: TEST_DURATION,
      timestamp: new Date().toISOString(),
      thresholdsEnabled: !DISABLE_THRESHOLDS,
    },
    overall: {
      totalRequests: get(data, 'metrics.http_reqs.values.count'),
      requestsPerSecond: get(data, 'metrics.http_reqs.values.rate'),
      failureRate: get(data, 'metrics.http_req_failed.values.rate') * 100,
      responseTime: {
        avg: get(data, 'metrics.http_req_duration.values.avg'),
        min: get(data, 'metrics.http_req_duration.values.min'),
        med: get(data, 'metrics.http_req_duration.values.med'),
        max: get(data, 'metrics.http_req_duration.values.max'),
        p95: get(data, 'metrics.http_req_duration.values.p(95)'),
        p99: get(data, 'metrics.http_req_duration.values.p(99)'),
      },
    },
    apis: {
      productList: {
        count: get(data, 'metrics.product_list_duration.values.count'),
        errors: get(data, 'metrics.product_list_errors.values.count'),
        responseTime: {
          avg: get(data, 'metrics.product_list_duration.values.avg'),
          p50: get(data, 'metrics.product_list_duration.values.p(50)'),
          p95: get(data, 'metrics.product_list_duration.values.p(95)'),
          p99: get(data, 'metrics.product_list_duration.values.p(99)'),
        },
      },
      orderDetail: {
        count: get(data, 'metrics.order_detail_duration.values.count'),
        errors: get(data, 'metrics.order_detail_errors.values.count'),
        responseTime: {
          avg: get(data, 'metrics.order_detail_duration.values.avg'),
          p50: get(data, 'metrics.order_detail_duration.values.p(50)'),
          p95: get(data, 'metrics.order_detail_duration.values.p(95)'),
          p99: get(data, 'metrics.order_detail_duration.values.p(99)'),
        },
      },
      orderCreate: {
        count: get(data, 'metrics.order_create_duration.values.count'),
        errors: get(data, 'metrics.order_create_errors.values.count'),
        responseTime: {
          avg: get(data, 'metrics.order_create_duration.values.avg'),
          p50: get(data, 'metrics.order_create_duration.values.p(50)'),
          p95: get(data, 'metrics.order_create_duration.values.p(95)'),
          p99: get(data, 'metrics.order_create_duration.values.p(99)'),
        },
      },
    },
    thresholds: data.thresholds,
  };

  const md = [
    `# Pool Size ${poolSize} – Benchmark Summary\n\n**Base URL:** ${BASE_URL}  `,
    `**Duration:** ${TEST_DURATION}  `,
    `**Timestamp:** ${summary.testInfo.timestamp}\n\n`,
    `## Overall\n`,
    `- Total Requests: ${summary.overall.totalRequests}\n`,
    `- RPS: ${summary.overall.requestsPerSecond.toFixed(2)}\n`,
    `- Failure Rate: ${summary.overall.failureRate.toFixed(2)}%\n`,
    `- P95: ${summary.overall.responseTime.p95.toFixed(2)} ms\n`,
    `- P99: ${summary.overall.responseTime.p99.toFixed(2)} ms\n\n`,
    `## API Latency (ms)\n`,
    `| API | p50 | p95 | p99 | Errors |\n`,
    `|---|---:|---:|---:|---:|\n`,
    `| Product List | ${summary.apis.productList.responseTime.p50.toFixed(2)} | ${summary.apis.productList.responseTime.p95.toFixed(2)} | ${summary.apis.productList.responseTime.p99.toFixed(2)} | ${summary.apis.productList.errors} |\n`,
    `| Order Detail | ${summary.apis.orderDetail.responseTime.p50.toFixed(2)} | ${summary.apis.orderDetail.responseTime.p95.toFixed(2)} | ${summary.apis.orderDetail.responseTime.p99.toFixed(2)} | ${summary.apis.orderDetail.errors} |\n`,
    `| Order Create | ${summary.apis.orderCreate.responseTime.p50.toFixed(2)} | ${summary.apis.orderCreate.responseTime.p95.toFixed(2)} | ${summary.apis.orderCreate.responseTime.p99.toFixed(2)} | ${summary.apis.orderCreate.errors} |\n`,
  ].join('');

  const csv = [
    'api,p50_ms,p95_ms,p99_ms,errors',
    `product_list,${summary.apis.productList.responseTime.p50},${summary.apis.productList.responseTime.p95},${summary.apis.productList.responseTime.p99},${summary.apis.productList.errors}`,
    `order_detail,${summary.apis.orderDetail.responseTime.p50},${summary.apis.orderDetail.responseTime.p95},${summary.apis.orderDetail.responseTime.p99},${summary.apis.orderDetail.errors}`,
    `order_create,${summary.apis.orderCreate.responseTime.p50},${summary.apis.orderCreate.responseTime.p95},${summary.apis.orderCreate.responseTime.p99},${summary.apis.orderCreate.errors}`,
  ].join('\n');

  return {
    [`/outputs/pool-${poolSize}.json`]: JSON.stringify(summary, null, 2),
    [`/outputs/pool-${poolSize}.md`]: md,
    [`/outputs/pool-${poolSize}.csv`]: csv,
  };
}
