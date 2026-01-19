# Copyright 2026 Dimitri Koshkin. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Sign git tags with GPG by default.
SIGN_COMMITS ?= true

GIT_TAG_FLAGS := -a
ifeq ($(SIGN_COMMITS),true)
GIT_TAG_FLAGS += -s
endif

.PHONY: tag
tag:
ifndef NEW_GIT_TAG
	$(error Please specify git tag to create via NEW_GIT_TAG env var or make variable)
endif
	$(foreach module,\
		$(dir $(GO_SUBMODULES_NO_DOCS)),\
		git tag $(GIT_TAG_FLAGS) "$(module)$(NEW_GIT_TAG)" -m "$(module)$(NEW_GIT_TAG)";\
	)
	git tag $(GIT_TAG_FLAGS) "$(NEW_GIT_TAG)" -m "$(NEW_GIT_TAG)"

.PHONY: tag-modules
tag-modules:
ifndef NEW_GIT_TAG
	$(error Please specify git tag to create via NEW_GIT_TAG env var or make variable)
endif
	$(foreach module,\
		$(dir $(GO_SUBMODULES_NO_DOCS)),\
		git tag $(GIT_TAG_FLAGS) "$(module)$(NEW_GIT_TAG)" -m "$(module)$(NEW_GIT_TAG)";\
	)
