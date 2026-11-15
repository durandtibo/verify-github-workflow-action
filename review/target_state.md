# Target state: verify-github-workflow-action

Review date: 2026-11-14. Scope: `action.yaml`, `README.md`, `.github/workflows/`, `CLAUDE.md`.
Breaking changes are accepted. The next release should be `v0.1.0`, with a migration note.

## 1. Properties of the action

These come from `CLAUDE.md` and the README. They are the contract the target state is
judged against.

| #   | Property                      | Meaning                                                                                                                     |
| --- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| P1  | Single purpose                | Lint and security-scan GitHub workflow files with actionlint and zizmor. Nothing else.                                      |
| P2  | Composite, no code of its own | All logic is `bash` in `action.yaml`. No scripts, no Docker, no JS, no build step.                                          |
| P3  | Portable                      | Linux, macOS and Windows runners (x64 and ARM). `shell: bash`. Works with both GNU and BSD tools.                           |
| P4  | Safe by construction          | Inputs reach scripts only through `env:`. Flags are tokenized with `xargs`, never `eval`ed. No `${{ inputs.* }}` in `run:`. |
| P5  | Supply-chain aware            | Nothing is executed from a moving ref. Tool versions are explicit and reproducible.                                         |
| P6  | Zero config                   | `uses:` with no `with:` works on a checked-out repo.                                                                        |
| P7  | Independent tools             | Each tool can be disabled. Disabling both is a successful no-op.                                                            |
| P8  | Fail loudly                   | Any finding, bad input or install failure fails the step with a clear message. Nothing is swallowed.                        |
| P9  | Clean workspace               | The action never writes into the user's checkout.                                                                           |
| P10 | Fast                          | Minimal steps, no redundant work, caching where the runner offers it.                                                       |
| P11 | Self-verifying                | This repo's workflows pass the action's own checks. Every input and every failure path is exercised in CI.                  |
| P12 | Immutable releases            | Exact version tags only (`v0.1.0`). No floating tags.                                                                       |

## 2. Findings on the current state

Ordered by impact.

### Violations of the properties

1. **P5: remote script executed from `main`.** `bash <(curl -sSL …/rhysd/actionlint/main/scripts/download-actionlint.bash)`
   runs whatever is on `main` at that moment. It is unpinned, unauthenticated code
   execution in every consumer's CI. The default `latest` for both tools also makes the
   same action tag give different results over time.
2. **P9: workspace pollution.** The actionlint download script saves the binary in the
   current directory, which is the user's checkout. A file named `actionlint` (or
   `actionlint.exe`) appears in the repo, and a later step such as `git status` or
   `git add -A` can pick it up.
3. **P4/P8: `paths` is split by the shell.** `$ACTIONLINT_PATHS` is expanded unquoted so
   the glob works, with a `shellcheck disable=SC2086`. Paths containing spaces break. A
   glob matching nothing is passed literally to the tool and fails with a confusing
   message. The default `.github/workflows/*` also matches non-workflow files such as
   `README.md` or `.yml.bak`.
4. **P3/P8: zizmor is installed with a global `pip install`.** It fails on "externally
   managed environment" (PEP 668) Pythons, and it mutates the runner's global
   environment. On self-hosted runners without Python it fails with no hint.
5. **P11: no negative tests.** CI only proves the action passes on this repo's valid
   workflows. Nothing proves it fails on a bad workflow, so a regression to "always
   green" would go unnoticed. `CLAUDE.md` requires a failing test for each bug fix.
   The version pins in `ci-action.yaml` (`1.7.9`, `1.14.0`) are also stale.

### Needless complexity (P10, maintainability)

6. Six steps where two or three are enough. The "Verify installation" step (an
   `-f` check after a script that already fails on error) and the final "All checks
   passed" step add runtime and lines, and carry no information. The final step also
   prints success when both tools are disabled.
