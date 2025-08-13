<!--
 Copyright 2025 Dimitri Koshkin. All rights reserved.
 SPDX-License-Identifier: Apache-2.0
 -->

# Project Template

[![build](https://github.com/dkoshkin/golang-repository-template/actions/workflows/build.yml/badge.svg)](https://github.com/dkoshkin/golang-repository-template/actions/workflows/build.yml)
[![codecov](https://codecov.io/github/dkoshkin/golang-repository-template/graph/badge.svg?token=RUEME4RFZK)](https://codecov.io/github/dkoshkin/golang-repository-template)

This repository serves as a starting point for new Golang projects.
It includes a Makefile with common development targets, a pre-configured development environment,
GitHub Actions workflows, and a clean, modular project structure.

Just replace all instances of `golang-repository-template` and `Golang Repository Template` with your project’s name.

## Prerequisites

...

## Usage Instructions

...

## Setup your Dev Environment

- Install [devbox](https://www.jetify.com/docs/devbox/installing_devbox/)
- Install [direnv](https://direnv.net/)
- Run `direnv allow`

Tip: to see all available make targets with descriptions, simply run `make`.

### Test

```bash
make test
```

### Build

The binary for your OS will be placed in `./dist`,
e.g. `./dist/golang-repository-template_darwin_arm64_v8.0/golang-repository-template`:

```bash
make build-snapshot
```

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
