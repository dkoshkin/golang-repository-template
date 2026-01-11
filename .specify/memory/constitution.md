<!--
 Copyright 2025 Dimitri Koshkin. All rights reserved.
 SPDX-License-Identifier: Apache-2.0
 -->

<!--
 SYNC IMPACT REPORT
 ==================
 Version Change: N/A → 1.0.0
 Rationale: Initial constitution for Kubernetes controller and CLI development in Go

 Modified Principles: N/A (initial version)
 Added Sections:
   - All core principles (I-IX)
     - I. Kubernetes-Native Development
     - II. Project Structure & Build Configuration (supports Controller/CLI/Both)
     - III. Reconciliation Correctness (NON-NEGOTIABLE)
     - IV. API Design & Versioning
     - V. Testing Strategy
     - VI. Observability & Debugging
     - VII. Backward Compatibility & Deprecation
     - VIII. Dependency Management & Security
     - IX. Code Quality & Maintainability
   - Code Quality Standards (error handling, logging, naming)
   - Kubernetes & Controller Standards (RBAC, Helm, configuration)
   - CI/CD & Release Standards (CI, releases, GoReleaser config, conventional commits, dependencies)
   - Governance (amendment process, versioning, compliance review)

 Removed Sections: N/A

 Templates Status:
   ✅ plan-template.md - Updated with:
     - Constitution Check referencing all 9 principles (with conditional checks for controllers)
     - Technical Context with Kubernetes-specific dependencies
     - Three project structure options (Controller/CLI/Both) with GoReleaser guidance
   ✅ spec-template.md - Requirements align with quality standards (no changes needed)
   ✅ tasks-template.md - Updated with:
     - Path conventions for all three project types
     - Conditional foundational tasks based on project type
     - GoReleaser build ID verification tasks
   ⚠ agent-file-template.md - Review recommended for multi-binary project guidance
   ⚠ checklist-template.md - Review recommended for project-type-specific compliance checks

 Follow-up TODOs:
   - Review agent-file-template.md for alignment with Controller/CLI/Both patterns
   - Review checklist-template.md for project-type-specific compliance checks
   - Consider creating example .goreleaser.yaml templates for each project type
-->

# Golang Repository Template Constitution

## Core Principles

### I. Kubernetes-Native Development

All controller development MUST follow Kubernetes controller patterns and conventions:

- Controllers MUST be built using controller-runtime and follow the operator pattern
- APIs MUST use Kubernetes CRD (CustomResourceDefinition) conventions with versioned API groups
- Reconciliation loops MUST be idempotent and handle partial failures gracefully
- Controllers MUST respect Kubernetes ownership, finalizers, and garbage collection semantics
- All Kubernetes resources MUST include proper RBAC (Role-Based Access Control) definitions
- Controller logic MUST never directly manipulate etcd; use the Kubernetes API client exclusively

**Rationale**: Kubernetes controllers have established patterns that ensure reliability, predictability, and seamless integration with the Kubernetes ecosystem. Deviating from these patterns creates operational complexity and breaks user expectations.

### II. Project Structure & Build Configuration

Projects can be one of three types: **Controller-only**, **CLI-only**, or **Both**. Structure MUST match the project type:

**Controller-only (Kubebuilder):**
- The PROJECT file and kubebuilder markers are the source of truth for API and controller scaffolding
- Generated manifests in `config/` MUST be kept in sync with Helm charts using `make kubebuilder.sync-chart`
- Controller boilerplate MUST be generated via `kubebuilder create api` and `kubebuilder create webhook`
- Controller binary in `cmd/golang-repository-template/` (or project-specific name)
- `.goreleaser.yaml` MUST build the controller binary and container images

**CLI-only:**
- CLI binary in `cmd/<cli-name>/`
- No `config/` directory or Kubebuilder scaffolding
- `.goreleaser.yaml` MUST build the CLI binary for multiple platforms (linux, darwin, windows)
- CLI MUST follow cobra patterns for subcommands and flags

