// k6 load test for the infra-lab demo-app.
//
//   # port-forward the app first (in another shell):
//   kubectl port-forward -n demo svc/demo-app 8080:8080
//   # then:
//   k6 run k6-tests/load.js                 # default TARGET=http://localhost:8080/
//   TARGET=http://localhost:8080/ k6 run k6-tests/load.js
//
// Writes summary.json next to where k6 runs (see handleSummary). To stream
// results into Grafana, run with the Prometheus remote-write output:
//   K6_PROMETHEUS_RW_SERVER_URL=http://localhost:9090/api/v1/write \
//     k6 run -o experimental-prometheus-rw k6-tests/load.js
import http from "k6/http";
import { check, sleep } from "k6";
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.2/index.js";

const TARGET = __ENV.TARGET || "http://localhost:8080/";

export const options = {
  scenarios: {
    ramping_load: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "30s", target: 20 }, // ramp up
        { duration: "1m", target: 20 },  // steady
        { duration: "10s", target: 0 },  // ramp down
      ],
      gracefulStop: "5s",
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests under 500ms
    http_req_failed: ["rate<0.01"],   // <1% errors
  },
};

export default function () {
  const res = http.get(TARGET);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(1);
}

export function handleSummary(data) {
  return {
    "summary.json": JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: " ", enableColors: true }) + "\n",
  };
}
