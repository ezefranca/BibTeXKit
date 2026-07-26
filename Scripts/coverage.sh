#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
build_path="${COVERAGE_BUILD_PATH:-${repository_root}/.build/coverage}"
report_directory="${COVERAGE_REPORT_DIR:-${repository_root}/.build/reports/coverage}"
minimum_line_coverage="${MIN_LINE_COVERAGE:-100}"
minimum_function_coverage="${MIN_FUNCTION_COVERAGE:-100}"
minimum_region_coverage="${MIN_REGION_COVERAGE:-100}"
minimum_core_line_coverage="${MIN_CORE_LINE_COVERAGE:-100}"
minimum_core_function_coverage="${MIN_CORE_FUNCTION_COVERAGE:-100}"
minimum_core_region_coverage="${MIN_CORE_REGION_COVERAGE:-100}"

mkdir -p "${build_path}" "${report_directory}"
build_path="$(cd "${build_path}" && pwd -P)"
report_directory="$(cd "${report_directory}" && pwd -P)"

if [[ "${report_directory}" == "/" || "${report_directory}" == "${repository_root}" ]]; then
    echo "Refusing to use an unsafe coverage report directory." >&2
    exit 2
fi

rm -rf "${report_directory}/html"
mkdir -p "${report_directory}/html"
rm -f \
    "${report_directory}/coverage.txt" \
    "${report_directory}/coverage.lcov" \
    "${report_directory}/coverage.json" \
    "${report_directory}/summary.md"

swift test \
    --package-path "${repository_root}" \
    --scratch-path "${build_path}" \
    --enable-code-coverage \
    --filter BibTeXKitTests \
    -Xswiftc -warnings-as-errors

swiftpm_coverage_path="$(
    swift test \
        --package-path "${repository_root}" \
        --scratch-path "${build_path}" \
        --show-codecov-path
)"
if [[ "${swiftpm_coverage_path}" == *.profdata ]]; then
    profile_data="${swiftpm_coverage_path}"
else
    profile_data="$(dirname "${swiftpm_coverage_path}")/default.profdata"
fi
binary_directory="$(
    swift build \
        --package-path "${repository_root}" \
        --scratch-path "${build_path}" \
        --show-bin-path
)"
test_binary="${binary_directory}/BibTeXKitPackageTests.xctest/Contents/MacOS/BibTeXKitPackageTests"

if [[ ! -s "${profile_data}" || ! -x "${test_binary}" ]]; then
    echo "Unable to locate SwiftPM coverage artifacts under ${build_path}." >&2
    exit 2
fi

ignore_pattern='(^|/)(Tests|\.build)(/|$)'
source_directory="${repository_root}/Sources/BibTeXKit"
text_report="${report_directory}/coverage.txt"

xcrun llvm-cov report \
    "${test_binary}" \
    -instr-profile="${profile_data}" \
    -ignore-filename-regex="${ignore_pattern}" \
    "${source_directory}" | tee "${text_report}"

xcrun llvm-cov export \
    "${test_binary}" \
    -instr-profile="${profile_data}" \
    -ignore-filename-regex="${ignore_pattern}" \
    -format=lcov \
    "${source_directory}" > "${report_directory}/coverage.lcov"

xcrun llvm-cov export \
    "${test_binary}" \
    -instr-profile="${profile_data}" \
    -ignore-filename-regex="${ignore_pattern}" \
    "${source_directory}" > "${report_directory}/coverage.json"

xcrun llvm-cov show \
    "${test_binary}" \
    -instr-profile="${profile_data}" \
    -ignore-filename-regex="${ignore_pattern}" \
    -format=html \
    -output-dir="${report_directory}/html" \
    "${source_directory}"

summary_path="${report_directory}/summary.md"
set +e
python3 "${repository_root}/Scripts/check_coverage.py" \
    "${report_directory}/coverage.json" \
    --repository-root "${repository_root}" \
    --minimum-line "${minimum_line_coverage}" \
    --minimum-function "${minimum_function_coverage}" \
    --minimum-region "${minimum_region_coverage}" \
    --minimum-core-line "${minimum_core_line_coverage}" \
    --minimum-core-function "${minimum_core_function_coverage}" \
    --minimum-core-region "${minimum_core_region_coverage}" \
    --summary "${summary_path}"
coverage_status=$?
set -e

if [[ -n "${GITHUB_STEP_SUMMARY:-}" && -f "${summary_path}" ]]; then
    cat "${summary_path}" >> "${GITHUB_STEP_SUMMARY}"
fi

exit "${coverage_status}"
