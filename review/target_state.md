# Target state: verify-github-workflow-action

Review date: 2026-11-14. Scope: `action.yaml`, `README.md`, `SECURITY.md`, `Makefile`,
`.github/workflows/`, `tests/fixtures/`, `CLAUDE.md`.

This replaces the first review (PR #52). Nearly all of it is now implemented (three steps,
`RUNNER_TEMP` install, pinned installer and versions, `pipx`, `github-token`, strict
booleans, fixtures and negative tests). This document judges the **current** state and
proposes the next target. Breaking changes are accepted; the target release is `v0.1.0`
(the last tag is `v0.0.3`).

## 1. Properties of the action

These come from `CLAUDE.md`, `README.md` and `SECURITY.md`. The target state is judged
against them.

| #   | Property                      | Meaning                                                                                                                     |
| --- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| P1  | Single purpose                | Lint and security-scan GitHub workflow files with actionlint and zizmor. Nothing else.                                      |
| P2  | Composite, no code of its own | All logic is `bash` in `action.yaml`. No scripts, Docker, JS or build step. Three steps: `Prepare`, `actionlint`, `zizmor`. |
| P3  | Portable                      | Linux and macOS runners (x64 and ARM), `shell: bash`, GNU and BSD tools, bash 3.2.                                          |
| P4  | Safe by construction          | Inputs reach scripts only through `env:`. Flags are tokenized with `xargs`, never `eval`ed.                                 |
| P5  | Supply-chain aware            | Nothing is executed from a moving ref. Default tool versions are exact. Downloads are verifiable.                           |
| P6  | Zero config                   | `uses:` with no `with:` works on a checked-out repo.                                                                        |
| P7  | Independent tools             | Each tool can be disabled. Disabling both is a successful no-op.                                                            |
| P8  | Fail loudly and completely    | Any finding, bad input or install failure fails the action with a clear message. One run reports **all** problems.          |
| P9  | Clean workspace               | Tools live in `RUNNER_TEMP`. `git status` stays clean.                                                                      |
| P10 | Fast                          | Few steps, no redundant work, minimal downloads.                                                                            |
| P11 | Self-verifying                | Every input and every failure path is exercised in CI, and the tests can only pass for the right reason.                    |
| P12 | Immutable releases            | Exact version tags only. No floating tags.                                                                                  |

P8 now has "completely" because of finding 2 below.

## 2. Findings on the current state

Ordered by impact. Items marked **(verified)** were reproduced locally; everything else
is from reading the code.

### Bugs

1. **`ci-action.yaml` `test-inputs` is broken (verified).** It passes
   `paths: ".github/workflows/*.yaml"`, but the action no longer expands globs. Locally,
   `actionlint '.github/workflows/*.yaml'` prints `could not read … no such file` and
   zizmor prints `invalid input: …` with `fatal: no audit was performed`. This job fails
   as soon as CI runs. The README says "no glob expansion", so the test contradicts the
   documented contract. It also means no CI job currently covers the `paths` plus custom
   versions plus flags combination. Fix: use explicit newline-separated files.
2. **`nightly-test-released.yaml` is stale.** It uses `version:` and `flags:`, which no
   longer exist in the current inputs, and the glob path. It works only because it pins
   `v0.0.3`. After the `v0.1.0` release, it would fail. It also has no negative test,
   so the nightly cannot detect a released "always green" regression. `CLAUDE.md` says
   to mirror the cases once released; only the two simplest ones exist.
3. **Download errors are masked (P8).** `bash <(curl -fsSL "$installer")` uses process
   substitution. If `curl` fails, `bash` receives an empty script and exits 0, and
   `pipefail` does not see the failure. The step then fails later with
   `actionlint: No such file`, hiding the real cause. The `> /dev/null` also hides the
   installer's own output.

### Violations of the properties

4\. **P8: the first failing tool hides the second.** The `zizmor` step has the default
`if: success()`. When actionlint reports a finding, zizmor never runs, so the user
fixes one tool, pushes, and only then sees the other tool's findings. Two CI
round trips instead of one, for a slow-feedback gate.

5\. **P11: negative tests can pass for the wrong reason.** `test-failure-os` and
`test-fixtures` only check that the outcome is `failure`. A failed install, a missing
`pipx` or a typo would also yield `failure` and the test stays green. Only the
positive `test` job proves the install works, and nothing ties the two together on
one OS. The action should make the cause assertable.

6\. **P5: not all downloads are verified, and some references still move.**

- The actionlint archive is not checksum-verified (documented in `SECURITY.md`).
  `actionlint_<v>_checksums.txt` is published next to every archive, so the check is
  cheap now that versions are pinned.
