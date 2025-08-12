# Copyright 2025 Dimitri Koshkin. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

.PHONY: preview-docs
preview-docs: ## Runs hugo server to locally preview docs
preview-docs: ; $(info $(M) running hugo server to locally preview docs)
	cd docs && hugo server --buildFuture --buildDrafts

.PHONY: build-docs
build-docs: ## Builds the docs
build-docs: ; $(info $(M) building docs with hugo)
ifndef BASE_URL
	$(error BASE_URL is not set)
endif
	cd docs && hugo --minify --baseURL "$(BASE_URL)"
