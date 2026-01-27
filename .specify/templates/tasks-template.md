<!--
 Copyright 2025 Dimitri Koshkin. All rights reserved.
 SPDX-License-Identifier: Apache-2.0
 -->

---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Project type determines path structure (see plan.md for details):

- **Controller-only**: APIs in `api/v1alpha1/`, controllers in `internal/controller/`, controller binary in `cmd/<project>/`, config in `config/`, charts in `charts/`
- **CLI-only**: CLI binary in `cmd/<cli-name>/`, business logic in `internal/commands/`, tests in `test/`
- **Both**: Controller in `cmd/<project>-controller/`, CLI in `cmd/<project>-cli/` (or `cmd/<project>/`), shared code in `internal/`

All controller paths follow Kubebuilder v4 conventions. `.goreleaser.yaml` MUST have build IDs matching `cmd/` directories.

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/

  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment

  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization based on project type (Controller/CLI/Both)

**For all project types:**
- [ ] T001 Configure Go module dependencies in `go.mod`
- [ ] T002 [P] Setup golangci-lint, pre-commit hooks, and CI workflows
- [ ] T003 [P] Configure Codecov and test reporting
- [ ] T004 Update `.goreleaser.yaml` with correct build IDs matching `cmd/` directories

**Additional for Controller or Both:**
- [ ] T005 Verify `kubebuilder init` has been run (PROJECT file exists)
- [ ] T006 Setup Helm chart structure in `charts/<project>/`

**Additional for CLI or Both:**
- [ ] T007 Setup cobra CLI structure in `cmd/<cli-name>/`
- [ ] T008 Create base CLI command structure with version, help flags

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before user story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

**For Controller-only projects:**
- [ ] T009 Run `kubebuilder create api` to scaffold CRD in `api/v1alpha1/[resource]_types.go`
- [ ] T010 Define CRD Spec and Status fields with kubebuilder markers (+kubebuilder:validation, +kubebuilder:printcolumn)
- [ ] T011 Run `make manifests` to generate CRD YAML in `config/crd/`
- [ ] T012 Run `make kubebuilder.sync-chart` to sync manifests to Helm chart
- [ ] T013 [P] Setup controller reconciliation skeleton in `internal/controller/[resource]_controller.go`
- [ ] T014 [P] Configure controller manager with metrics, health probes, and leader election
- [ ] T015 [P] Setup structured logging (logr) and Prometheus metrics exporter
- [ ] T016 Create base test suite with envtest in `test/e2e/`

**For CLI-only projects:**
- [ ] T009 Create core command structure in `internal/commands/`
- [ ] T010 [P] Setup configuration loading (flags, env vars, config files)
- [ ] T011 [P] Create shared client/API utilities in `internal/client/`
- [ ] T012 Setup unit test framework in `test/`

**For Both (Controller + CLI) projects:**
- [ ] T009 Complete all controller foundation tasks (T009-T016 from Controller-only)
- [ ] T017 Create CLI binary structure in `cmd/<project>-cli/`
- [ ] T018 Create shared utilities in `internal/util/` for use by both binaries
- [ ] T019 Ensure `.goreleaser.yaml` has TWO build IDs (controller + CLI)
- [ ] T020 CLI commands for interacting with controller CRDs (get, list, create, delete)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 (OPTIONAL - only if tests requested) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation (TDD)**

- [ ] T013 [P] [US1] Unit test for reconciliation logic in internal/controller/[resource]_controller_test.go
- [ ] T014 [P] [US1] Integration test using envtest in test/e2e/e2e_test.go
- [ ] T015 [P] [US1] E2E test with real kind cluster validating end-to-end user workflow

### Implementation for User Story 1

- [ ] T016 [US1] Add Spec fields to api/v1alpha1/[resource]_types.go for user story requirements
- [ ] T017 [US1] Add Status conditions to api/v1alpha1/[resource]_types.go (Ready, Progressing, Failed)
- [ ] T018 [US1] Run `make manifests` to regenerate CRD with new fields
- [ ] T019 [US1] Implement reconciliation logic in internal/controller/[resource]_controller.go
- [ ] T020 [US1] Add finalizer handling for resource cleanup (if external resources created)
- [ ] T021 [US1] Update Status conditions based on reconciliation outcome
- [ ] T022 [US1] Emit Kubernetes Events for important state transitions
- [ ] T023 [US1] Add structured logging with appropriate log levels
- [ ] T024 [US1] Update Prometheus metrics (reconciliation duration, error count)
- [ ] T025 [US1] Run `make kubebuilder.sync-chart` to sync changes to Helm chart
- [ ] T026 [US1] Update Helm chart values.yaml with new configuration options (if any)

**Checkpoint**: At this point, User Story 1 should be fully functional, tested, and deployable via Helm

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 (OPTIONAL - only if tests requested) ⚠️

- [ ] T018 [P] [US2] Contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T019 [P] [US2] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 2

- [ ] T020 [P] [US2] Create [Entity] model in src/models/[entity].py
- [ ] T021 [US2] Implement [Service] in src/services/[service].py
- [ ] T022 [US2] Implement [endpoint/feature] in src/[location]/[file].py
- [ ] T023 [US2] Integrate with User Story 1 components (if needed)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3 (OPTIONAL - only if tests requested) ⚠️

- [ ] T024 [P] [US3] Contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T025 [P] [US3] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 3

- [ ] T026 [P] [US3] Create [Entity] model in src/models/[entity].py
- [ ] T027 [US3] Implement [Service] in src/services/[service].py
- [ ] T028 [US3] Implement [endpoint/feature] in src/[location]/[file].py

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in docs/
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance optimization across all stories
- [ ] TXXX [P] Additional unit tests (if requested) in tests/unit/
- [ ] TXXX Security hardening
- [ ] TXXX Run quickstart.md validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (if tests requested):
Task: "Contract test for [endpoint] in tests/contract/test_[name].py"
Task: "Integration test for [user journey] in tests/integration/test_[name].py"

# Launch all models for User Story 1 together:
Task: "Create [Entity1] model in src/models/[entity1].py"
Task: "Create [Entity2] model in src/models/[entity2].py"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