- `pipx run zizmor==X` pins zizmor but not its transitive dependencies, and has no
  hashes.
- `ci-format.yaml` uses `node-version: "latest"` and `bot-pin-action.yaml` installs
  "the latest ratchet". These are repo tooling, not the shipped action, so they are
  lower risk, but they make CI results time-dependent.
- The `Makefile` `zizmor` target still runs an unpinned `pip3 install --user zizmor`
  when zizmor is missing, which also fails on PEP 668 Pythons. `make install-zizmor`
  (in `.make/actions.mk`) now exists and is the supported way to install it.

7\. **P11/P12: documentation promises a release that does not exist.** `README.md` has a
"Migration to v0.1.0" section and `SECURITY.md` lists `0.1.x` as supported, while the
latest tag is `v0.0.3` and the README examples pin `v0.0.3`. This is accepted by
`CLAUDE.md` (README examples change only on release), but the migration section needs a
visible "unreleased" marker so users on `v0.0.3` do not read it as current behaviour.

### Smaller points

8\. `README.md` and `action.yaml` link `woodruffw/zizmor`. The project moved to
`zizmorcore/zizmor` (the GitHub API resolves it). Update the links.

9\. The two flag/path parsing blocks are duplicated between the `actionlint` and `zizmor`
steps (about 15 lines each). This is inherent to composite actions without scripts
(P2) and is small. Keep it, but keep both blocks byte-identical so a diff shows any
divergence.

10\. `README.md` states `bash` as a requirement only; the actionlint installer also needs
`curl` and `tar`. They are present on every hosted runner;
self-hosted runners need them. One line in Requirements.

11\. `action.yaml` description fields use folded `>` with long lines. Fine, but the
`paths` description should say explicitly that glob patterns are **not** expanded
(the README does, the input does not), since the input description is what
the Marketplace shows.

## 3. Target design

### 3.1 Interface

Almost unchanged. The interface is already small and consistent with the README.

| Input                | Default  | Change                                                         |
| -------------------- | -------- | -------------------------------------------------------------- |
| `paths`              | `""`     | Unchanged. Description gains "glob patterns are not expanded". |
| `actionlint`         | `"true"` | Unchanged.                                                     |
| `actionlint-version` | exact    | Unchanged. Bumped on release.                                  |
| `actionlint-flags`   | `""`     | Unchanged.                                                     |
| `zizmor`             | `"true"` | Unchanged.                                                     |
| `zizmor-version`     | exact    | Unchanged. Bumped on release.                                  |
| `zizmor-flags`       | `""`     | Unchanged.                                                     |
| `github-token`       | `""`     | Unchanged (opt-in). See decision D2 below.                     |

No new inputs, no outputs, no renames. The target release is therefore only
breaking relative to `v0.0.3`, as already described in the migration section.

**Decisions** (each has a recommendation; none needs input to proceed):

- **D1: run both tools, report both (finding 4). Recommended: yes.** Change the
  `zizmor` step condition so it runs after a failed actionlint, and keep the action's
  overall result failed. Cost: one `if:` expression. A failed `Prepare` must still skip
  both tools (`steps.prepare.outcome == 'success'`). Behaviour change: on a failing
  repo the zizmor step now runs, so the log is longer, but the user sees everything in
  one run. Flag it in the migration notes.
- **D2: keep `github-token` opt-in, do not default it to `${{ github.token }}`.**
  Online audits query the GitHub API, so the result depends on external state. That
  weakens P5 and P6 ("same tag, same result"). Users who want the audits add one line.
- **D3: keep `pipx`, do not switch to the zizmor release binaries.** GitHub releases
  have binaries for Linux (x64 and ARM64) and macOS (x64 and ARM64). That would need
  per-OS archive naming (about 30 lines). `pipx` is preinstalled and works on all of them.
- **D4: keep the actionlint download script, but fetch it to a file and verify the
  archive checksum.** Alternative considered: skip the script and download the archive
  directly. That needs per-OS naming (`darwin`/`linux`, `amd64`/`arm64`,
  `.tar.gz`), which the script already handles. Keep the script.

### 3.2 Implementation

The structure stays: `Prepare`, `actionlint`, `zizmor` (P2). Changes:

1. **`Prepare`** gets `id: prepare`, so later steps can condition on it. No other change.
2. **`actionlint` step: download then run, no process substitution (finding 3).**

   ```bash
   installer="$RUNNER_TEMP/verify-workflows/download-actionlint.bash"
   curl -fsSL -o "$installer" "$ACTIONLINT_INSTALLER_URL"   # fails loudly, set -e applies
   bash "$installer" "$ACTIONLINT_VERSION" "$bin_dir"       # output kept in the log
   ```

   Keep the installer URL pinned to the commit SHA. Drop `> /dev/null`: the installer
   prints one line, and the log should show what was installed.

