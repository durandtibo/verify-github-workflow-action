#!/usr/bin/env bash
#
# Check that action.yaml and README.md describe the same inputs, with the same defaults.
# Nothing else checks it: a renamed input or a changed default would pass every other test.
#
# The files are parsed with awk (no YAML library is needed) and the script stays portable
# between GNU and BSD tools (bash 3.2 on macOS).
#
# Environment variables (optional):
#   ACTION_FILE  The action definition (default: action.yaml)
#   README_FILE  The README (default: README.md)
#
# Exit codes:
#   0 - action.yaml and README.md agree
#   1 - At least one difference (each one is reported as an ::error:: on stderr)

set -euo pipefail

ACTION_FILE="${ACTION_FILE:-action.yaml}"
README_FILE="${README_FILE:-README.md}"
errors=0

fail() {
	echo "::error::$*" >&2
	errors=1
}

# The names of the inputs of action.yaml, one per line
action_inputs() {
	awk '/^inputs:/ {f=1; next} /^[a-z]+:/ {f=0} f && /^  [a-z-]+:$/ {gsub(/[: ]/, ""); print}' "$ACTION_FILE"
}

# The default of an input of action.yaml, without quotes (the empty string gives an empty line)
# Args: $1 - input name
action_default() {
	awk -v name="$1" '
		/^inputs:/ {f=1; next}
		/^[a-z]+:/ {f=0}
		f && /^  [a-z-]+:$/ {cur=$1; sub(/:$/, "", cur)}
		f && cur == name && /^    default:/ {sub(/^    default: */, ""); gsub(/"/, ""); print; exit}
	' "$ACTION_FILE"
}

# The names of the inputs of the table of the "Inputs" section of the README, one per line
readme_inputs() {
	awk -F'|' '/^## Inputs/ {f=1; next} /^## / {f=0} f && /^\| `/ {gsub(/[` ]/, "", $2); print $2}' "$README_FILE"
}

# The default of an input in the table of the README, without backticks and quotes
# Args: $1 - input name
readme_default() {
	awk -F'|' -v name="$1" '
		/^## Inputs/ {f=1; next}
		/^## / {f=0}
		f && /^\| `/ {
			n = $2; gsub(/[` ]/, "", n)
			if (n == name) {d = $4; gsub(/[` "]/, "", d); print d; exit}
		}
	' "$README_FILE"
}

main() {
	local name want got
	local action_names readme_names

	action_names=$(action_inputs | sort)
	readme_names=$(readme_inputs | sort)
	[ -n "$action_names" ] || fail "No input found in $ACTION_FILE"
	[ "$action_names" = "$readme_names" ] ||
		fail "The inputs of $ACTION_FILE and of the README differ: $(printf '%s\n%s\n' "$action_names" "$readme_names" | sort | uniq -u | tr '\n' ' ')"

	while IFS= read -r name; do
		[ -n "$name" ] || continue
		want=$(action_default "$name")
		got=$(readme_default "$name")
		[ "$want" = "$got" ] || fail "The default of '$name' is '$want' in $ACTION_FILE and '$got' in the README"
	done <<<"$action_names"

	# The README says the action has no outputs
	if grep -q '^outputs:' "$ACTION_FILE"; then
		fail "$ACTION_FILE has outputs: document them in the README and check them here"
	fi

	[ "$errors" -eq 0 ] || return 1
	echo "✅ $ACTION_FILE and the README describe the same inputs"
}

main "$@"
