import http from 'k6/http';
import { Counter, Trend } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://spring-app:8080';
const TEST_DURATION = __ENV.TEST_DURATION || '3m';
const WARMUP_DURATION = __ENV.WARMUP_DURATION || '30s';
const RATE = Number(__ENV.RATE || 500);
const MEMBER_ID_MIN = Number(__ENV.MEMBER_ID_MIN || 1);
const MEMBER_ID_MAX = Number(__ENV.MEMBER_ID_MAX || 1000);
const CACHE_TTL_SECONDS = Number(__ENV.CACHE_TTL_SECONDS || 30);
const USE_CACHE = String(__ENV.USE_CACHE || 'true').toLowerCase() === 'true';

const summaryDuration = new Trend('order_summary_duration', true);
const cacheHitCount = new Counter('order_summary_cache_hit');
const cacheMissCount = new Counter('order_summary_cache_miss');

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function endpoint(memberId) {
  if (USE_CACHE) {
    return `${BASE_URL}/api/v1/experiments/orders/${memberId}/me/summary/cached?page=0&size=20&ttlSeconds=${CACHE_TTL_SECONDS}`;
  }
  return `${BASE_URL}/api/v1/experiments/orders/${memberId}/me/summary?page=0&size=20`;
}

export const options = {
  scenarios: {
    warmup: {
      executor: 'constant-arrival-rate',
      rate: 30,
      timeUnit: '1s',
      duration: WARMUP_DURATION,
      preAllocatedVUs: 20,
      maxVUs: 50,
      exec: 'runScenario',
    },
    main: {
      executor: 'constant-arrival-rate',
      startTime: WARMUP_DURATION,
      rate: RATE,
      timeUnit: '1s',
      duration: TEST_DURATION,
      preAllocatedVUs: Math.max(50, Math.ceil(RATE * 0.5)),
      maxVUs: Math.max(200, Math.ceil(RATE * 1.5)),
      exec: 'runScenario',
    },
  },
};

export function runScenario() {
  const memberId = randInt(MEMBER_ID_MIN, MEMBER_ID_MAX);
  const res = http.get(endpoint(memberId), { timeout: '10s' });
  summaryDuration.add(res.timings.duration);

  const cacheHitHeader = res.headers['X-Experiment-Cache-Hit'];
  if (cacheHitHeader === 'true') cacheHitCount.add(1);
  else if (USE_CACHE) cacheMissCount.add(1);
}
