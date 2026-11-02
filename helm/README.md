# helm/

Helm values for the in-cluster stack.

| File | Chart | What it does |
| ---- | ----- | ------------ |
| `monitoring-values.yaml` | `prometheus-community/kube-prometheus-stack` | Prometheus + Grafana, tuned for kind ($0, emptyDir, Alertmanager off) |

## Install

```bash
make helm-monitoring     # adds the repo + helm upgrade --install
make dashboard           # port-forward Grafana -> http://localhost:3000
```

Grafana login: **admin / prom-operator**.

The Grafana Service is named `grafana` (via `fullnameOverride`) so the
port-forward target is stable regardless of the Helm release name.

> Postgres and the demo app (with its ServiceMonitor) are separate charts:
> `helm/postgres` and `helm/demo-app`.
> `serviceMonitorSelectorNilUsesHelmValues: false` lets Prometheus discover
> ServiceMonitors created outside this release.
