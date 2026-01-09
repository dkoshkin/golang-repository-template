# Copyright 2025 Dimitri Koshkin. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: dev.run-on-kind
dev.run-on-kind: export KUBECONFIG := $(KIND_KUBECONFIG)
dev.run-on-kind: kind.create
ifndef SKIP_BUILD
dev.run-on-kind: release-snapshot
endif
dev.run-on-kind: SNAPSHOT_VERSION = $(shell gojq -r '.version+"-"+.runtime.goarch' dist/metadata.json)
dev.run-on-kind:
	kind load docker-image --name $(KIND_CLUSTER_NAME) \
		ko.local/golang-repository-template:$(SNAPSHOT_VERSION)
	helm upgrade --install golang-repository-template ./charts/golang-repository-template \
		--set-string manager.image.repository=ko.local/golang-repository-template \
		--set-string manager.image.tag=$(SNAPSHOT_VERSION) \
		--wait --wait-for-jobs
	kubectl rollout restart deployment golang-repository-template-controller-manager
	kubectl rollout status deployment golang-repository-template-controller-manager

.PHONY: dev.image-on-kind
dev.image-on-kind: export KUBECONFIG := $(KIND_KUBECONFIG)
ifndef SKIP_BUILD
dev.image-on-kind: release-snapshot
endif
dev.image-on-kind: SNAPSHOT_VERSION = $(shell gojq -r '.version+"-"+.runtime.goarch' dist/metadata.json)
dev.image-on-kind:
	kind load docker-image --name $(KIND_CLUSTER_NAME) \
	  ko.local/golang-repository-template:$(SNAPSHOT_VERSION)
	kubectl set image deployment \
	  golang-repository-template manager=ko.local/golang-repository-template:$(SNAPSHOT_VERSION)
	kubectl rollout restart deployment golang-repository-template-controller-manager
	kubectl rollout status deployment golang-repository-template-controller-manager

.PHONY: release-please
release-please:
# filter Returns all whitespace-separated words in text that do match any of the pattern words.
ifeq ($(filter main release/v%,$(GIT_CURRENT_BRANCH)),)
	$(error "release-please should only be run on the main or release branch")
else
	release-please release-pr --repo-url $(GITHUB_ORG)/$(GITHUB_REPOSITORY) --target-branch $(GIT_CURRENT_BRANCH) --token "$$(gh auth token)"
endif
