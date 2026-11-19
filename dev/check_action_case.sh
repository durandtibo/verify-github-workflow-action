#!/usr/bin/env bash
#
# Check the result of one case of the action tests (used by ci-action.yaml, for the local
# action and for the released action, so that both runs assert the same thing).
#
# The cases are in tests/action_cases.json; this script checks one of them after the action ran.
#
# Environment variables (passed through env:, never interpolated in a script):
#   CASE           The case, as a JSON object of tests/action_cases.json
#   OUTCOME        The outcome of the step that ran the action (success or failure)
#   CHECK_MARKERS  "true" to check the ran-<tool> marker files (the pinned release may not
#                  create them yet), anything else to skip that check
#   RUNNER_TEMP    Where the action installs the tools and leaves the markers
#
# A case has "expect" (the outcome: success, failure, or any when only the side effects
# matter) and, optionally:
#   "markers": which tools started, from their ran-<tool> marker (both, actionlint, zizmor
#              or none)
#   "actionlint-version": the exact version that is installed after the run
# For every case the checkout must be clean (the action installs in RUNNER_TEMP) and no
# file named "pwned" exists (shell syntax in the flags must never be executed).
#
# Exit codes:
#   0 - The case passed
#   1 - At least one problem (each one is reported as an ::error:: on stderr)

set -euo pipefail

errors=0
fail() {
	echo "::error::[$id] $*" >&2
	errors=1
}

check_markers() {
	local want actionlint=absent zizmor=absent dir
	want=$(jq -r '.markers // empty' <<<"$CASE")
	[ -n "$want" ] || return 0
	dir="${RUNNER_TEMP:?RUNNER_TEMP must be set}/verify-workflows"
	[ ! -e "$dir/ran-actionlint" ] || actionlint=present
	[ ! -e "$dir/ran-zizmor" ] || zizmor=present
	case "$want" in
	both) [ "$actionlint $zizmor" = "present present" ] || fail "Both tools must have started (actionlint $actionlint, zizmor $zizmor)" ;;
	actionlint) [ "$actionlint $zizmor" = "present absent" ] || fail "Only actionlint must have started (actionlint $actionlint, zizmor $zizmor)" ;;
	zizmor) [ "$actionlint $zizmor" = "absent present" ] || fail "Only zizmor must have started (actionlint $actionlint, zizmor $zizmor)" ;;
	none) [ "$actionlint $zizmor" = "absent absent" ] || fail "No tool must have started (actionlint $actionlint, zizmor $zizmor)" ;;
	*) fail "Unknown markers value '$want'" ;;
	esac
}

check_version() {
	local want got
	want=$(jq -r '.["actionlint-version"] // empty' <<<"$CASE")
	[ -n "$want" ] || return 0
	got=$("$RUNNER_TEMP/verify-workflows/bin/actionlint" -version | head -n 1)
	[ "$got" = "$want" ] || fail "The installed actionlint must be $want (got '$got')"
}

check_workspace() {
	local status
	status=$(git status --porcelain)
	[ -z "$status" ] || fail "The checkout must stay clean (got: $status)"
	[ ! -e pwned ] || fail "Shell syntax in the flags was executed (the file pwned exists)"
}

main() {
	local expect
	id=$(jq -r '.id' <<<"${CASE:?CASE must be set}")
	expect=$(jq -r '.expect' <<<"$CASE")

	if [ "$expect" != "any" ] && [ "${OUTCOME:-}" != "$expect" ]; then
		fail "The outcome must be '$expect' (got '${OUTCOME:-}')"
	fi
	if [ "${CHECK_MARKERS:-}" = "true" ]; then check_markers; fi
	check_version
	check_workspace
	[ "$errors" -eq 0 ] || return 1
	echo "✅ Case $id: outcome ${OUTCOME:-}"
}

main "$@"