**Both Controller and CLI:**
- Controller binary in `cmd/<project-name>-controller/`
- CLI binary in `cmd/<project-name>/` or `cmd/<project-name>-cli/`
- Both binaries MUST be listed in `.goreleaser.yaml` builds section with separate IDs
- Shared code MUST live in `internal/` or `pkg/` directories
- The `cmd/main.go` stub MUST remain minimal (Kubebuilder requirement)

**Rationale**: Clear separation between controller and CLI binaries prevents coupling and allows independent versioning. Kubebuilder provides battle-tested scaffolding for controllers, while CLI tools follow Go community conventions.

### III. Reconciliation Correctness (NON-NEGOTIABLE for Controllers)

**Note**: This principle applies ONLY to Controller-only and Both project types. CLI-only projects skip this principle.

Controller reconciliation logic MUST be correct, deterministic, and safe:

- Reconcile functions MUST be idempotent: applying the same desired state multiple times produces the same result
- Reconcile functions MUST handle concurrent reconciliations of the same resource safely (no race conditions)
- All error conditions MUST return `ctrl.Result{Requeue: true}` or use exponential backoff via `ctrl.Result{RequeueAfter: duration}`
- Finalizers MUST be added before creating external resources and removed only after cleanup completes
- Status conditions MUST reflect the actual observed state, never the desired state
- Reconciliation MUST NOT assume ordering of events or webhook invocations

**Rationale**: Incorrect reconciliation logic causes cascading failures, data loss, and unpredictable behavior in production clusters. Controllers are constantly retried by the Kubernetes control plane, so non-idempotent logic amplifies errors exponentially.

### IV. API Design & Versioning (for Controllers)

**Note**: This principle applies ONLY to Controller-only and Both project types. CLI-only projects skip this principle.

Kubernetes API design MUST follow established conventions:

- All APIs MUST use the standard `v1alpha1` → `v1beta1` → `v1` maturity progression
- API structs MUST include `metav1.TypeMeta` and `metav1.ObjectMeta` embedding
- Spec fields MUST represent desired state; Status fields MUST represent observed state
- Breaking changes to `v1` APIs are FORBIDDEN; use a new API version (e.g., `v2alpha1`)
- All API types MUST include JSON tags, kubebuilder validation markers, and OpenAPI schema markers
- Defaulting and validation logic MUST be implemented via webhooks, not in reconciliation

**Rationale**: Kubernetes APIs are contracts with users. Breaking these contracts causes production outages. The Kubernetes API versioning system provides a proven path for API evolution without breaking existing workloads.

### V. Testing Strategy

Testing MUST cover unit, integration, and end-to-end scenarios:

