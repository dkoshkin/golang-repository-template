// Copyright 2026 Dimitri Koshkin. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

// Package helpers provides utilities for integration testing (envtest).
package helpers

import (
	"os"
	"path/filepath"

	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/rest"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/envtest"
)

// TestEnvironmentConfiguration configures the envtest environment.
type TestEnvironmentConfiguration struct {
	env *envtest.Environment
}

// TestEnvironment holds a local API server + etcd from envtest (no controller manager).
type TestEnvironment struct {
	Config         *rest.Config
	env            *envtest.Environment
	kubeconfigPath string
}

// NewTestEnvironmentConfiguration creates a new test environment configuration.
// CRDs are optional; paths can be added later when the API module has CRDs.
func NewTestEnvironmentConfiguration() *TestEnvironmentConfiguration {
	return &TestEnvironmentConfiguration{
		env: &envtest.Environment{
			ErrorIfCRDPathMissing: false,
		},
	}
}

// WithCRDDirectoryPaths adds CRD directories for envtest to load.
func (c *TestEnvironmentConfiguration) WithCRDDirectoryPaths(paths ...string) *TestEnvironmentConfiguration {
	c.env.CRDDirectoryPaths = append(c.env.CRDDirectoryPaths, paths...)
	c.env.ErrorIfCRDPathMissing = true
	return c
}

// Build starts the envtest API server and etcd and returns a TestEnvironment.
// A kubeconfig file is written once to a temp dir for use with GetKubeconfig.
func (c *TestEnvironmentConfiguration) Build() (*TestEnvironment, error) {
	cfg, err := c.env.Start()
	if err != nil {
		return nil, err
	}
	dir, err := os.MkdirTemp("", "envtest-kubeconfig-")
	if err != nil {
		return nil, err
	}
	kubeconfigPath, err := WriteKubeconfig(cfg, dir)
	if err != nil {
		_ = os.RemoveAll(dir)
		return nil, err
	}
	return &TestEnvironment{
		Config:         cfg,
		env:            c.env,
		kubeconfigPath: kubeconfigPath,
	}, nil
}

// GetConfig returns the rest.Config for the envtest API server.
func (t *TestEnvironment) GetConfig() *rest.Config {
	return t.Config
}

// GetK8sClientWithScheme returns a client that talks to the envtest API server
// using the given scheme (e.g. client-go scheme).
func (t *TestEnvironment) GetK8sClientWithScheme(clientScheme *runtime.Scheme) (client.Client, error) {
	return client.New(t.Config, client.Options{Scheme: clientScheme})
}

// GetKubeconfig returns the path to the kubeconfig file for the envtest API server.
// The file is created once when the environment is built.
func (t *TestEnvironment) GetKubeconfig() string {
	return t.kubeconfigPath
}

// Stop stops the envtest environment and removes the kubeconfig temp dir.
func (t *TestEnvironment) Stop() error {
	_ = os.RemoveAll(filepath.Dir(t.kubeconfigPath))
	return t.env.Stop()
}