3. **Checksum verification (finding 6), optional but recommended for `v0.1.0`.** When
   `ACTIONLINT_VERSION` is not `latest`, the script downloads `actionlint_<v>_<os>_<arch>`.
   Verifying requires knowing which archive it fetched, which the script does not expose.
   So this is only simple if the action downloads the archive itself, which conflicts
   with D4. Decision: **do not implement checksums in this round.** Keep the documented
   limit in `SECURITY.md`. Revisit if actionlint publishes artifact attestations, which
   would allow `gh attestation verify` in one line. Unverified, check before relying on
   it.
4. **`zizmor` step condition (D1):**

   ```yaml
   if: ${{ !cancelled() && steps.prepare.outcome == 'success' && inputs.zizmor == 'true' }}
   ```

   The `actionlint` step gets the same shape for its own input, so the two stay symmetric
   and disabling one never changes the other.

5. **Make failure causes assertable (finding 5) without adding an output.** Keep the
   interface free of outputs (P1). Structure the tests so the cause is implied: each
   negative run happens in the same job, on the same runner, right after a positive run
   with the same inputs on the valid fixture. If the install were broken, the positive
   step would fail first, so a failing negative step can only come from a finding.
   For D1 (both tools run), each tool step ends by creating a marker file
   `$RUNNER_TEMP/verify-workflows/ran-<tool>` (one `touch` line, only after the tool
   was started), which the test job checks. It lives in `RUNNER_TEMP`, so P9 holds.

6. **Everything else in `action.yaml` stays**: `xargs` tokenization, `${arr[@]+...}`,
   `--format=github` unless the user passes `--format`, `GH_TOKEN` unset when empty,
   strict booleans.

### 3.3 Step condition skeleton

```yaml
runs:
  using: composite
  steps:
    # Validate booleans and create the private tool directory
    - name: Prepare
      id: prepare
      shell: bash
      # ... unchanged ...

    # Download the pinned installer to a file (curl errors fail the step), install
    # actionlint in the tool directory, run it
    - name: actionlint
      if: ${{ !cancelled() && steps.prepare.outcome == 'success' && inputs.actionlint == 'true' }}
      shell: bash
      # ... download to file, then run ...

    # Run zizmor through pipx even if actionlint failed, so one run reports both tools
    - name: zizmor
      if: ${{ !cancelled() && steps.prepare.outcome == 'success' && inputs.zizmor == 'true' }}
      shell: bash
      # ... unchanged ...
```

## 4. Tests and CI

Layout stays: `ci.yaml` calls `lib-get-test-matrix`, `ci-format`, `ci-action`;
`nightly.yaml` calls `nightly-test-released`; `ci-verify-workflows` is standalone.

1. **Fix `test-inputs` (finding 1).** Replace the glob with explicit files:

   ```yaml
   paths: |
     .github/workflows/ci.yaml
     .github/workflows/ci-action.yaml
   ```

   Keep the custom versions (`actionlint-version`, `zizmor-version`) and flags. Update the
   stale zizmor pin (`1.29.0`) to an exact older version that is still intentionally
   different from the default, and say so in a comment.

2. **Add a test for D1.** Run the action with `continue-on-error: true` on both
   `actionlint-error.yaml` and `zizmor-error.yaml` (two lines in `paths`). Then assert
   that the outcome is `failure` and that both marker files
   `ran-actionlint` and `ran-zizmor` exist. Without D1 the zizmor marker is missing, so
   this test fails on the current action.
3. **Negative tests that cannot pass for the wrong reason (finding 5).** In
   `test-failure-os` and `test-fixtures`, put a positive run (valid fixture, expected
   success) in the same job, before the negative run. Both use the same runner and
   inputs, so an install problem would fail the positive step first.
4. **Mirror in `nightly-test-released.yaml` at release time.** After tagging `v0.1.0`:
   same OS matrix, `test-inputs` with the new input names, the valid, actionlint-error
   and zizmor-error fixtures, a space-in-path case and the workspace-clean check. Until
   then, keep the `v0.0.3`-valid job as is, but fix its comment so it is not described as
   a mirror of the current inputs.
5. **Keep `test-paths`, `test-latest-and-format`, `test-github-token`, the disabled
   jobs, and the workspace-clean assertion.** They are correct.