- **Unit tests**: Test individual reconciliation functions, predicates, and business logic in isolation using fake clients
- **Integration tests**: Test controller behavior against a real API server using `envtest` (Kubebuilder's test environment)
- **End-to-end tests**: Test complete workflows in a real Kubernetes cluster (using kind or similar)
- All new features MUST include tests before implementation (Test-Driven Development strongly encouraged)
- Test coverage MUST be tracked; new code MUST NOT decrease overall coverage percentage
- E2E tests MUST use Ginkgo/Gomega to match controller-runtime patterns

**Rationale**: Controllers run in production clusters managing critical workloads. Insufficient testing leads to bugs that are expensive to debug and dangerous to fix in production. Layered testing catches different classes of bugs.

### VI. Observability & Debugging

Controllers MUST be observable in production:

- All reconciliation loops MUST use structured logging via `logr` (from controller-runtime)
- Critical state transitions MUST emit Kubernetes Events on the reconciled resource
- Prometheus metrics MUST be exported for reconciliation duration, error rates, and queue depth
- Error messages in Status conditions MUST be actionable and include sufficient context for debugging
- Logs MUST NOT contain sensitive data (secrets, tokens, passwords)
- Use log levels appropriately: Info for normal operations, Error for failures, Debug/V(1) for detailed troubleshooting

**Rationale**: Controllers run asynchronously and handle transient failures. Without proper observability, debugging production issues becomes guesswork. Structured logs and metrics are essential for diagnosing controller behavior.

### VII. Backward Compatibility & Deprecation

Changes MUST NOT break existing users:

- Deprecated fields MUST remain functional for at least one minor version before removal
- Breaking changes MUST be accompanied by migration guides and automated migration tooling where possible
- Helm chart changes MUST maintain backward compatibility; use chart versioning (MAJOR.MINOR.PATCH)
- Configuration changes MUST support both old and new formats during a transition period
- Deprecation warnings MUST be surfaced via logs, Events, and Status conditions

**Rationale**: Users depend on stable APIs and configurations for production workloads. Unannounced breaking changes destroy trust and force emergency maintenance windows.

### VIII. Dependency Management & Security

Dependencies MUST be managed responsibly:

- Use Go modules (`go.mod`) with explicit versions; avoid `latest` or `master` dependencies
- Security vulnerabilities MUST be addressed promptly; run `govulncheck` in CI/CD
- Dependency updates MUST be tested in integration and E2E test suites before merging
- Kubernetes dependencies (`k8s.io/*`, `sigs.k8s.io/controller-runtime`) MUST stay within N-2 minor versions of the latest stable release
- Vendor only when necessary; prefer Go module proxies for reproducibility

**Rationale**: Controller-runtime and Kubernetes dependencies update frequently. Falling behind creates security risks and blocks access to bug fixes. Automated dependency management (Dependabot, Renovate) prevents drift.

### IX. Code Quality & Maintainability

All code MUST meet high quality standards:

- Code MUST pass `golangci-lint` with project configuration (`.golangci.yaml`)
- All exported functions, types, and constants MUST include godoc comments
- Error handling MUST use `errors.Is()` and `errors.As()` for wrapped errors; avoid string matching
- Context cancellation MUST be respected; long-running operations MUST accept `context.Context`
- Cyclomatic complexity MUST be kept low; refactor functions exceeding 15 complexity
- Code MUST be formatted with `gofmt`; imports MUST be organized with `goimports`

**Rationale**: Go codebases scale with discipline. Linting and formatting catch bugs early and make code reviews faster. Consistent style reduces cognitive load for all contributors.

## Code Quality Standards

### Error Handling

- Always wrap errors with context: `fmt.Errorf("failed to reconcile %s: %w", name, err)`
- Never ignore errors; if intentional, add a comment: `_ = resource.Close() // best-effort cleanup`
- Log errors before returning `ctrl.Result{Requeue: true}`

### Logging Best Practices

- Use structured logging keys consistently: `log.Info("reconciling", "name", req.NamespacedName)`
- Avoid log spam; do not log inside tight loops
- Use `log.V(1).Info()` for verbose logs that aid debugging but clutter normal operation

### Naming Conventions

- Use `camelCase` for unexported names, `PascalCase` for exported names
- Controller names should end with `Reconciler`: `FooReconciler`
- API group names should use reverse domain notation: `com.dimitrikoshkin.golang-repository-template`

## Kubernetes & Controller Standards

### RBAC & Security

- Grant minimum required permissions; never use `*` verbs or `*` resources in production RBAC
- Service accounts MUST be dedicated per controller
- Webhooks MUST use TLS; certificates MUST be rotated automatically (e.g., cert-manager)

### Helm Chart Standards

- Charts MUST follow Helm best practices: use `values.yaml` for all configurable parameters
- Charts MUST include resource limits and requests with sensible defaults
- Charts MUST support namespace-scoped and cluster-scoped installations
- RBAC resources MUST be templated to allow customization

### Controller Configuration

- Configuration MUST be provided via flags, environment variables, or ConfigMaps (in that order of preference)
- Hardcoded values are FORBIDDEN; all tunables MUST be configurable
- Defaults MUST be production-safe but allow overrides for development

## CI/CD & Release Standards

### Continuous Integration

- All PRs MUST pass linting (`golangci-lint`), unit tests, integration tests, and E2E tests
- Pre-commit hooks MUST be configured and documented (see `.pre-commit-config.yaml`)
- CI MUST run on every commit to `main` and all pull requests
- Code coverage MUST be reported to Codecov; coverage MUST NOT decrease

### Release Process

- Releases MUST use semantic versioning (MAJOR.MINOR.PATCH)
- Releases MUST be automated via `release-please-action`
- Container images MUST be built with GoReleaser and tagged with version and commit SHA
- Helm charts MUST be versioned independently but kept in sync with application versions
- Release notes MUST be auto-generated from conventional commits

### GoReleaser Configuration

`.goreleaser.yaml` MUST be configured according to project type:

**Controller-only:**
```yaml
builds:
  - id: controller-name
    dir: ./cmd/controller-name
    # ... controller-specific build config
kos:
  - id: controller-name
    build: controller-name
    # ... container image config
```

**CLI-only:**
```yaml
builds:
  - id: cli-name
    dir: ./cmd/cli-name
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
    # ... CLI-specific build config (no kos section)
```

**Both Controller and CLI:**
```yaml
builds:
  - id: controller
    dir: ./cmd/project-controller
    goos: [linux]
    # ... controller build config
  - id: cli
    dir: ./cmd/project-cli
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
    # ... CLI build config
kos:
  - id: controller
    build: controller
    # ... only controller gets container images
archives:
  - id: controller-archive
    builds: [controller]
  - id: cli-archive
    builds: [cli]
```

**Critical rules:**
- Each binary MUST have a unique build ID
- Controller binaries MUST include `kos` section for container images
- CLI binaries MUST support multiple OS/arch combinations
- `dir:` field MUST match `cmd/<binary-name>/` directory
- ldflags MUST inject version information from tags

### Conventional Commits

- Commit messages MUST follow Conventional Commits specification:
  - `feat:` for new features (MINOR version bump)
  - `fix:` for bug fixes (PATCH version bump)
  - `feat!:` or `BREAKING CHANGE:` footer for breaking changes (MAJOR version bump)
  - `docs:`, `chore:`, `ci:`, `test:` for non-release commits

### Dependency Updates

- Dependabot MUST be enabled for Go modules and GitHub Actions
- Devbox dependencies MUST be updated automatically via workflow
- Dependency PRs MUST pass all CI checks before auto-merge

## Governance

This constitution is the supreme authority for development decisions. All pull requests, design discussions, and architectural choices MUST comply with these principles.

### Amendment Process

1. Proposed amendments MUST be documented in a GitHub issue with rationale
2. Breaking changes to principles REQUIRE approval from the repository owner
3. Approved amendments MUST update this document and increment `CONSTITUTION_VERSION`
4. After amendment, all dependent templates (plan, spec, tasks) MUST be reviewed for alignment

### Versioning Policy

- **MAJOR**: Backward-incompatible changes to principles (e.g., removing a principle, changing NON-NEGOTIABLE rules)
- **MINOR**: New principles added or existing principles materially expanded
- **PATCH**: Clarifications, typo fixes, formatting improvements, non-semantic changes

### Compliance Review

- All feature plans MUST include a "Constitution Check" section validating compliance
- Violations MUST be justified in the "Complexity Tracking" section of the plan
- Repeated violations trigger a constitution review to determine if the principle is outdated

### Runtime Guidance

For day-to-day development guidance beyond constitutional principles, refer to:
- Kubebuilder Book: https://book.kubebuilder.io/
- Controller-runtime godoc: https://pkg.go.dev/sigs.k8s.io/controller-runtime
- Kubernetes API Conventions: https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md

**Version**: 1.0.0 | **Ratified**: 2026-01-10 | **Last Amended**: 2026-01-10
