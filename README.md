# verify-github-workflow-action

[![CI](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/ci.yaml/badge.svg)](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/ci.yaml)
[![Nightly Tests](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/nightly-tests.yaml/badge.svg)](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/nightly-tests.yaml)
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://github.com/durandtibo/verify-github-workflow-action/blob/main/LICENSE)

A GitHub Action to verify and validate GitHub workflow files using
[actionlint](https://github.com/rhysd/actionlint).
This action helps catch errors and issues in your workflow files early, ensuring they
follow best practices and are correctly configured.

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
- **actionlint Integration**: Uses the latest version of actionlint for comprehensive validation
- **Error Detection**: Catches syntax errors, invalid workflow configurations, and best
  practice violations
- **Multi-Platform Support**: Works on Ubuntu, macOS, and ARM-based runners
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
        uses: durandtibo/verify-github-workflow-action@v0.0.2
```

### Minimal Example

```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v6

  - name: Verify GitHub Workflows
    uses: durandtibo/verify-github-workflow-action@v0.0.2
```

## How It Works

This action performs the following steps:

1. **Install actionlint**: Downloads and installs the latest version of actionlint
2. **Version Check**: Displays the installed actionlint version for debugging
3. **Validate**: Runs actionlint on all workflow files in `.github/workflows/`

The action will fail if any errors are found in your workflow files, helping you catch
issues before they cause problems in production.

**Note**: The action requires your repository code to be checked out first using
`actions/checkout` before it can validate the workflow files.

## Examples

### Basic CI Pipeline

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Run tests
        run: make test

  verify-workflows:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Verify GitHub Workflows
        uses: durandtibo/verify-github-workflow-action@v0.0.2
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
        uses: durandtibo/verify-github-workflow-action@v0.0.2
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
        uses: durandtibo/verify-github-workflow-action@v0.0.2
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
