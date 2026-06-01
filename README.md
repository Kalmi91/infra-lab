# infra-lab

Portfolio project #1 of 3 for the CDMX DevOps job search. Goal: learn and
demonstrate **Terraform + AWS + Kubernetes + monitoring + load testing** by
building a complete, reproducible cloud-style environment.

> **$0 by design.** The whole stack runs locally — no AWS bill, no credit-card
> risk. AWS APIs are emulated with [LocalStack](https://localstack.cloud)
> (Community edition) and Kubernetes runs in [kind](https://kind.sigs.k8s.io)
> (Kubernetes-in-Docker). The Terraform and Helm skills transfer 1:1 to real
> AWS later.

## What this builds

| Layer | Real AWS would use | $0 local substitute | Skill demonstrated |
| ----- | ------------------ | ------------------- | ------------------ |
| Network / IAM / storage | VPC, IAM, S3 | LocalStack (Community) | Terraform + AWS provider |
| Kubernetes cluster | EKS | kind | k8s, Helm authoring |
| Database | RDS Postgres | Postgres Helm chart in kind | stateful workloads |
| Monitoring | Managed Grafana | Prometheus + Grafana (Helm) | observability stack |
| Load testing | — | k6 → Grafana dashboard | performance testing |
| CI | CodeBuild | GitHub Actions | pipeline authoring |

> LocalStack Community does **not** include EKS or RDS (Pro-only). That is why
> the cluster is `kind` and the database is an in-cluster Postgres chart. The
> README is explicit about this so it is honest on the CV.

## Architecture

```
                 ┌─────────────── kind cluster (Docker) ───────────────┐
                 │                                                      │
  Terraform ──►  │  Helm: Prometheus ──┐                               │
   │   │         │        Grafana   ◄──┘ (dashboards)                  │
   │   │         │        Postgres                                      │
   │   │         │        demo-app   ◄── k6 load test ──► metrics      │
   │   │         └──────────────────────────────────────────────────┘
   │   └──► LocalStack (Docker): VPC · IAM · S3
   └─────► everything is code, nothing is clicked
```

## Prerequisites (the host runs these — see `scripts/bootstrap.sh`)

The Docker daemon, kind, LocalStack, Terraform, kubectl and k6 must run on the
host shell (they need the Docker socket, which is not available inside the
Claude Code sandbox). Run the bootstrap once:

```bash
./scripts/bootstrap.sh        # installs tools to ~/.local/bin, starts Docker
```

## Usage

```bash
make up        # start LocalStack + kind, terraform apply, helm install
make test      # run k6 load test against the demo app
make dashboard # open Grafana (http://localhost:3000)
make down      # tear everything down — back to $0, nothing left running
```

## Repo layout

```
infra-lab/
├── terraform/          # LocalStack-targeted AWS resources (VPC, IAM, S3)
├── helm/               # Prometheus/Grafana/Postgres/demo-app values + charts
├── k6-tests/           # load test scripts
├── scripts/            # bootstrap.sh + helpers (run on host)
├── .github/workflows/  # terraform fmt/validate/tflint on PR
└── Makefile            # up / test / dashboard / down
```

## Learning roadmap (6 weeks)

- **Week 1–2** — Terraform basics: provider, VPC, IAM, S3 against LocalStack.
- **Week 3** — kind cluster + Helm: deploy Postgres + a demo app.
- **Week 4** — Prometheus + Grafana stack, wire app metrics, build a dashboard.
- **Week 5** — k6 load tests feeding results into Grafana.
- **Week 6** — GitHub Actions CI, polish README + architecture diagram.
