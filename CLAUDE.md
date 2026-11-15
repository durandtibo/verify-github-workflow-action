# CLAUDE.md

Guidance for coding agents working in this repository.

## Repository purpose

A GitHub composite action (`action.yaml`) that verifies GitHub workflow files with
[actionlint](https://github.com/rhysd/actionlint) and
[zizmor](https://github.com/woodruffw/zizmor). There is no separate script: all logic lives in the
bash steps of `action.yaml` (they must work on Linux, macOS and Windows runners with `shell: bash`).
It is tested by running the action itself in workflows (`ci-action.yaml`,
`nightly-test-released.yaml`); there is no unit test suite.

## Environment

- Use the `Makefile`; run `make help` to list targets (`make format`, `make format-markdown`,
  `make format-yaml`, `make zizmor`).
- Run `make format` before committing. It runs markdownlint, prettier (which rewrites files) and
  yamllint. Fix what they report instead of disabling rules (config: `.markdownlint.json`,
  `.yamllint.yaml`).
- `make zizmor` applies autofixes to `.github/workflows`; review the diff it produces.
- Workflows cannot be run locally. Say so in the PR instead of claiming they pass.

## Git workflow

- One branch and one PR per logical change, branched from an up-to-date `main`. Never commit or
  push to `main`.
- Name branches `<type>/<short-description>` in kebab-case, with type one of: `feat`, `bugfix`,
  `hotfix`, `docs`, `refactor`, `perf`, `test`, `chore`, `ci`.
- PR descriptions follow `.github/PULL_REQUEST_TEMPLATE.md` and cover what changed, what was
  deliberately left alone, and any behaviour change.
- On conflicts with `main`, merge `origin/main` into the branch; do not rebase and force-push.
- Update `README.md` when inputs, behaviour, or workflows change.
- Releases are immutable exact version tags (`v0.0.3`, ...). Do not create or move floating tags
  (`v1`, `latest`) and do not document them as an option. Update the version in `README.md`
  examples only as part of a release.

## Action rules (`action.yaml`)

- Keep input names, defaults, and descriptions consistent with `README.md`. Renaming or removing
  an input is a breaking change and must be flagged.
- Pass inputs to scripts through `env:`, never by interpolating `${{ inputs.* }}` in `run:`.
- Every `run:` step sets `shell: bash` and starts with `set -euo pipefail`.
- Free-form flag inputs (`actionlint-flags`, `zizmor-flags`) are tokenized with `xargs`, never
  `eval`ed, so they cannot be used for command injection. Keep it that way.
- Stay portable between GNU and BSD tools (`xargs`, `date`, `sed`, etc.) and across runner OSes;
  an empty flags value must produce zero arguments.
- Each step has a `name:` and a comment saying what it does.
- Code in `run:` blocks must stay clean under `shellcheck`; justify any `# shellcheck disable`.

## Workflow structure (`.github/workflows/`)

- Files are prefixed by their role: `ci-`, `nightly-`, `lib-`, `bot-`, `security-`.
- `ci.yaml`: entry point for pull requests, pushes to `main`, a nightly schedule and manual runs. It
  holds no steps, only jobs that call the reusable workflows below. It tests the current checkout.
  - `lib-get-test-matrix.yaml`: loads the OS matrix (`os_all`) from
    `durandtibo/workflow-config-action` once; callers pass it down to the test workflows. Never
    hardcode the OS list.
  - `ci-format.yaml`: markdownlint/prettier and yamllint checks.
  - `ci-action.yaml`: runs the action from this checkout (the version not released yet) on the
    full OS matrix and with different input combinations (custom versions and flags, actionlint
    disabled, zizmor disabled, both disabled).
- `ci-verify-workflows.yaml`: verifies this repo's workflows with the latest released action. It
  has its own triggers and is deliberately not called from `ci.yaml`.
- `nightly.yaml`: scheduled entry point that tests the latest released action.
  - `nightly-test-released.yaml`: runs the latest released action (pinned, update it on release).
- `security-dependency-review.yaml`: dependency review on pull requests.
- `bot-pin-action.yaml`: scheduled automation that pins actions to SHAs with ratchet and opens a PR.
- `bot-cancel-stale-queued-runs.yaml`: scheduled automation that cancels stale queued runs.

Conventions:

- Pin third-party actions to commit SHAs with a `# ratchet:<owner>/<repo>@<tag>` comment, never to
  tags or branches. Dependabot (`.github/dependabot.yml`) bumps them.
- Set least-privilege `permissions` (workflow level `permissions: {}` or `contents: read`, widened
  per job only when needed) and `timeout-minutes` on every job. Use `persist-credentials: false` on
  checkout.
- Reusable checks are `workflow_call` workflows that also have `workflow_dispatch`, so they can be
  run alone. Add a new check as a new workflow plus a job in `ci.yaml` (or `nightly.yaml` for
  released-version checks).
- Do not interpolate untrusted values (`github.event.*`, inputs) in `run:`; use `env:`.
- Workflows must pass the action's own checks (actionlint and zizmor), since this repo verifies
  itself.
- Start each workflow with a comment saying what it does, and update it when behaviour changes.

## Tests

- Every new or changed input needs a job in `ci-action.yaml` exercising it (including the
  disabled and default paths). Mirror the relevant case in `nightly-test-released.yaml` once released.
- Keep the OS matrix in both test workflows identical (it comes from `lib-get-test-matrix.yaml`).
- Every bug fix needs a test case that fails without the fix.
- If a check fails for a real reason, report it rather than weakening the test or the linters.

## Reporting

- State which checks ran (`make format`, `make zizmor`) and which did not.
- Note that CI was not awaited, and that the workflows could not be run locally.
- Report failures that already exist on `main` rather than hiding them.
