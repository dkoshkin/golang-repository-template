<!--
 Copyright 2025 Dimitri Koshkin. All rights reserved.
 SPDX-License-Identifier: Apache-2.0
 -->

# Project Template

[![build](https://github.com/dkoshkin/golang-repository-template/actions/workflows/build.yaml/badge.svg)](https://github.com/dkoshkin/golang-repository-template/actions/workflows/build.yaml)
[![codecov](https://codecov.io/github/dkoshkin/golang-repository-template/graph/badge.svg?token=RUEME4RFZK)](https://codecov.io/github/dkoshkin/golang-repository-template)

This repository serves as a starting point for new Golang projects.
It includes a Makefile with common development targets with `make`,
a pre-configured development environment using [Devbox][Devbox],
GitHub Actions workflows, and [release-please-action][release-please-action] for release automation.

The template is configured with [Kubebuilder][Kubebuilder] v4 for building Kubernetes operators.
Kubebuilder manifests in `config/` are automatically synced to the Helm chart using the `kubebuilder.sync-chart` make target,
which uses the Kubebuilder Helm plugin to keep your chart in sync with generated RBAC, manager, and other Kubernetes resources

## Prerequisites

...

## Usage Instructions

Use this repo as the template for a new repository by making the following changes.

### Changes in the repository

1. Search and replacing all instances of `golang-repository-template` and `Golang Repository Template`
   with your project's name.
2. Rename the folder in `cmd/` and `charts/` with your project's name.
3. Update the files in `hack/license` with your details.
4. Run `echo "{}" > .release-please-manifest.json` to clear out the release-please version.

#### Kubebuilder

This template is initialized with [Kubebuilder][Kubebuilder] to build Kubernetes controllers.
To remove, make the following changes:

1. Remove `kubebuilder.sync-chart` target in [`make/goreleaser.mk`](make/goreleaser.mk).
2. Remove `generate manifests` target from [`make/go.mk`](make/go.mk).
3. Delete the [`make/kubebuilder.mk`](make/kubebuilder.mk) and remove its reference from [`make/all.mk`](make/all.mk).
4. Delete the [`PROJECT`](PROJECT) file.
5. Delete the [`config/`](config/) directory.

### Changes in Github

1. Go to `Settings` > `General` and enable `Allow auto-merge` and `Automatically delete head branches`.
2. Create two [Github PATs][Github-PAT] to use in Github automation.
   - One to use with [release-please-action][release-please-action], adding the following permissions:
     - Contents: read and write
     - Pull Requests: read and write
     - Actions: read and write
     - Issues: read and write

     Go to `Settings` > `Secrets and variables` > `Actions` and add is as `RELEASE_PLEASE_TOKEN`.

   - Another to use with [Devbox][Devbox] update automation, adding the following permissions:
     - Contents: read and write
     - Pull Requests: read and write
     - Issues: read and write

     Go to `Settings` > `Secrets and variables` > `Actions` and add is as `DEPENDENCY_AUTOMATION_TOKEN`.

     Go to `Settings` > `Secrets and variables` > `Actions` and add these Secrets
     `GIT_SSH_SIGNING_PRIVATE_KEY`, `GIT_USER_NAME` and `GIT_USER_EMAIL`.
3. Go to `Settings` > `Pages` and set the source to `gh-pages` branch and `/ (root)` folder.
4. Go to `Settings` > `Branches` > `Add branch ruleset` and configure it for the "default" and `release/**/*` branches.
   Enable "Require signed commits" and "Require a pull request before merging".
   Enable "Require status checks to pass" with the following checks:
   - build / build
   - lint / gha
   - lint / go (.)
   - lint / helm
   - pre-commit / pre-commit
   - unit-tests / unit-tests
   - govulncheck / govulncheck (.)
   - codeql / analyze (go)
   - e2e-tests / e2e-tests
5. Go to `Settings` > `Pages` > `Branch` and select `main` and `/docs` as the Source.

### Changes in Codecov

This template is configured with [Codecov][Codecov] that must be configured before using.

Go to `Settings` > `Secrets and variables` > `Actions` and add the generated token as `CODECOV_TOKEN`.

## Setup your Dev Environment

1. Install [Devbox][Devbox]
2. Install [direnv][direnv]
   - run `direnv allow`
3. Install [pre-commit][pre-commit-hooks] git hooks
   - run `pre-commit install`

Tip: to see all available make targets with descriptions, simply run `make`.

### Test

```bash
make test
```

This repository is configured with [Codecov][Codecov] but can be removed by modifying `.github/workflows/unit-tests.yml`.

### Build

```bash
make build-snapshot
```

The binary for your OS will be placed in `./dist`,
e.g. `./dist/golang-repository-template_darwin_arm64_v8.0/golang-repository-template`:

### Lint

```bash
make lint
make lint-chart
```

### Pre-commit

```bash
make pre-commit
```

### Helm Chart

```bash
make chart-docs
make schema-chart
```

### Build Tooling

The repository is configured with automation to periodically update dependencies.

- [dependabot action][dependabot-action] to update both Github Actions and Golang `go.mod` dependencies using [Dependabot][Dependabot].
- [devbox action][devbox-action] to update [Devbox][Devbox] packages.

[Devbox]: https://www.jetify.com/docs/devbox/installing-devbox
[release-please-action]: https://github.com/googleapis/release-please-action
[Github-PAT]: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
[direnv]: https://direnv.net/
[Codecov]: https://about.codecov.io/
[pre-commit-hooks]: https://pre-commit.com/#3-install-the-git-hook-scripts
[Dependabot]: https://docs.github.com/en/code-security/getting-started/dependabot-quickstart-guide
[dependabot-action]: https://github.com/dkoshkin/golang-repository-template/actions/workflows/dependabot/dependabot-updates
[devbox-action]: https://github.com/dkoshkin/golang-repository-template/actions/workflows/devbox-dependencies-update.yaml
[Kubebuilder]: https://book.kubebuilder.io/
