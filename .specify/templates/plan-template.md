<!--
 Copyright 2025 Dimitri Koshkin. All rights reserved.
 SPDX-License-Identifier: Apache-2.0
 -->

# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

**Language/Version**: Go 1.25+ (as per go.mod)
**Primary Dependencies**:
- controller-runtime v0.22.4
- Kubernetes client-go v0.35.0
- Kubebuilder v4.10.1
- Ginkgo/Gomega for testing

**Storage**: Kubernetes API server (etcd-backed)
**Testing**:
- Unit: Go testing, fake clients
- Integration: envtest (Kubebuilder test environment)
- E2E: Ginkgo/Gomega with kind clusters

**Target Platform**: Kubernetes 1.30+ clusters (Linux amd64/arm64 controller pods)
**Project Type**: Kubernetes controller/operator with Helm chart deployment
**Performance Goals**: [Feature-specific, e.g., reconcile 1000 resources/min, <5s reconciliation latency or NEEDS CLARIFICATION]
**Constraints**: [Feature-specific, e.g., <200MB memory per controller, no cluster-admin privileges required or NEEDS CLARIFICATION]
**Scale/Scope**: [Feature-specific, e.g., 10k CRD instances, multi-namespace, HA deployment or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with `.specify/memory/constitution.md` principles:

- [ ] **Kubernetes-Native Development**: (If controller) Does this feature follow controller patterns, use CRDs properly, and respect Kubernetes semantics?
- [ ] **Project Structure & Build Configuration**: Is project type (Controller/CLI/Both) clear? Are `cmd/` directories and `.goreleaser.yaml` configured correctly?
- [ ] **Reconciliation Correctness**: (If controller) Is reconciliation idempotent, safe under concurrency, and handling errors correctly?
- [ ] **API Design & Versioning**: (If controller) Do APIs follow versioning conventions? Are Spec/Status separated correctly?
- [ ] **Testing Strategy**: Are unit, integration (envtest for controllers), and E2E tests planned?
- [ ] **Observability & Debugging**: Are we using structured logging, emitting Events (for controllers), and exporting Prometheus metrics?
- [ ] **Backward Compatibility**: Are deprecations handled gracefully? Is there a migration path for breaking changes?
- [ ] **Dependency Management**: Are dependencies explicit, up-to-date, and security-scanned?
- [ ] **Code Quality**: Will code pass golangci-lint? Are godocs present? Is error handling robust?

**Violations** (if any): [List violations and justifications in Complexity Tracking section]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

<!--
  ACTION REQUIRED: Choose ONE of the three project types below based on requirements.
  Delete the other two options. The delivered plan MUST NOT include all three options.
-->

```text
# [CHOOSE ONE] Option 1: Controller-only (Kubebuilder)
api/
└── v1alpha1/              # CRD API definitions (versioned)
    ├── [resource]_types.go
    └── groupversion_info.go

internal/
└── controller/            # Controller reconciliation logic
    └── [resource]_controller.go

cmd/
├── main.go               # Kubebuilder stub (required, keep minimal)
└── <project-name>/       # Controller binary
    └── main.go

config/                   # Kubebuilder-generated Kubernetes manifests
├── crd/                 # CRD definitions
├── rbac/                # RBAC rules
├── manager/             # Controller deployment
└── webhook/             # Webhook configurations (if used)

charts/                  # Helm chart (synced from config/)
└── <project-name>/
    ├── templates/
    ├── values.yaml
    └── Chart.yaml

test/e2e/                # E2E tests (Ginkgo/Gomega)
PROJECT                  # Kubebuilder metadata
.goreleaser.yaml         # Build config for controller + images

# [CHOOSE ONE] Option 2: CLI-only
cmd/<cli-name>/          # CLI binary (cobra-based)
└── main.go

internal/                # Shared business logic
├── commands/            # CLI command implementations
└── client/              # API clients, utilities

pkg/                     # Public libraries (if any)

test/                    # Unit and integration tests
.goreleaser.yaml         # Build config for multi-platform CLI

# [CHOOSE ONE] Option 3: Both Controller and CLI
api/v1alpha1/            # CRD API definitions

internal/
├── controller/          # Controller reconciliation logic
├── client/              # Shared Kubernetes client
└── util/                # Shared utilities

cmd/
├── main.go              # Kubebuilder stub (required)
├── <project>-controller/ # Controller binary
│   └── main.go
└── <project>-cli/       # CLI binary (or just <project>/)
    └── main.go

config/                  # Kubebuilder manifests
charts/                  # Helm chart
test/e2e/                # E2E tests
PROJECT                  # Kubebuilder metadata
.goreleaser.yaml         # Build config for BOTH binaries
```

**Structure Decision**: [Document which option was selected and why]

- **Controller-only**: [Why no CLI is needed]
- **CLI-only**: [Why this is not a Kubernetes controller]
- **Both**: [Explain controller and CLI responsibilities, why both are needed]

**GoReleaser Configuration**: [Confirm .goreleaser.yaml has correct build IDs matching cmd/ directories]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
