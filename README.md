<!--
 Copyright 2023 Dimitri Koshkin. All rights reserved.
 SPDX-License-Identifier: Apache-2.0
 -->

# <PROJECT_NAME>

Replace `<PROJECT_NAME>` with the name of the project.

## Dev Instructions

-   Built it, the binary for your OS will be placed in `./dist`, e.g. `./dist/<PROJECT_NAME>_darwin_arm64/<PROJECT_NAME>`:

    ```shell
    make build-snapshot
    ```

-   Test it:

    ```shell
    make test
    ```

-   Lint it:

    ```shell
    make lint
    ```
