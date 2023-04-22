// Copyright 2023 Dimitri Koshkin. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"fmt"

	"github.com/dkoshkin/golang-repository-template/pkg/version"
)

func main() {
	fmt.Println(version.Print())
}
