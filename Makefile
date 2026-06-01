.PHONY: help up down test dashboard app-forward localstack-up kind-up tf-apply tf-destroy helm-monitoring helm-postgres app-deploy

CLUSTER ?= infra-lab
HELM_NS ?= monitoring
DATA_NS ?= data
APP_NS ?= demo
IMAGE ?= infra-lab-demo-app:dev

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'

up: localstack-up kind-up tf-apply helm-monitoring helm-postgres app-deploy ## Full stack: LocalStack + kind + Terraform + monitoring + postgres + app
	@echo "Stack up. Next: make dashboard / make test"

app-deploy: ## Build the Go demo-app image, load into kind, helm install
	docker build -t $(IMAGE) app
	kind load docker-image $(IMAGE) --name $(CLUSTER)
	helm upgrade --install demo-app helm/demo-app \
	  --namespace $(APP_NS) --create-namespace --wait --timeout 5m

helm-monitoring: ## Install kube-prometheus-stack (Prometheus + Grafana)
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update prometheus-community
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
	  --namespace $(HELM_NS) --create-namespace \
	  -f helm/monitoring-values.yaml --wait --timeout 10m

helm-postgres: ## Install ephemeral Postgres (RDS substitute, local chart)
	helm upgrade --install postgres helm/postgres \
	  --namespace $(DATA_NS) --create-namespace --wait --timeout 5m

localstack-up: ## Start LocalStack (Docker) on :4566
	localstack start -d
	localstack wait -t 60

kind-up: ## Create the kind Kubernetes cluster
	@kind get clusters | grep -qx $(CLUSTER) || kind create cluster --name $(CLUSTER)
	kubectl cluster-info --context kind-$(CLUSTER)

tf-apply: ## terraform init + apply against LocalStack
	cd terraform && terraform init -input=false && terraform apply -auto-approve

tf-destroy: ## terraform destroy
	cd terraform && terraform destroy -auto-approve

app-forward: ## Port-forward the demo-app to http://localhost:8080 (for k6)
	@echo "demo-app on http://localhost:8080 — leave running, run 'make test' in another shell."
	kubectl port-forward -n $(APP_NS) svc/demo-app 8080:8080

test: ## Run the k6 load test (needs 'make app-forward' running)
	k6 run k6-tests/load.js

dashboard: ## Port-forward Grafana to http://localhost:3000
	@echo "Grafana on http://localhost:3000 (admin / prom-operator). Ctrl-C to stop."
	kubectl port-forward -n monitoring svc/grafana 3000:80

down: ## Tear everything down — back to \$$0
	-cd terraform && terraform destroy -auto-approve
	-kind delete cluster --name $(CLUSTER)
	-localstack stop
	@echo "All down. Nothing left running."
