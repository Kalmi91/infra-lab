// Minimal k6 load test. Point TARGET at the demo app once it is deployed
// (Week 5). Run: k6 run k6-tests/load.js
import http from "k6/http";
import { check, sleep } from "k6";

const TARGET = __ENV.TARGET || "http://localhost:8080/";

export const options = {
  stages: [
    { duration: "30s", target: 20 }, // ramp up
    { duration: "1m", target: 20 },  // steady
    { duration: "10s", target: 0 },  // ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% under 500ms
    http_req_failed: ["rate<0.01"],   // <1% errors
  },
};

export default function () {
  const res = http.get(TARGET);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(1);
}
