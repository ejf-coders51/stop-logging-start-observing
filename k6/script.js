// TO RUN docker run --rm -i grafana/k6 run --vus 10 --duration 30s  - <loadtesting.js
import http from "k6/http";
import { check, sleep } from "k6";
import { randomString } from "https://jslib.k6.io/k6-utils/1.2.0/index.js";

export const options = {
  discardResponseBodies: true,
  scenarios: {
    contacts: {
      executor: "constant-arrival-rate",
      duration: "5m",
      gracefulStop: "5s",
      rate: 5,
      timeUnit: "2s",
      preAllocatedVUs: 50,
      maxVUs: 10000,
    },
  },
};

export default function () {
  const url = `http://${__ENV.HOSTNAME || "order.localhost"}/api/orders`;

  const params = {
    headers: {
      "Content-Type": "application/json",
    },
  };

  const payload = JSON.stringify({
    payload: {
      orderNumber: "9" + randomString(32),
      items: "margherita",
      pickupAt: new Date().toISOString(),
      dropoffAt: new Date().toISOString(),
    },
  });

  const res = http.post(url, payload, params);

  check(res, { "status was 200": (r) => r.status == 200 });

  sleep(100);
}
