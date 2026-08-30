# verify-github-workflow-action

[![CI](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/ci.yaml/badge.svg)](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/ci.yaml)
[![Nightly Tests](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/nightly-tests.yaml/badge.svg)](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/nightly-tests.yaml)
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://github.com/durandtibo/verify-github-workflow-action/blob/main/LICENSE)

A GitHub Action to verify and validate GitHub workflow files using
[zizmor](https://github.com/woodruffw/zizmor) and, optionally,
[actionlint](https://github.com/rhysd/actionlint).
This action helps catch errors and issues in your workflow files early, ensuring they
follow best practices, are correctly configured, and are free of common security
pitfalls.

## Table of Contents

- [Features](#features)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Examples](#examples)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Automated Validation**: Automatically checks all workflow files in `.github/workflows/`
- **zizmor Integration**: Runs zizmor (enabled by default) to catch security issues such as
  script injection, overly broad `GITHUB_TOKEN` permissions, and unpinned third-party actions
- **actionlint Integration** (opt-in): Runs actionlint for additional syntax and semantic
  checks. It is disabled by default because its upstream maintenance has slowed down; set
  `actionlint: "true"` to enable it
- **Error Detection**: Catches syntax errors, invalid workflow configurations, best
  practice violations, and security issues
- **Multi-Platform Support**: Works on Ubuntu, macOS, Windows, and ARM-based runners
- **Zero Configuration**: Works out of the box with sensible defaults

## Usage

To use this action in your workflow, add the following step to your workflow file:

```yaml
name: Verify Workflows

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Verify GitHub Workflows
        uses: durandtibo/verify-github-workflow-action@v0.0.3
```

### Minimal Example

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v6

  - name: Verify GitHub Workflows
    uses: durandtibo/verify-github-workflow-action@v0.0.3
```

## How It Works

This action performs the following steps:

1. **Install zizmor**: Installs the latest version of zizmor (unless disabled)
2. **Security Scan**: Runs zizmor on all workflow files in `.github/workflows/` to catch
   security issues
3. **Install actionlint** (opt-in): Downloads and installs actionlint, only if
   `actionlint: "true"` is set
4. **Validate**: Runs actionlint on the same workflow files

The action will fail if any errors are found in your workflow files, helping you catch
issues before they cause problems in production.

**Note**: The action requires your repository code to be checked out first using
`actions/checkout` before it can validate the workflow files.

### Inputs

| Name                 | Description                                    | Default               |
| -------------------- | ---------------------------------------------- | --------------------- |
| `paths`              | Paths or glob patterns to workflow files       | `.github/workflows/*` |
| `zizmor`             | Whether to run zizmor (`"true"`/`"false"`)     | `true`                |
| `zizmor-version`     | Version of zizmor to install                   | `latest`              |
| `zizmor-flags`       | Additional flags to pass to zizmor             | `""`                  |
| `actionlint`         | Whether to run actionlint (`"true"`/`"false"`) | `false`               |
| `actionlint-version` | Version of actionlint to install               | `latest`              |
| `actionlint-flags`   | Additional flags to pass to actionlint         | `""`                  |

### Disabling zizmor

```yaml
- name: Verify GitHub Workflows
  uses: durandtibo/verify-github-workflow-action@v0.0.3
  with:
    zizmor: "false"
```

### Enabling actionlint

actionlint is disabled by default because its upstream maintenance has slowed down. If you
still want its checks (e.g. its shellcheck integration for `run:` steps), enable it:

```yaml
- name: Verify GitHub Workflows
  uses: durandtibo/verify-github-workflow-action@v0.0.3
  with:
    actionlint: "true"
```

## Examples

### Basic CI Pipeline

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  verify-workflows:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Verify GitHub Workflows
        uses: durandtibo/verify-github-workflow-action@v0.0.3
```

### Multiple OS Testing

```yaml
name: Multi-OS Verification

on: [push, pull_request]

jobs:
  verify:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Verify GitHub Workflows
        uses: durandtibo/verify-github-workflow-action@v0.0.3
```

### Scheduled Workflow Verification

```yaml
name: Weekly Workflow Check

on:
  schedule:
    - cron: "0 0 * * 0" # Every Sunday at midnight

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Verify GitHub Workflows
        uses: durandtibo/verify-github-workflow-action@v0.0.3
```

## Requirements

- **The action requires your repository code to be checked out first using
  `actions/checkout` before running the verification**
- Your repository must contain workflow files in `.github/workflows/` directory
- The runner must have bash available (standard on all GitHub-hosted runners)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how
to contribute to this project.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file
for details.
