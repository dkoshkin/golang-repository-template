// Copyright 2026 Dimitri Koshkin. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers_test

import (
	"testing"

	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"

	"github.com/dkoshkin/golang-repository-template/test/helpers"
)

func TestEnvtestListsNamespaces(t *testing.T) {
	t.Parallel()

	env, err := helpers.NewTestEnvironmentConfiguration().Build()
	if err != nil {
		t.Fatalf("start envtest: %v", err)
	}
	t.Cleanup(func() {
		if stopErr := env.Stop(); stopErr != nil {
			t.Errorf("stop envtest: %v", stopErr)
		}
	})

	scheme := runtime.NewScheme()
	if err := clientgoscheme.AddToScheme(scheme); err != nil {
		t.Fatalf("add scheme: %v", err)
	}

	k8sClient, err := env.GetK8sClientWithScheme(scheme)
	if err != nil {
		t.Fatalf("create client: %v", err)
	}

	nsList := &corev1.NamespaceList{}
	if err := k8sClient.List(t.Context(), nsList); err != nil {
		t.Fatalf("list namespaces: %v", err)
	}
	if len(nsList.Items) == 0 {
		t.Fatal("expected at least one namespace")
	}

	for _, ns := range nsList.Items {
		if ns.Name == "default" {
			return
		}
	}
	t.Fatal("expected default namespace")
}
