# Copyright 2025 Dimitri Koshkin. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

IMG ?= controller:latest

.PHONY: controller-gen
controller-gen: ; $(info $(M) using controller-gen from PATH)
	command -v controller-gen >/dev/null

.PHONY: kustomize
kustomize: ; $(info $(M) using kustomize from PATH)
	command -v kustomize >/dev/null

.PHONY: manifests
manifests: controller-gen ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
manifests: ; $(info $(M) generating CRDs and RBAC manifests)
	controller-gen paths="./..." \
		rbac:headerFile="hack/license/yaml.txt",roleName=manager-role
	controller-gen paths="./..." \
		crd:headerFile="hack/license/yaml.txt" \
		output:crd:artifacts:config=config/crd/bases
	controller-gen paths="./..." \
		webhook:headerFile="hack/license/yaml.txt"

.PHONY: generate
generate: controller-gen ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
generate: ; $(info $(M) generating deepcopy code)
	controller-gen object:headerFile="hack/license/go.txt" paths="./..."

.PHONY: build-installer
build-installer: manifests generate kustomize ## Generate a consolidated YAML with CRDs and deployment.
build-installer: ; $(info $(M) building installer manifest)
	mkdir -p dist
	cd config/manager && kustomize edit set image controller=${IMG}
	kustomize build config/default > dist/install.yaml

.PHONY: kubebuilder.sync-chart
kubebuilder.sync-chart: ## Regenerate kubebuilder helm chart and sync to charts/golang-repository-template
kubebuilder.sync-chart: ; $(info $(M) syncing kubebuilder helm chart)
	rm -rf dist/chart/templates
	kubebuilder edit --plugins=helm/v2-alpha
	# This workflow is added by the plugin, just remove it.
	rm -rf .github/workflows/test-chart.yml
	for file in $$(find dist/chart/templates -type f \( -name '*.yaml' -o -name '*.yml' \)); do \
	  { \
	    cat hack/license/yaml.txt; \
	    echo; \
	    cat "$$file"; \
	  } > "$$file.tmp"; \
	  mv "$$file.tmp" "$$file"; \
	done
	rm -rf charts/golang-repository-template/templates
	cp -R dist/chart/templates charts/golang-repository-template/templates
	# Format the values.yaml file.
	cp dist/chart/values.yaml dist/chart/values.yaml.formatted
	yamlfmt dist/chart/values.yaml.formatted
	# Remove the last line to avoid double newline when copying.
	sed -i '$$d' dist/chart/values.yaml.formatted
	{ \
	  cat hack/license/yaml.txt; \
	  echo; \
	  cat dist/chart/values.yaml.formatted; \
	} > charts/golang-repository-template/values.yaml
	rm -f dist/chart/values.yaml.formatted
	$(MAKE) chart-docs schema-chart
