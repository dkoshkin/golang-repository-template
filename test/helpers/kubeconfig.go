// Copyright 2026 Dimitri Koshkin. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"path/filepath"

	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	clientcmdapi "k8s.io/client-go/tools/clientcmd/api"
)

// WriteKubeconfig writes a kubeconfig file from rest.Config into dir and returns the file path.
// The file is named "kubeconfig". Caller is responsible for ensuring dir exists (e.g. t.TempDir()).
func WriteKubeconfig(cfg *rest.Config, dir string) (path string, err error) {
	path = filepath.Join(dir, "kubeconfig")
	config := kubeconfigFromRestConfig(cfg)
	if err := clientcmd.WriteToFile(*config, path); err != nil {
		return "", err
	}
	return path, nil
}

func kubeconfigFromRestConfig(cfg *rest.Config) *clientcmdapi.Config {
	clusterName := "envtest"
	contextName := "envtest"

	config := clientcmdapi.NewConfig()
	config.Clusters[clusterName] = &clientcmdapi.Cluster{
		Server:                   cfg.Host,
		CertificateAuthorityData: cfg.CAData,
	}
	config.AuthInfos[contextName] = &clientcmdapi.AuthInfo{
		ClientCertificateData: cfg.CertData,
		ClientKeyData:         cfg.KeyData,
		Token:                 cfg.BearerToken,
	}
	config.Contexts[contextName] = &clientcmdapi.Context{
		Cluster:  clusterName,
		AuthInfo: contextName,
	}
	config.CurrentContext = contextName
	return config
}