6. **Repo tooling pins (finding 6).** Replace `node-version: "latest"` in
   `ci-format.yaml` with an exact LTS major. Keep the ratchet bot installing the latest
   ratchet, since it only rewrites SHAs and opens a PR for review.
7. **Makefile.** Make the `zizmor` target depend on `install-zizmor` and delete its inline
   `pip3 install --user` fallback. Contributors install the tool with
   `make install-zizmor` (or `make install-tools`).

## 5. Documentation target

1. `README.md`: mark "Migration to v0.1.0" as "Unreleased: applies when upgrading from
   `v0.0.3`". Add the D1 behaviour change (both tools always run) to it. Add
   `curl` and `tar` to Requirements for self-hosted runners.
   Update zizmor links to `zizmorcore/zizmor`. Say in the `paths` row that globs are not
   expanded (already there), and mirror it in the input description in `action.yaml`.
2. `SECURITY.md`: change the supported versions table to match real tags (`0.0.x` now,
   add `0.1.x` at release). Keep the "no checksum verification" note; add that the
   installer is downloaded to a file before it is run.
3. `CLAUDE.md`: record the new rules: both tools run even when one fails (the `if:`
   shape above); the installer is downloaded to a file, never run through process
   substitution; negative tests need a positive run on the same runner; `test-inputs`
   must not use globs; marker files are a test hook. (`os_unix` is the config key and
   `os_matrix` the exposed output; `CLAUDE.md` already says so.)
4. `.github/PULL_REQUEST_TEMPLATE.md`: unchanged.

## 6. Deliberately not changing

- Composite action with bash and the three-step structure (P2).
- Two tools in one action. A split would double the usage boilerplate.
- `xargs` tokenization and `paths` handling (P4). Already safe and portable.
- No outputs. The exit status is the signal. SARIF upload stays out of scope; users can
  pass `--format=sarif` via `zizmor-flags`.
- `pipx` for zizmor (D3) and the pinned installer script for actionlint (D4).
- `github-token` stays opt-in (D2).
- zizmor's default target stays `.github/workflows`. Scanning `.` would also audit
  `action.yaml` and Dependabot files. That is useful, but widens the scope past
  "verify workflows" (P1). Users can add `paths` or flags themselves.
- No version-bumping bot in this round. Dependabot does not see the pins in `action.yaml`
  (inputs defaults and a SHA in a URL), so the release checklist stays manual.

## 7. Rollout order

One PR per logical change, branched from an up-to-date `main`, per `CLAUDE.md`:

1. `bugfix/`: fix `test-inputs` (explicit paths) and the stale nightly comment. This
   fixes CI immediately and is independent of the rest.
2. `test/`: positive-before-negative structure in `test-fixtures` and `test-failure-os`,
   plus the combined-fixture test for D1 (it fails on the current action, which proves
   it is meaningful).
3. `refactor/`: download the installer to a file, keep its output, add `id: prepare`
   and the `!cancelled()` conditions (D1). One PR because the test from step 2 turns
   green with it.
4. `ci/` and `chore/`: pin the Node version in `ci-format.yaml`, make the Makefile
   `zizmor` target use `make install-zizmor`.
5. `docs/`: README, SECURITY.md, CLAUDE.md as listed in section 5.
6. Release `v0.1.0`: bump the defaults if newer tools exist (current: actionlint 1.7.12
   and zizmor 1.32.0 are the latest, and the installer SHA `914e7df…` is the `v1.7.12`
   tag), tag, then update the pinned version in `README.md`, `ci-verify-workflows.yaml`
   and `nightly-test-released.yaml`, and extend the nightly with the mirrored cases.

## 8. Verification status and open points

Checked locally:

- Glob paths fail in both actionlint and zizmor (finding 1).
- Latest releases: actionlint `v1.7.12` (installer SHA matches the tag), zizmor `v1.32.0`.
  The defaults in `action.yaml` are current.
- zizmor release assets cover Linux x64/ARM64 and macOS x64/ARM64 (D3).

Not verified:

- Nothing here was run in GitHub Actions; workflows cannot be run locally, and no check
  (`make format`, `make zizmor`) was run, because only `review/target_state.md` changed.
  CI was not awaited.
- Whether the `!cancelled()` condition behaves identically for composite-step `if:` on
  all three OSes. It is standard expression syntax, but the combined-fixture test in
  section 4 is the proof, and it should be run before release.
- Whether actionlint publishes artifact attestations (would simplify checksum or
  provenance verification).
- Existing failures on `main`: `test-inputs` is expected to fail (finding 1). I did not
  confirm it by a CI run.
