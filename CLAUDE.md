# CLAUDE.md

Guidance for coding agents working in this repository.

## Repository purpose

A GitHub composite action (`action.yaml`) that verifies GitHub workflow files with
[actionlint](https://github.com/rhysd/actionlint) and
[zizmor](https://github.com/zizmorcore/zizmor). There is no separate script: all logic lives in the
bash steps of `action.yaml` (they must work on Linux and macOS runners with `shell: bash`;
Windows is not supported and not tested).
It is tested by running the action itself in workflows (`ci-action.yaml`, called by `ci.yaml`
and `nightly.yaml`) on the cases of `tests/action_cases.json` and the fixtures in `tests/fixtures/`;
there is no unit test suite.
`dev/` holds maintainer helpers (`check_action_case.sh`, `check_readme_sync.sh`) and
`review/target_state.md` is a review of the action against its properties; none of them is part of
the action.

## Environment

- Use the `Makefile`; run `make help` to list targets (`make format`, `make lint`,
  `make lint-actions`, `make zizmor`, `make test`, ...). `make test` only runs
  `make check-readme-sync`: the action itself is tested by CI.
- Do not edit `.make/`: it is a shared directory synced by `bot-sync-shared-makefile.yaml`.
- Run `make format` and `make lint` before committing. Fix what they report instead of disabling
  rules (config: `.markdownlint.json`, `.yamllint.yaml`). `make format` rewrites files.
- `make zizmor` applies autofixes to `.github/workflows`; review the diff it produces.
- Workflows cannot be run locally (the action itself is only exercised by CI). Say so in the PR
  instead of claiming they pass.

## Git workflow

- One branch and one PR per logical change, branched from an up-to-date `main`. Never commit or
  push to `main`.
- Name branches `<type>/<short-description>` in kebab-case, with type one of: `feat`, `bugfix`,
  `hotfix`, `docs`, `refactor`, `perf`, `test`, `chore`, `ci`.
- Write commit messages and PR titles as a short imperative sentence starting with a verb such as
  `Add`, `Fix`, `Update`, `Remove` or `Improve`. Do not use conventional-commit prefixes like
  `docs:` or `feat:` (the type prefix is only for branch names). The squash-merge appends the PR
  number, so do not add one.
- PR descriptions follow `.github/PULL_REQUEST_TEMPLATE.md` and cover what changed, what was
  deliberately left alone, and any behaviour change.
- Do not escape special characters such as the backtick (`` ` ``) in PR titles and descriptions
  (no `\``): the escape characters are not rendered well. Write them as plain Markdown.
- On conflicts with `main`, merge `origin/main` into the branch; do not rebase and force-push.
- Update `README.md` when inputs, behaviour, or workflows change.
- Releases are immutable exact version tags (`v0.0.3`, ...). Do not create or move floating tags
  (`v1`, `latest`) and do not document them as an option. Update the version in `README.md`
  examples only as part of a release.
- Release checklist: bump the default `actionlint-version` and `zizmor-version` in `action.yaml`
  and `README.md` (and the pinned installer SHA if actionlint changes), tag, then update the
  pinned version in `README.md`, `ci-verify-workflows.yaml` and `ci-action.yaml` (the released action
  steps), flip `"released"` to `true` in `tests/action_cases.json` for the cases the release
  supports, and update the input defaults duplicated in the `with:` blocks of `ci-action.yaml`.

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
- Structure: three steps (`Prepare`, `actionlint`, `zizmor`); each tool step installs and runs.
  Keep it that way.
- The tool steps use
  `if: ${{ !cancelled() && steps.prepare.outcome == 'success' && inputs.<tool> == 'true' }}`,
  so both tools run even when one fails and one run reports all problems. A failed `Prepare`
  skips both. Keep the two conditions symmetric.
- The actionlint installer is downloaded to a file (`curl -fsSL -o`) and then run, never run
  through process substitution (`bash <(curl ...)`), which hides download errors.
- Each tool step touches `$RUNNER_TEMP/verify-workflows/ran-<tool>` just before starting the
  tool. This is a test hook (see Tests); keep it.
- Tools are installed under `RUNNER_TEMP`, never in the workspace. The action must leave
  `git status` clean.
- `paths` is newline-separated and read line by line, never word-split or globbed. Use the
  `${arr[@]+"${arr[@]}"}` form for possibly empty arrays (bash 3.2 on macOS), and no bash 4
  syntax (`${var^^}`, `${!var}`, `mapfile`, ...).
- Never execute anything from a moving ref: the actionlint installer is pinned to a commit SHA,
  and the default tool versions are exact. Releasing bumps them (see below).
- Only ship what the action needs at runtime: it is self-contained in `action.yaml` and downloads
  its tools. Never make it read tests, fixtures or other repo files of this repository, because
  consumers only get `action.yaml`, and `uses: ./` runs the whole checkout and hides a missing file.
  There is no `.gitattributes`: the action has no script to export, so a new file the action reads
  would be a design change to flag.
- `github-token` reaches zizmor as `GH_TOKEN` through `env:`; unset it when empty. zizmor gets
  `--format=github` unless the flags contain `--format`.
- `actionlint` and `zizmor` accept only `true` or `false`; anything else fails.

## Workflow structure (`.github/workflows/`)

- Files are prefixed by their role: `ci-`, `nightly-`, `lib-`, `bot-`, `security-`.
- `ci.yaml`: entry point for pull requests, pushes to `main`, a nightly schedule and manual runs. It
  holds no steps, only jobs that call the reusable workflows below. It tests the current checkout.
  - `lib-get-test-matrix.yaml`: loads the OS and Python lists from
    `durandtibo/workflow-config-action` once and exposes them in the `test_matrix` JSON output
    (`os_matrix`, `os_macos`, `os_latest`, `python_versions`, `python_versions_standard`); callers
    pass it down to the test workflows. Never hardcode an OS or a Python version. The action does
    not depend on the user's Python, so no job crosses `python_versions`.
  - `ci-format.yaml`: read-only markdownlint and yamllint checks (`make lint-markdown`,
    `make lint-yaml`).
  - `ci-action.yaml`: one reusable workflow with a boolean input `use-released` (default `false`).
    `ci.yaml` calls it with `false` (the action from this checkout, not released yet);
    `nightly.yaml` calls it with `true` (the latest release, pinned). The `test` job runs the
    default usage on `os_matrix`. The cases of `tests/action_cases.json` run one per matrix cell:
    the rows with `"os": "matrix"` on `os_matrix`, the rows with `"os": "latest"` on `os_latest`,
    the others on `ubuntu-latest`. `get-cases`
    turns the file into one matrix cell per case and runner (one `test-cases` job);
    `dev/check_action_case.sh` asserts one case. The header of the workflow counts the cells.
  - `ci-docs.yaml`: `make check-readme-sync` (`dev/check_readme_sync.sh`) compares the inputs and
    defaults of `README.md` with `action.yaml`.
- `ci-verify-workflows.yaml`: verifies this repo's workflows with the latest released action. It
  has its own triggers and is deliberately not called from `ci.yaml`.
- `nightly.yaml`: scheduled entry point that calls `ci-action.yaml` with `use-released: true`. It
  is not part of `ci.yaml`.
- `security-dependency-review.yaml`: dependency review on pull requests.
- `bot-pin-action.yaml`: scheduled automation that pins actions to SHAs with ratchet and opens a PR.
- `bot-cancel-stale-queued-runs.yaml`: scheduled automation that cancels stale queued runs.
- `bot-format-files.yaml`: weekly automation that formats the files and opens a PR.
- `bot-sync-shared-makefile.yaml`: weekly automation that syncs the `.make` subtree
  (`durandtibo/shared-makefiles`) and opens a PR.
- `security-scorecard.yaml`: OpenSSF Scorecard analysis (feeds the README badge).

Conventions:

- Pin third-party actions to commit SHAs with a `# ratchet:<owner>/<repo>@<tag>` comment, never to
  tags or branches. Dependabot (`.github/dependabot.yml`) bumps them.
- Every workflow has `permissions: {}` at the workflow level (it grants nothing), never a grant.
  Set least-privilege `permissions` on every job, including jobs that call a reusable workflow, and
  `timeout-minutes` on every job. Use `persist-credentials: false` on checkout.
- Put `make` targets in the steps rather than duplicating commands, so local runs and CI match.
- Reusable checks are `workflow_call` workflows that also have `workflow_dispatch`, so they can be
  run alone. Add a new check as a new workflow plus a job in `ci.yaml` (or `nightly.yaml` for
  released-version checks).
- Do not interpolate untrusted values (`github.event.*`, inputs) in `run:`; use `env:`.
- Workflows must pass the action's own checks (actionlint and zizmor), since this repo verifies
  itself.
- Start each workflow with a comment saying what it does, and update it when behaviour changes.

## Tests

- Fixtures live in `tests/fixtures/` (outside `.github/workflows`, so they are never run or
  self-checked): `valid/ok.yaml`, `actionlint-error.yaml` (rejected by actionlint only),
  `zizmor-error.yaml` (rejected by zizmor only), `dir with space/ok.yaml`. Keep each bad fixture
  failing for exactly one tool.
- A negative test needs a positive run (valid fixture, expected success) on the same runner
  before it, so an install problem fails there and the negative run cannot pass for the
  wrong reason.
- A new case is a row of `tests/action_cases.json`, not a new job: `id`, `inputs`, `expect`
  (`success`, `failure`, or `any` when only the side effects matter), `markers` (which tools must
  have started, from their `ran-<tool>` files), `released`, and optionally `os` (`matrix` for
  general behaviour that must work on every OS, `latest` when the case depends on the OS),
  `setup` (a fixture copied into `.github/workflows` for the default discovery) and
  `actionlint-version` (the installed version). `paths` uses explicit
  newline-separated files, never globs (they are not expanded).
- The assertions live in `dev/check_action_case.sh`, shared by the local and the released runs:
  outcome, markers, installed version, clean `git status`, no `pwned` file (flag injection).
- Failure paths are tested with `continue-on-error: true`, an `id`, and a step asserting
  `steps.<id>.outcome`.
- Every new or changed input needs a row in `tests/action_cases.json` exercising it (including the
  disabled, default and invalid-value paths). A row has `"released": false` until the pinned
  release has the feature (the released run skips it).
- There is one test workflow for both versions (`use-released`); the OS and Python lists come only
  from `lib-get-test-matrix.yaml`.
- Each job has one action step per version, `uses: ./` with `if: ${{ !inputs.use-released }}` and
  the pinned release with `if: ${{ inputs.use-released }}`, and one shared verify step. The
  assertions live in `dev/check_action_case.sh`, never duplicated in two workflows.
- Keep the README inputs and defaults in step with `action.yaml` (`make check-readme-sync`,
  run by `ci-docs.yaml`).
- Cover success, failure and edge cases (empty or invalid input, paths with spaces, an empty flags
  value) with one behaviour per case.
- Every bug fix needs a test case that fails without the fix.
- If a check fails for a real reason, report it rather than weakening the test or the linters.

## Testing strategy

The strategy is the same for all the action repositories of `durandtibo`. The properties the action
must keep are reviewed in `review/target_state.md`. This repository follows
it with the layout below (there is no script, so there is no level 1 with mocks, and no Python
dimension: the action does not run in the user's Python).

Levels:

1. **Local action**: the action from this checkout (`uses: ./`) in a real workflow
   (`ci-action.yaml`, called by `ci.yaml`, on pull requests, pushes and the schedule).
2. **Released action**: the latest stable release, pinned, with the same cases as level 1
   (the same `ci-action.yaml` with `use-released: true`, called by `nightly.yaml`). Never run it
   on pull requests.

Rules:

- Test a behaviour at the cheapest level that can show it. The action tests check the contract and
  the wiring: inputs reach the tools, the action fails on an invalid input or a finding. Do not
  re-test what actionlint or zizmor already do.
- Split the tests in two. **General behaviour** (default usage, failure detection, flag
  tokenization, which differ per OS) runs on the full `os_matrix`. **Edge cases** (one input, one
  invalid value, an unusual path) run on one runner (`ubuntu-latest`). There is no reduced matrix
  on pull requests.
- Never write an OS in a workflow: read the list through `lib-get-test-matrix.yaml`.
- Every input has a case with an invalid or unknown value that asserts the action failed (boolean
  `yes`, version `0.0.0`, unknown flag, missing path). It proves the input reached the tool.
  Assert an outcome, a marker file or the installed version, never just print them, and never
  assert on a log message.
- Failure paths use `continue-on-error: true`, an `id`, and a step that asserts `steps.<id>.outcome`.
  A negative test needs a positive run on the same runner before it, so it cannot pass for the
  wrong reason.
- Tests have no side effect outside the runner: use throwaway files, and check that `git status`
  stays clean when the case could write into the workspace. If something cannot be tested in CI,
  write down which check covers it.
- Set `timeout-minutes` on every job and `fail-fast: false` on matrix jobs.

## Reporting

- State which checks ran (`make format`, `make lint`, `make zizmor`, `make test`) and which did not.
- Note that CI was not awaited, and that the workflows could not be run locally.
- Report failures that already exist on `main` rather than hiding them.
