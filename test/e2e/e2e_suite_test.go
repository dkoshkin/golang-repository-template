// Copyright 2025 Dimitri Koshkin. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

//go:build e2e
// +build e2e

package e2e

import (
	"fmt"
	"testing"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

// TestE2E runs the end-to-end (e2e) test suite for the project. These tests execute in an isolated,
// temporary environment to validate project changes with the purpose of being used in CI jobs.
// The default setup requires a KUBECONFIG environment variable to be set
// to a cluster with cert-manager installed and the project deployed.
func TestE2E(t *testing.T) {
	RegisterFailHandler(Fail)
	_, _ = fmt.Fprintf(GinkgoWriter, "Starting golang-repository-template integration test suite\n")
	RunSpecs(t, "e2e suite")
}
