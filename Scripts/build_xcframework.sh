#!/bin/bash

set -euo pipefail

readonly MODULE_NAME="BibTeXKit"
readonly BUILD_PACKAGE_NAME="BibTeXKitXCFrameworkBuild"
readonly VALID_PLATFORM_GROUPS="macos,catalyst,ios,tvos,watchos,visionos"

usage() {
    cat <<'EOF'
Build a library-evolution-enabled BibTeXKit XCFramework.

Usage:
  Scripts/build_xcframework.sh \
    --version <MAJOR.MINOR.PATCH> \
    --output <path/BibTeXKit.xcframework> \
    [--platforms all|macos,catalyst,ios,tvos,watchos,visionos]

The output path must not already exist. The default platform set is "all".
EOF
}

fail() {
    echo "error: $*" >&2
    exit 1
}

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repository_root="$(cd "${script_directory}/.." && pwd -P)"
build_template="${repository_root}/Distribution/XCFrameworkBuild/Package.swift.template"
source_directory="${repository_root}/Sources/${MODULE_NAME}"

version=""
output=""
platforms="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            [[ $# -ge 2 ]] || fail "--version requires a value"
            version="$2"
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || fail "--output requires a value"
            output="$2"
            shift 2
            ;;
        --platforms)
            [[ $# -ge 2 ]] || fail "--platforms requires a value"
            platforms="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            fail "unknown argument: $1"
            ;;
    esac
done

[[ -n "${version}" ]] || fail "--version is required"
[[ "${version}" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] \
    || fail "invalid release version: ${version}"
[[ -n "${output}" ]] || fail "--output is required"
[[ -d "${source_directory}" ]] || fail "missing source directory: ${source_directory}"
[[ -f "${build_template}" ]] || fail "missing build manifest: ${build_template}"

command -v xcodebuild >/dev/null || fail "xcodebuild is required"
command -v xcrun >/dev/null || fail "xcrun is required"
command -v ditto >/dev/null || fail "ditto is required"
command -v python3 >/dev/null || fail "python3 is required"

output_parent_input="$(dirname "${output}")"
mkdir -p "${output_parent_input}"
output_parent="$(cd "${output_parent_input}" && pwd -P)"
output="${output_parent}/$(basename "${output}")"
[[ "$(basename "${output}")" == "${MODULE_NAME}.xcframework" ]] \
    || fail "output must be named ${MODULE_NAME}.xcframework"
[[ ! -e "${output}" ]] || fail "output already exists: ${output}"

if [[ "${platforms}" == "all" ]]; then
    requested_platforms="${VALID_PLATFORM_GROUPS}"
elif [[ "${platforms}" == *"all"* ]]; then
    fail "'all' cannot be combined with platform names"
else
    requested_platforms="${platforms}"
fi

IFS=',' read -r -a requested_array <<< "${requested_platforms}"
[[ ${#requested_array[@]} -gt 0 ]] || fail "at least one platform is required"
for platform in "${requested_array[@]}"; do
    case "${platform}" in
        macos|catalyst|ios|tvos|watchos|visionos) ;;
        *) fail "unsupported platform group: ${platform}" ;;
    esac
done

platform_requested() {
    local candidate="$1"
    local item
    for item in "${requested_array[@]}"; do
        if [[ "${item}" == "${candidate}" ]]; then
            return 0
        fi
    done
    return 1
}

work_directory="$(mktemp -d "${output_parent}/.BibTeXKit-xcframework.XXXXXX")"
cleanup() {
    if [[ -n "${work_directory:-}" \
        && -d "${work_directory}" \
        && "${work_directory}" == "${output_parent}/.BibTeXKit-xcframework."* ]]; then
        /bin/rm -rf -- "${work_directory}"
    fi
}
trap cleanup EXIT INT TERM

staging_package="${work_directory}/${BUILD_PACKAGE_NAME}"
archives_directory="${work_directory}/Archives"
derived_data_directory="${work_directory}/DerivedData"
candidate_xcframework="${work_directory}/${MODULE_NAME}.xcframework"
mkdir -p "${staging_package}/Sources" "${archives_directory}" "${derived_data_directory}"
ditto "${source_directory}" "${staging_package}/Sources/${MODULE_NAME}"
cp "${build_template}" "${staging_package}/Package.swift"

export SWIFT_DETERMINISTIC_HASHING=1

xcframework_arguments=()

archive_slice() {
    local identifier="$1"
    local destination="$2"
    local sdk="$3"
    local architectures="$4"
    local archive_path="${archives_directory}/${identifier}.xcarchive"
    local derived_path="${derived_data_directory}/${identifier}"
    local framework_path="${archive_path}/Products/usr/local/lib/${MODULE_NAME}.framework"
    local module_search_root
    local module_directory
    local module_install_root
    local module_count

    xcrun --sdk "${sdk}" --show-sdk-path >/dev/null 2>&1 \
        || fail "required SDK is unavailable for ${identifier}: ${sdk}"

    echo "Archiving ${identifier} (${destination})"
    (
        cd "${staging_package}"
        xcodebuild archive \
            -scheme "${BUILD_PACKAGE_NAME}" \
            -destination "${destination}" \
            -archivePath "${archive_path}" \
            -derivedDataPath "${derived_path}" \
            -configuration Release \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            COMPILER_INDEX_STORE_ENABLE=NO \
            DEBUG_INFORMATION_FORMAT=dwarf \
            GCC_TREAT_WARNINGS_AS_ERRORS=YES \
            SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
            SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
            STRIP_INSTALLED_PRODUCT=YES \
            ZERO_AR_DATE=1 \
            ARCHS="${architectures}" \
            ONLY_ACTIVE_ARCH=NO \
            MARKETING_VERSION="${version}" \
            CURRENT_PROJECT_VERSION=1
    )

    [[ -f "${framework_path}/${MODULE_NAME}" ]] \
        || fail "archive did not contain ${MODULE_NAME}.framework for ${identifier}"

    # Xcode archives SwiftPM dynamic products without installing their Modules
    # directory. Copy the public module artifacts emitted by the same archive;
    # otherwise the framework binary exists but cannot be imported by clients.
    module_search_root="${derived_path}/Build/Intermediates.noindex/ArchiveIntermediates"
    module_count="$(
        find "${module_search_root}" -type d -name "${MODULE_NAME}.swiftmodule" \
            -path "*/BuildProductsPath/*" | wc -l | tr -d ' '
    )"
    [[ "${module_count}" == "1" ]] \
        || fail "expected one module directory for ${identifier}, found ${module_count}"
    module_directory="$(
        find "${module_search_root}" -type d -name "${MODULE_NAME}.swiftmodule" \
            -path "*/BuildProductsPath/*" -print
    )"
    if [[ -d "${framework_path}/Versions/A" ]]; then
        module_install_root="${framework_path}/Versions/A/Modules"
        mkdir -p "${module_install_root}"
        if [[ ! -e "${framework_path}/Modules" && ! -L "${framework_path}/Modules" ]]; then
            ln -s "Versions/Current/Modules" "${framework_path}/Modules"
        fi
    else
        module_install_root="${framework_path}/Modules"
        mkdir -p "${module_install_root}"
    fi
    ditto "${module_directory}" "${module_install_root}/${MODULE_NAME}.swiftmodule"

    find "${framework_path}/Modules/${MODULE_NAME}.swiftmodule" \
        -type f -name '*.swiftinterface' -print -quit | grep -q . \
        || fail "archive has no public Swift interface for ${identifier}"
    grep -q -- '-enable-library-evolution' \
        "${framework_path}/Modules/${MODULE_NAME}.swiftmodule/"*.swiftinterface \
        || fail "archive was not built with library evolution for ${identifier}"

    xcframework_arguments+=("-framework" "${framework_path}")
}

if platform_requested macos; then
    archive_slice "macos" "generic/platform=macOS" "macosx" "arm64 x86_64"
fi
if platform_requested catalyst; then
    archive_slice "maccatalyst" "generic/platform=macOS,variant=Mac Catalyst" "macosx" "arm64 x86_64"
fi
if platform_requested ios; then
    archive_slice "ios" "generic/platform=iOS" "iphoneos" "arm64"
    archive_slice "ios-simulator" "generic/platform=iOS Simulator" "iphonesimulator" "arm64 x86_64"
fi
if platform_requested tvos; then
    archive_slice "tvos" "generic/platform=tvOS" "appletvos" "arm64"
    archive_slice "tvos-simulator" "generic/platform=tvOS Simulator" "appletvsimulator" "arm64 x86_64"
fi
if platform_requested watchos; then
    archive_slice "watchos" "generic/platform=watchOS" "watchos" "arm64 arm64_32"
    archive_slice "watchos-simulator" "generic/platform=watchOS Simulator" "watchsimulator" "arm64 x86_64"
fi
if platform_requested visionos; then
    archive_slice "visionos" "generic/platform=visionOS" "xros" "arm64"
    archive_slice "visionos-simulator" "generic/platform=visionOS Simulator" "xrsimulator" "arm64 x86_64"
fi

[[ ${#xcframework_arguments[@]} -gt 0 ]] || fail "no framework slices were built"
xcodebuild -create-xcframework \
    "${xcframework_arguments[@]}" \
    -output "${candidate_xcframework}"

python3 - \
    "${script_directory}" \
    "${candidate_xcframework}" \
    "${platforms}" <<'PY'
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
from package_xcframework import parse_platform_groups, validate_xcframework

validate_xcframework(Path(sys.argv[2]), parse_platform_groups(sys.argv[3]))
PY

mv "${candidate_xcframework}" "${output}"
echo "Created ${output}"
