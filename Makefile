.PHONY: help up down test dashboard localstack-up kind-up tf-apply tf-destroy

CLUSTER ?= infra-lab

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n",$$1,$$2}'

up: localstack-up kind-up tf-apply ## Start LocalStack + kind, apply Terraform
	@echo "Stack up. Next: make dashboard / make test"

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

test: ## Run the k6 load test
	k6 run k6-tests/load.js

dashboard: ## Port-forward Grafana to http://localhost:3000
	@echo "Grafana on http://localhost:3000 (admin / prom-operator). Ctrl-C to stop."
	kubectl port-forward -n monitoring svc/grafana 3000:80

down: ## Tear everything down — back to \$$0
	-cd terraform && terraform destroy -auto-approve
	-kind delete cluster --name $(CLUSTER)
	-localstack stop
	@echo "All down. Nothing left running."