7. Two near-identical 15-line flag-tokenizing blocks. A copy-paste divergence risk.
8. README duplicates the same minimal example four times ("Usage", "Minimal", "Basic CI
   Pipeline", "Scheduled"). The "How It Works" section is inaccurate: it says "latest"
   and `.github/workflows/` is hardcoded.

### Missing value

9. **No inline annotations.** Findings only appear in the log. zizmor has
   `--format=github`, and actionlint can emit the same with its own format flag. Both
   show up on the PR diff.
10. **No token for zizmor online audits.** Several zizmor audits (for example known
    vulnerable actions, impostor commits, ref confusion) need a token and are silently
    skipped, or the tool nags, when none is provided. There is no input to supply one.

### Small inconsistencies

11. `CLAUDE.md` says `lib-get-test-matrix.yaml` provides `os_all`, but the workflows read
    `os_matrix`. Fix whichever is wrong.
12. `README` examples use `actions/checkout@v6` while the repo itself pins v7 by SHA, and
    the examples use a floating major for a third-party action, contradicting the
    repo's own pinning rule. Examples should show a SHA pin with a ratchet comment.

## 3. Target design

### 3.1 Interface

Breaking changes are marked ⚠.

| Input                | Default                 | Change                                                                                                                                                                                                                                                                                                          |
| -------------------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `paths`              | `""` ⚠                  | Newline-separated list of files or directories. Empty means each tool auto-discovers `.github/workflows` (actionlint with no args does this, and zizmor with no args discovers workflows and actions). No glob parsing by the action; users who need globs let the runner shell or `with:` pass explicit files. |
| `actionlint`         | `"true"`                | Unchanged. Anything other than `true` or `false` fails with an error (P8), instead of silently disabling.                                                                                                                                                                                                       |
| `actionlint-version` | pinned, e.g. `1.7.12` ⚠ | Default becomes an exact version, bumped by the release process. `latest` remains accepted.                                                                                                                                                                                                                     |
| `actionlint-flags`   | `""`                    | Unchanged.                                                                                                                                                                                                                                                                                                      |
| `zizmor`             | `"true"`                | Unchanged, with the same strict validation.                                                                                                                                                                                                                                                                     |
| `zizmor-version`     | pinned ⚠                | As for actionlint.                                                                                                                                                                                                                                                                                              |
| `zizmor-flags`       | `""`                    | Unchanged. The action adds `--format=github` itself unless the user passes `--format`/`-f`.                                                                                                                                                                                                                     |
| `github-token` (new) | `""`                    | Passed to zizmor as `GH_TOKEN` to enable online audits. Optional. Never echoed. Users pass `${{ github.token }}` (needs `contents: read` and `actions: read`, nothing more).                                                                                                                                    |

No outputs. The step's pass/fail status is the interface (P1).

Why pinned defaults: with immutable releases (P12), "action `vX` gives result R" is
the strongest property a CI gate can have. A new actionlint rule must not turn every
consumer's CI red overnight. Updating the pins is part of the release, and Dependabot
or the existing `bot-` workflows can propose it. `latest` stays available for people
who want the moving target.

### 3.2 Implementation

Three steps, down from six. Each has a `name:` and a comment (existing rule).

1. **Validate inputs and prepare** (one step): check the two booleans, create
   `$RUNNER_TEMP/verify-workflows/bin`, and export it with `GITHUB_PATH`. This also
   keeps P9, because every tool lives in `RUNNER_TEMP`.
2. **actionlint** (`if: inputs.actionlint == 'true'`): install, then run, in one step.
3. **zizmor** (`if: inputs.zizmor == 'true'`): install, then run, in one step.

Install and run share a step because they share the same inputs and the same failure
meaning. This removes the step-output plumbing (`steps.install.outputs.executable`).

actionlint install:

- Run the official download script pinned to a release tag **SHA** (not `main`),
  from inside `$RUNNER_TEMP/verify-workflows/bin`, so the binary never touches the
  checkout.
- Pass the version as the script argument, and keep passing `ACTIONLINT_VERSION` via
  `env:`.
- Known limit, to document in `SECURITY.md`: the pinned script downloads the release
  archive over HTTPS from GitHub releases. If checksum verification is wanted later,
  the next step up is downloading `actionlint_<v>_checksums.txt` and comparing with
  `sha256sum`/`shasum -a 256`. That is deferred because it needs per-OS archive
  naming and costs about 30 lines for a marginal gain on top of pinned HTTPS.

zizmor install:

- `pipx run --spec "zizmor==$ZIZMOR_VERSION" zizmor …` is the target. pipx is
  preinstalled on GitHub-hosted runners (all three OSes), isolates the install from the
  global environment, and caches the venv. `latest` maps to `--spec zizmor`.
- Fallback for runners without pipx: `uvx zizmor@<version>` if `uv` exists. Do not add
  both. Pick pipx and state in the README that Python plus pipx are required. This
  needs a one-time check on Windows and macOS ARM runners in CI before release; I
  could not run workflows locally to confirm it.

Argument handling (one shared shape, written once per step, no `shellcheck disable`):

```bash
set -euo pipefail

flags=()
if [ -n "$ACTIONLINT_FLAGS" ]; then          # BSD xargs yields one empty token on empty input
  while IFS= read -r f; do flags+=("$f"); done < <(xargs -n1 <<<"$ACTIONLINT_FLAGS")
fi

targets=()
while IFS= read -r p; do                      # newline-separated, spaces preserved
  [ -n "$p" ] && targets+=("$p")
done <<<"$VERIFY_PATHS"

"$bin" ${flags[@]+"${flags[@]}"} ${targets[@]+"${targets[@]}"}
```

The `${arr[@]+"${arr[@]}"}` form is required: bash 3.2 on macOS errors on an empty
array under `set -u`. This replaces the `if len > 0 … else …` duplication and the
SC2086 disable. Because both tools take identical `flags`/`paths` handling, the
duplication that remains is deliberate (composite actions have no functions across
steps) and small, at about 8 lines each.

Annotations: zizmor gets `--format=github` unless the user's flags already contain
`--format` or `-f`. actionlint gets no automatic format change. Its default output
is already `file:line:col: message`, and the user can pass `-format` themselves.
This keeps the zero-config path simple and avoids a surprise for people who parse
the log.

Dropped: "Verify installation" step, "All checks passed" step, emoji banners beyond a
single start line per tool. The runner already marks each step green or red.

### 3.3 Skeleton

```yaml
runs:
  using: composite
  steps:
    # Validate booleans and create a private tool directory outside the checkout
    - name: Prepare
      shell: bash
      env:
        ACTIONLINT: ${{ inputs.actionlint }}
        ZIZMOR: ${{ inputs.zizmor }}
      run: |
        set -euo pipefail
        for v in "$ACTIONLINT" "$ZIZMOR"; do
          case "$v" in true|false) ;; *) echo "::error::actionlint/zizmor must be 'true' or 'false', got '$v'"; exit 1 ;; esac
        done
        mkdir -p "$RUNNER_TEMP/verify-workflows/bin"
        echo "$RUNNER_TEMP/verify-workflows/bin" >> "$GITHUB_PATH"

    # Install actionlint (pinned script, outside the checkout) and run it
    - name: actionlint
      if: inputs.actionlint == 'true'
      shell: bash
      env: { ACTIONLINT_VERSION: …, ACTIONLINT_FLAGS: …, VERIFY_PATHS: … }
      run: …

    # Run zizmor through pipx (isolated, cached) and annotate the PR
    - name: zizmor
      if: inputs.zizmor == 'true'
      shell: bash
      env:
        {
          ZIZMOR_VERSION: …,
          ZIZMOR_FLAGS: …,
          VERIFY_PATHS: …,
          GH_TOKEN: "${{ inputs.github-token }}",
        }
      run: …
```

## 4. Tests and CI

Keep the existing layout (`ci.yaml` → `lib-get-test-matrix`, `ci-format`, `ci-action`;
`nightly.yaml` → `nightly-test-released`; `ci-verify-workflows` standalone). Changes:

1. **Fixtures.** Add `tests/fixtures/valid/ok.yaml`, `tests/fixtures/actionlint-error.yaml`
   (for example an undefined `needs` reference) and `tests/fixtures/zizmor-error.yaml`
   (for example `${{ github.event.issue.title }}` in `run:`). They live outside
   `.github/workflows`, so they are never run and never fail the self-check.
2. **Negative jobs in `ci-action.yaml`.** Run the action with `paths` pointing at each bad
   fixture, `continue-on-error: true` and an `id`. A following step asserts
   `steps.<id>.outcome == 'failure'`, failing otherwise. Cover:
   - actionlint-error is caught with actionlint on, and ignored with `actionlint: "false"`.
   - zizmor-error is caught with zizmor on, and ignored with `zizmor: "false"`.
   - A bad boolean value (`actionlint: "yes"`) fails.
3. **Input coverage.** One job for each: default, `paths` with a space in the path (add a
   `tests/fixtures/dir with space/ok.yaml`), a multi-line `paths`, custom pinned
   versions (refresh to current), `latest`, flags with quoted values, `github-token`
   set, both disabled.
4. **Workspace cleanliness test.** After the action runs, assert `git status --porcelain`
   is empty (guards P9).
5. **Matrix.** Positive default test on the full OS matrix (from the lib workflow,
   never hardcoded). Negative and input-variant jobs may run on `ubuntu-latest` only,
   plus one macOS and one Windows run of the failure test, since the xargs, array and
   pipx behaviours are exactly what differs per OS.
6. Mirror the positive and negative cases in `nightly-test-released.yaml` after
   release, with the same matrix.
7. Reconcile `os_all` (CLAUDE.md) and `os_matrix` (workflows).

## 5. Documentation target

README restructure (about 40% shorter):

1. One paragraph, then the properties table from section 1, condensed to 6 bullets.
2. **Usage**: a single minimal example, pinned by SHA with a ratchet comment and
   `persist-credentials: false` on checkout.
3. **Inputs** table, including `github-token`, with the exact defaults from `action.yaml`.
4. **Recipes** (short): disable a tool, check specific paths, pin versions, enable
   zizmor online audits (with the minimal `permissions:` block).
5. **Requirements**: checked-out repo, `bash`, Python with `pipx` (preinstalled on
   GitHub-hosted runners) for zizmor.
6. **Migration to v0.1.0**: `paths` default and format changed, default versions are
   now pinned, `paths` is newline-separated and no longer glob-expanded by the action.
7. Remove: duplicated examples, the multi-OS and scheduled examples (they only wrap
   the same step), the claim "latest version" in Features.

`CLAUDE.md` updates: new input and behaviours, fixtures location, the
`os_all`/`os_matrix` fix, the rule "tools are installed under `RUNNER_TEMP`, never the
workspace", and the release step "bump default tool versions".
`SECURITY.md`: describe the supply-chain posture (pinned script, pinned versions, no
checksum check yet).

## 6. Deliberately not changing

- Composite action with bash (P2): a Docker or JS action would be slower and heavier.
- Two tools in one action: splitting would double the usage boilerplate for no gain.
- `xargs`-based flag tokenization (P4): still the simplest injection-safe option.
- No `outputs`: the exit status is the signal, and SARIF upload is out of scope. Users
  can pass `--format=sarif` through `zizmor-flags` themselves.
- No version-bumping bot in this change. Mention as follow-up.

## 7. Rollout order

One PR per logical change, per `CLAUDE.md`:

1. `test/`: fixtures plus negative jobs against the **current** action (proves the
   tests are meaningful, and reveals the workspace pollution and space-in-path bugs).
2. `refactor/`: three-step `action.yaml`, safe arg handling, `RUNNER_TEMP`
   install, pipx. Breaking `paths` change is flagged in the PR.
3. `feat/`: `github-token` input, zizmor annotations, strict booleans, pinned defaults.
4. `docs/`: README, CLAUDE.md, SECURITY.md.
5. Release `v0.1.0`, then update the pinned version in `README.md`,
   `ci-verify-workflows.yaml` and `nightly-test-released.yaml`.

## 8. Open points to verify before implementing

- pipx availability and speed on Windows and macOS ARM runners (not testable locally).
- Whether zizmor's current release still auto-discovers with no path argument as
  assumed; if not, the default must be an explicit `.github/workflows`.
- Current latest versions of actionlint and zizmor, and the SHA of the actionlint
  download script at that tag, to set the pins.
- Workflows cannot be run locally. None of the proposed CI changes have been
  executed, and nothing was changed outside `review/`.
