#! /usr/bin/make -f

SHELL := /bin/bash

# current workspace
WORKSPACE := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
CURRENTDIR := $(notdir $(shell pwd))

# kind and k8s settings
KIND_CMD ?= kind
KIND_CLUSTER_NAME ?= nexeed
KIND_K8S_VERSION ?= 1.27.0
KIND_NODE_IMAGE_NAME = kindest/node:v$(KIND_K8S_VERSION)
KUBECONFIG = ~/.kube/config
HELM_CONFIG_DIR = helm

# different settings
DOCKER_CMD ?= docker
KUBECTL_CMD ?= kubectl
HELM_CMD ?= helm

# cmd configs
KUBECTL_CMD_CONFIG = $(KUBECTL_CMD) --kubeconfig $(KUBECONFIG)
KIND_CMD_CONFIG = $(KIND_CMD) --kubeconfig $(KUBECONFIG)
HELM_CMD_CONFIG = $(HELM_CMD) --kubeconfig $(KUBECONFIG)

# Define loadbalancer IP based on kind docker network https://kind.sigs.k8s.io/docs/user/loadbalancer/
KIND_NET_CIDR ?= $(shell docker network inspect -f '{{(index .IPAM.Config 0).Subnet}}' kind)
METALLB_IP_RANGE_START ?= 255.200
METALLB_IP_RANGE_END ?= 255.210
_METALLB_IP_RANGE_START = $(shell echo $(KIND_NET_CIDR) | sed "s@0.0/16@$(METALLB_IP_RANGE_START)@")
_METALLB_IP_RANGE_END = $(shell echo $(KIND_NET_CIDR) | sed "s@0.0/16@$(METALLB_IP_RANGE_END)@")

# Metallb configuration
METALLB_HELM_REPO_URL ?= https://metallb.github.io/metallb
METALLB_HELM_REPO_NAME ?= metallb
METALLB_HELM_CHART_VERSION ?= 0.13.10
METALLB_HELM_CHART_NAME ?= metallb
METALLB_HELM_RELEASE_NAME ?= metallb
METALLB_NAMESPACE_NAME ?= metallb-system

# ingress-nginx
INGRESS_NGINX_DEPLOY_VERSION ?= v1.2.0
INGRESS_NGINX_DEPLOY_PATH = https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-$(INGRESS_NGINX_DEPLOY_VERSION)/deploy/static/provider/cloud/deploy.yaml

# cert-manager
CERT_MANAGER_HELM_REPO_URL = https://charts.jetstack.io
CERT_MANAGER_HELM_REPO_NAME = jetstack
CERT_MANAGER_HELM_CHART_NAME = cert-manager
CERT_MANAGER_RELEASE_VERSION ?= v1.11.0
CERT_MANAGER_RELEASE_NAME = cert-manager
CERT_MANAGER_NAMESPACE_NAME = cert-manager

# here we go
default: help

.PHONY: help # Generate list of targets with descriptions
help:
	@echo "Basic usage:"
	@echo ""
	@echo "make <target> <option>"
	@echo ""
	@echo "Targets:"
	@grep '^.PHONY: .* #' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1	\2/' | expand -t30

.PHONY: prepare-cluster # create-kind deploy-metallb configure-metallb deploy-ingress-nginx deploy-cert-manager
prepare-cluster: deploy-metallb configure-metallb deploy-ingress-nginx deploy-cert-manager configure-cert-manager

.PHONY: create-kind # Create kind cluster
create-kind:
	@echo $$(date --iso=seconds) "Creating kind cluster"
	$(KIND_CMD_CONFIG) create cluster \
        --config ./k8s/kind-config.yaml \
		--name $(KIND_CLUSTER_NAME) \
		--image $(KIND_NODE_IMAGE_NAME)

.PHONY: delete-kind # Delete kind cluster
delete-kind:
	@echo $$(date --iso=seconds) "Deleting kind cluster"
	$(KIND_CMD_CONFIG) delete cluster \
		--name $(KIND_CLUSTER_NAME)

.PHONY: deploy-metallb # Deploy Metallb external type Loadbalancer
deploy-metallb:
	@echo $$(date --iso=seconds) "Deploying Metallb external type Loadbalancer on kind cluster"
	$(HELM_CMD_CONFIG) repo add $(METALLB_HELM_REPO_NAME) $(METALLB_HELM_REPO_URL)
	$(HELM_CMD_CONFIG) repo update
	$(HELM_CMD_CONFIG) upgrade --install $(METALLB_HELM_RELEASE_NAME) $(METALLB_HELM_REPO_NAME)/$(METALLB_HELM_CHART_NAME) \
		--create-namespace \
		--namespace $(METALLB_NAMESPACE_NAME) \
		--wait \
		--timeout=5m

.PHONY: configure-metallb # Configure Metallb
configure-metallb:
	@echo $$(date --iso=seconds) "Configuring Metallb"
	@echo $$(date --iso=seconds) "Using Loadbalancer IP range:" $(_METALLB_IP_RANGE_START)-$(_METALLB_IP_RANGE_END)
	$(HELM_CMD_CONFIG) upgrade --install metallb-config $(HELM_CONFIG_DIR)/metallb-config \
		--create-namespace \
		--set IPAddressPool.Range=$(_METALLB_IP_RANGE_START)-$(_METALLB_IP_RANGE_END) \
		--namespace $(METALLB_NAMESPACE_NAME)

.PHONY: deploy-ingress-nginx # Deploy Ingress Nginx
deploy-ingress-nginx:
	@echo $$(date --iso=seconds) "Deploying Ingress Nginx"
	$(KUBECTL_CMD_CONFIG) apply -f $(INGRESS_NGINX_DEPLOY_PATH)
	$(KUBECTL_CMD_CONFIG) rollout status deployment.apps/ingress-nginx-controller -n ingress-nginx --timeout=3m
	$(KUBECTL_CMD_CONFIG) get service ingress-nginx-controller --namespace=ingress-nginx

.PHONY: deploy-cert-manager # Deploy Cert-Manager
deploy-cert-manager:
	@echo $$(date --iso=seconds) "Deploying cert-manager"
	$(HELM_CMD_CONFIG) repo add $(CERT_MANAGER_HELM_REPO_NAME) $(CERT_MANAGER_HELM_REPO_URL)
	$(HELM_CMD_CONFIG) repo update
	$(HELM_CMD_CONFIG) upgrade --install $(CERT_MANAGER_RELEASE_NAME) $(CERT_MANAGER_HELM_REPO_NAME)/$(CERT_MANAGER_HELM_CHART_NAME) \
		--create-namespace \
		--set installCRDs=true \
		--namespace $(CERT_MANAGER_NAMESPACE_NAME) \
		--wait \
		--timeout=5m

.PHONY: configure-cert-manager # Configure Cert Manager
configure-cert-manager:
	@echo $$(date --iso=seconds) "Configuring Cert Manager"
	$(HELM_CMD_CONFIG) upgrade --install cert-manager-config $(HELM_CONFIG_DIR)/cert-manager-config \
		-n $(CERT_MANAGER_NAMESPACE_NAME)
