# verify-github-workflow-action

[![CI](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/ci.yaml/badge.svg)](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/ci.yaml)
[![Nightly Tests](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/nightly.yaml/badge.svg)](https://github.com/durandtibo/verify-github-workflow-action/actions/workflows/nightly.yaml)
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://github.com/durandtibo/verify-github-workflow-action/blob/main/LICENSE)

A GitHub Action to verify and validate GitHub workflow files using
[actionlint](https://github.com/rhysd/actionlint) and
[zizmor](https://github.com/zizmorcore/zizmor).
This action helps catch errors and issues in your workflow files early, ensuring they
follow best practices, are correctly configured, and are free of common security
pitfalls.

## Table of Contents

- [Features](#features)
- [Usage](#usage)
- [Inputs](#inputs)
- [Recipes](#recipes)
- [Requirements](#requirements)
- [Migration to v0.1.0](#migration-to-v010)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Two checkers**: actionlint (syntax and correctness) and zizmor (security), each one
  can be disabled
- **Reproducible**: tool versions are pinned by default, and nothing is executed from a
  moving ref (see [SECURITY.md](SECURITY.md))
- **Annotations**: zizmor findings show up inline on pull requests
- **Clean**: tools are installed outside your checkout, which is never modified
- **Portable**: Linux, macOS and Windows runners (x64 and ARM)
- **Zero configuration**: works on a checked-out repository with no input

## Usage

```yaml
name: Verify Workflows

on:
  pull_request:
  push:
    branches: [main]

permissions: {}

jobs:
  verify:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # ratchet:actions/checkout@v7
        with:
          persist-credentials: false

      - name: Verify GitHub Workflows
        uses: durandtibo/verify-github-workflow-action@e5dc341675711838a82b2433f70a225858ad70d1 # ratchet:durandtibo/verify-github-workflow-action@v0.0.3
```

The action fails if actionlint or zizmor report a finding, if an input is invalid, or if a
tool cannot be installed.

## Inputs

| Name                 | Description                                                                                        | Default  |
| -------------------- | -------------------------------------------------------------------------------------------------- | -------- |
| `paths`              | Newline-separated workflow files (no glob expansion; default: all of `.github/workflows`)          | `""`     |
| `actionlint`         | Whether to run actionlint (`"true"`/`"false"`, anything else fails)                                | `"true"` |
| `actionlint-version` | Version of actionlint to install (`x.y.z` or `latest`)                                             | `1.7.12` |
| `actionlint-flags`   | Additional flags to pass to actionlint                                                             | `""`     |
| `zizmor`             | Whether to run zizmor (`"true"`/`"false"`, anything else fails)                                    | `"true"` |
| `zizmor-version`     | Version of zizmor to install (`x.y.z` or `latest`)                                                 | `1.32.0` |
| `zizmor-flags`       | Additional flags to pass to zizmor (`--format=github` is added unless you pass `--format`)         | `""`     |
| `github-token`       | Token for zizmor online audits (`${{ github.token }}`; needs `contents: read` and `actions: read`) | `""`     |

The action has no outputs: the status of the step is the result. Flags are split like
shell words (quotes are honored) but are never evaluated as shell code.

## Recipes

Disable a tool (disabling both is a successful no-op):

```yaml
- uses: durandtibo/verify-github-workflow-action@e5dc341675711838a82b2433f70a225858ad70d1 # ratchet:durandtibo/verify-github-workflow-action@v0.0.3
  with:
    zizmor: "false"
```

Check specific files (one per line, spaces are fine):

```yaml
- uses: durandtibo/verify-github-workflow-action@e5dc341675711838a82b2433f70a225858ad70d1 # ratchet:durandtibo/verify-github-workflow-action@v0.0.3
  with:
    paths: |
      .github/workflows/ci.yaml
      .github/workflows/release.yaml
```

Pin the tool versions, or follow the latest ones:

```yaml
- uses: durandtibo/verify-github-workflow-action@e5dc341675711838a82b2433f70a225858ad70d1 # ratchet:durandtibo/verify-github-workflow-action@v0.0.3
  with:
    actionlint-version: "1.7.12"
    zizmor-version: latest
```

Enable the zizmor online audits (for example known vulnerable actions or impostor commits):

```yaml
permissions:
  contents: read
  actions: read
steps:
  - uses: durandtibo/verify-github-workflow-action@e5dc341675711838a82b2433f70a225858ad70d1 # ratchet:durandtibo/verify-github-workflow-action@v0.0.3
    with:
      github-token: ${{ github.token }}
```

## Requirements

- Your repository must be checked out first (`actions/checkout`)
- `bash` (standard on all GitHub-hosted runners)
- `curl` and `tar` (`unzip` on Windows) to install actionlint; they are preinstalled on
  GitHub-hosted runners, self-hosted runners need them
- Python with `pipx` to run zizmor (both are preinstalled on GitHub-hosted runners)

## Migration to v0.1.0

> **Unreleased**: this applies when upgrading from `v0.0.3` to `v0.1.0`, which is not
> released yet. `v0.0.3` behaves as described by its own README.

- Both tools always run: zizmor now runs even if actionlint failed (and the reverse), so
  one run reports the findings of both. The action still fails if either tool fails. A
  failed preparation (invalid input) still skips both tools.
- `paths` now defaults to `""` (the workflows in `.github/workflows`) instead of
  `.github/workflows/*`. It is newline-separated and no longer expanded as a glob: list
  the files explicitly.
- `actionlint-version` and `zizmor-version` default to pinned versions instead of
  `latest`. Set them to `latest` to keep the previous behaviour.
- zizmor prints GitHub annotations (`--format=github`) unless you pass `--format`.
- `actionlint` and `zizmor` must be `"true"` or `"false"`. Other values fail instead of
  silently disabling the tool.
- zizmor is run with `pipx` instead of being installed with `pip`.
- New input: `github-token`.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how
to contribute to this project.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file
for details.
