# Copyright 2025 Dimitri Koshkin. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

export CAPI_VERSION := v1.12.1
export CAPD_VERSION := $(CAPI_VERSION)
export CAAPH_VERSION := v0.5.3

.PHONY: clusterctl.init
clusterctl.init:
	env CLUSTER_TOPOLOGY=true \
	    EXP_RUNTIME_SDK=true \
	    EXP_MACHINE_POOL=true \
	    clusterctl init \
	      --kubeconfig=$(KIND_KUBECONFIG) \
	      --core cluster-api:$(CAPI_VERSION) \
	      --bootstrap kubeadm:$(CAPI_VERSION) \
	      --control-plane kubeadm:$(CAPI_VERSION) \
	      --infrastructure docker:$(CAPD_VERSION) \
	      --addon helm:$(CAAPH_VERSION) \
	      --wait-providers

.PHONY: clusterctl.delete
clusterctl.delete:
	clusterctl delete --kubeconfig=$(KIND_KUBECONFIG) --all
