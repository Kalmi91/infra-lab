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

## More docs

- [`BUILD.md`](BUILD.md) — live status %, build queue, build contract (load this to resume).
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — why each choice was made (ADR-lite).
- [`docs/PORTFOLIO.md`](docs/PORTFOLIO.md) — CV bullets, interview talking points, demo script.

## Cost guard

This project **never touches real AWS** — every AWS call goes to LocalStack on
`localhost:4566`, so the bill is **$0** and no credit card is involved. If you
ever switch `terraform/provider.tf` to real AWS:

- Run `make down` (or `terraform destroy`) after **every** session — EKS/RDS/ALB
  bill by the hour.
- Set an **AWS Budgets** alarm at ~$1 before applying anything.
- Never commit real credentials; use `aws configure` / env vars.

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `Cannot connect to the Docker daemon` | `sudo systemctl start docker` (or `sudo service docker start`); ensure you are in the `docker` group (`newgrp docker`). |
| `terraform` cannot reach `:4566` | LocalStack not up — `localstack status`; start with `make localstack-up`. |
| Port `4566` already in use | A LocalStack is already running — `localstack stop` or reuse it. |
| `kind create cluster` fails on image pull | Network/Docker issue; retry, or `docker pull kindest/node` first. |
| `helm ... --wait` times out | Inspect pods: `kubectl get pods -n monitoring`; describe the pending one. |
| Grafana port-forward refused | Pods not ready yet — wait for `kubectl get pods -n monitoring` to be `Running`. |
| `command not found: terraform/kind/k6` | `~/.local/bin` not on PATH — see `scripts/bootstrap.sh` output. |
