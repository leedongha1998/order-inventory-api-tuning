import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.4/index.js';

const MODE = __ENV.TEST_TYPE || 'optimistic'; // 'pessimistic' 도 사용
const BASE = __ENV.BASE_URL || 'http://app:8080';
const PATH = __ENV.TARGET_PATH || '/api/v1/orders/optimistic';
export const options = {
  vus: Number(__ENV.VUS || 20),
  duration: __ENV.DURATION || '60s',
  thresholds: {
    // 시스템 실패(네트워크+5xx) < 1% 유지. 4xx는 비즈니스 실패로 별도 집계.
    'http_req_failed': ['rate<0.01'],
    // 지연 임곗값은 참조용
    'http_req_duration': ['p(95)<300'],
  },
  tags: { testType: MODE },
};

// 메트릭
const Latency = new Trend('latency_ms');
const Ok2xx = new Counter('resp_2xx');
const C409  = new Counter('resp_409');
const C4xx  = new Counter('resp_4xx_other');
const C5xx  = new Counter('resp_5xx');

const payload = JSON.stringify({
  memberId: 1,
  items: [{ productId: 1, quantity: 1 }],
});
const params = { headers: { 'Content-Type': 'application/json' }, timeout: '120s', tags: { endpoint: PATH, testType: MODE } };

export default function () {
  const r = http.post(`${BASE}${PATH}`, payload, params);

  // 상태 분기 집계
  if (r.status >= 200 && r.status < 300) Ok2xx.add(1);
  else if (r.status === 409) C409.add(1);
  else if (r.status >= 400 && r.status < 500) C4xx.add(1);
  else if (r.status >= 500) C5xx.add(1);

  // 체크: 모드별 허용 범위
  const isCreateOK = MODE === 'optimistic'
      ? (r.status === 200 || r.status === 201 || r.status === 409) // 충돌을 “예상 가능한 결과”로 허용
      : (r.status === 200 || r.status === 201);                     // 비관적락은 충돌을 억제해야 함

  check(r, { 'response acceptable': () => isCreateOK });

  Latency.add(r.timings.duration);
  sleep(Number(__ENV.SLEEP || 0));
}

export function handleSummary(data) {
  return {
    '/outputs/summary.txt': textSummary(data, { indent: ' ', enableColors: false }),
  };
}
