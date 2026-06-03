# Decisions (ADR-lite)

Short architecture decision records. Each: context → decision → consequence →
trade-off.

## ADR-001 — LocalStack instead of real AWS
- **Context:** Portfolio/learning project with a hard $0 budget and zero
  credit-card risk.
- **Decision:** Run AWS APIs against LocalStack (Community) on `localhost:4566`;
  Terraform's AWS provider points there via the `endpoints` block + dummy creds.
- **Consequence:** Every Terraform/AWS skill is exercised for real, billed
  nothing. Code is provider-portable: deleting the endpoints + skip_* flags
  targets real AWS unchanged.
- **Trade-off:** Less "real" than a live AWS account; recruiters value real
  cloud. Mitigated by an honest README and the option of one real free-tier
  deploy later for screenshots.

## ADR-002 — kind instead of EKS
- **Context:** Need a Kubernetes cluster; LocalStack Community does **not**
  include EKS (Pro-only).
- **Decision:** Use kind (Kubernetes-in-Docker) as the cluster.
- **Consequence:** Real Kubernetes + real Helm authoring, $0. Everything that
  runs on the cluster (Prometheus, Grafana, Postgres, demo-app) is genuine.
- **Trade-off:** Not EKS-specific (no IRSA, no managed node groups). The k8s
  workload skills transfer; the EKS control-plane specifics do not.

## ADR-003 — Postgres in-cluster instead of RDS
- **Context:** Need a database; LocalStack Community has no RDS (Pro-only).
- **Decision:** Deploy a Postgres Helm chart into the kind cluster.
- **Consequence:** Demonstrates stateful workloads + DB connectivity from the
  app, $0.
- **Trade-off:** No managed-DB features (backups, failover). Acceptable for a
  demo; noted as such.

## ADR-004 — Ephemeral storage (emptyDir, no PVCs)
- **Context:** kind has no real storage backend; PVCs add friction and the demo
  is short-lived.
- **Decision:** Prometheus uses emptyDir; Grafana/Postgres persistence disabled.
- **Consequence:** No storage class needed, instant teardown, truly $0.
- **Trade-off:** Metrics/data are lost on restart. Fine for a demo; in prod
  you'd attach PVCs / managed storage.

## ADR-005 — Alertmanager disabled
- **Context:** kube-prometheus-stack ships Alertmanager; the portfolio demo
  shows dashboards, not paging.
- **Decision:** `alertmanager.enabled: false`.
- **Consequence:** Smaller footprint on a laptop-sized cluster.
- **Trade-off:** No alerting demo. Can be re-enabled in one line if needed.

## ADR-006 — Control-plane scrape targets disabled in kind
- **Context:** kind does not expose kube-controller-manager/scheduler/etcd/proxy
  on the host network, so those Prometheus targets are permanently "down".
- **Decision:** Disable those ServiceMonitors in values.
- **Consequence:** Prometheus targets stay green — a clean demo.
- **Trade-off:** Less control-plane visibility; irrelevant on kind anyway.

## ADR-009 — Local Postgres Helm chart over the Bitnami chart
- **Context:** Need a Postgres (RDS substitute). The plan suggested
  `bitnami/postgresql`.
- **Decision:** Author a minimal local Helm chart (`helm/postgres/`) using the
  official `postgres:16-alpine` Docker Hub image.
- **Consequence:** No dependency on the Bitnami chart/registry (which changed
  distribution + added auth/legacy repos in 2025), full control of the manifests,
  and it demonstrates **Helm chart authoring** (an explicit learning goal).
- **Trade-off:** Fewer features than the Bitnami chart (no HA, backups, metrics
  exporter). Not needed for a $0 ephemeral demo; would revisit for production.

## ADR-008 — GitHub Actions for CI
- **Context:** Existing experience is Jenkins; the gap analysis flagged
  GitHub Actions as a missing skill.
- **Decision:** CI runs on GitHub Actions (terraform fmt/validate now; tflint,
  helm lint, k6, app build later).
- **Consequence:** Closes a named CV gap with a public, reviewable pipeline.
- **Trade-off:** None meaningful for this project.
