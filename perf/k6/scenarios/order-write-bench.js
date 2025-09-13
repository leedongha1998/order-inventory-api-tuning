// POST {BASE_URL}{PATH_PREFIX} with JSON body { memberId, price, createdAt }
// createdAt: ISO_LOCAL_DATE_TIME (yyyy-MM-dd'T'HH:mm:ss), random 2024-07-01 ~ 2025-08-01

import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomSeed } from 'k6';

// ---- env parsing ----
function intEnv(name, def) { const r = __ENV[name]; if (r == null) return def; const n = parseInt(String(r).trim(), 10); return Number.isFinite(n) ? n : def; }
function numEnv(name, def) { const r = __ENV[name]; if (r == null) return def; const n = Number(String(r).trim());        return Number.isFinite(n) ? n : def; }
function strEnv(name, def) { const r = __ENV[name]; if (r == null) return def; const s = String(r);                      return s.length ? s : def; }

// ---- config ----
const BASE_URL  = strEnv('BASE_URL',  'http://spring-app:8080');
const PATH_PREF = strEnv('PATH_PREFIX','/api/v1/orders/np');        // 예: /api/v1/orders/np 또는 /api/v1/orders/pt
const SEED      = numEnv('SEED', 1);

// body fields
const MEMBER_ID = intEnv('MEMBER_ID', 1);
const PRICE_VAL = intEnv('PRICE', 1);

// ---- load ----
export const options = {
  scenarios: {
    write_load: {
      executor: 'constant-arrival-rate',
      rate: numEnv('RATE', 200),
      timeUnit: '1s',
      duration: strEnv('DURATION', '10m'),
      preAllocatedVUs: intEnv('PRE_VUS', 100),
      maxVUs: intEnv('MAX_VUS', 1000),
    },
  },
};
randomSeed(SEED);

// ---- time utils ----
const START_TS = Date.parse('2024-08-01T00:00:00Z');
const END_TS   = Date.parse('2025-08-01T00:00:00Z');
const p2 = n => (n < 10 ? `0${n}` : `${n}`);
const ri = (a, b) => a + Math.floor(Math.random() * (b - a + 1));
function randomLocalDateTimeISO() {
  const ts = START_TS + Math.floor(Math.random() * (END_TS - START_TS));
  const d = new Date(ts); // UTC base
  const yyyy = d.getUTCFullYear();
  const mm   = p2(d.getUTCMonth() + 1);
  const dd   = p2(d.getUTCDate());
  const HH   = p2(ri(0, 23));
  const MM   = p2(ri(0, 59));
  const SS   = p2(ri(0, 59));
  return `${yyyy}-${mm}-${dd}T${HH}:${MM}:${SS}`; // ISO_LOCAL_DATE_TIME
}

// ---- test ----
export default function () {
  const url = `${BASE_URL}${PATH_PREF}`;
  const payload = JSON.stringify({
    memberId: MEMBER_ID,
    price: PRICE_VAL,
    createdAt: randomLocalDateTimeISO(),
  });

  const res = http.post(url, payload, {
    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
    tags: { endpoint: 'order-write' },
  });

  if (__ITER < 3) console.log(`URL=${url} status=${res.status} body=${(res.body || '').substring(0, 120)}`);
  check(res, { 'status 2xx/3xx': r => r.status >= 200 && r.status < 400 });
  sleep(0.01);
}
