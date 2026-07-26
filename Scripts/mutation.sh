#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
report_directory="${MUTATION_REPORT_DIR:-${repository_root}/.build/reports/mutation}"
mutation_binary="${MUTATION_TESTING_BIN:-swift-mutation-testing}"
minimum_score="${MIN_MUTATION_SCORE:-100}"
maximum_timeouts="${MAX_MUTATION_TIMEOUTS:-0}"
maximum_no_coverage="${MAX_MUTATION_NO_COVERAGE:-0}"
maximum_unviable_percent="${MAX_MUTATION_UNVIABLE_PERCENT:-5}"

mkdir -p "${report_directory}"
report_directory="$(cd "${report_directory}" && pwd -P)"

if [[ "${report_directory}" == "/" || "${report_directory}" == "${repository_root}" ]]; then
    echo "Refusing to use an unsafe mutation report directory." >&2
    exit 2
fi

for report in mutation.json mutation.html mutation-sonar.json summary.md; do
    rm -f "${report_directory}/${report}"
done

if [[ "${mutation_binary}" == */* ]]; then
    if [[ ! -x "${mutation_binary}" ]]; then
        echo "Mutation-testing executable is not runnable: ${mutation_binary}" >&2
        exit 2
    fi
    mutation_binary="$(
        cd "$(dirname "${mutation_binary}")"
        printf '%s/%s\n' "$(pwd -P)" "$(basename "${mutation_binary}")"
    )"
elif ! command -v "${mutation_binary}" >/dev/null 2>&1; then
    echo "swift-mutation-testing is not installed or MUTATION_TESTING_BIN is invalid." >&2
    exit 2
fi

mutation_arguments=(
    "${repository_root}"
    --output "${report_directory}/mutation.json" \
    --html-output "${report_directory}/mutation.html" \
    --sonar-output "${report_directory}/mutation-sonar.json" \
    --quiet
)

if [[ "${MUTATION_NO_CACHE:-0}" == "1" ]]; then
    mutation_arguments+=(--no-cache)
fi

cd "${repository_root}"
"${mutation_binary}" "${mutation_arguments[@]}"

for report in mutation.json mutation.html mutation-sonar.json; do
    if [[ ! -s "${report_directory}/${report}" ]]; then
        echo "Mutation tool did not create ${report_directory}/${report}." >&2
        exit 2
    fi
done

set +e
python3 "${repository_root}/Scripts/check_mutation_score.py" \
    "${report_directory}/mutation.json" \
    --minimum-score "${minimum_score}" \
    --maximum-timeouts "${maximum_timeouts}" \
    --maximum-no-coverage "${maximum_no_coverage}" \
    --maximum-unviable-percent "${maximum_unviable_percent}" \
    --summary "${report_directory}/summary.md"
mutation_status=$?
set -e

if [[ -n "${GITHUB_STEP_SUMMARY:-}" && -f "${report_directory}/summary.md" ]]; then
    cat "${report_directory}/summary.md" >> "${GITHUB_STEP_SUMMARY}"
fi

exit "${mutation_status}"
