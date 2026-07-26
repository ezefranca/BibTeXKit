#!/bin/bash

set -euo pipefail

usage() {
    cat <<'EOF'
Validate automatic, dynamic, and XCFramework consumption.

Usage:
  Scripts/validate_distribution.sh \
    --xcframework <path/BibTeXKit.xcframework> \
    [--platforms all|macos,catalyst,ios,tvos,watchos,visionos]
EOF
}

fail() {
    echo "error: $*" >&2
    exit 1
}

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repository_root="$(cd "${script_directory}/.." && pwd -P)"
xcframework=""
platforms="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --xcframework)
            [[ $# -ge 2 ]] || fail "--xcframework requires a value"
            xcframework="$2"
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

[[ -d "${xcframework}" ]] || fail "XCFramework does not exist: ${xcframework}"

for command_name in ditto python3 swift xcodebuild; do
    command -v "${command_name}" >/dev/null \
        || fail "${command_name} is required"
done

platform_selection="${platforms}"
if ! platforms="$(
    python3 - "${script_directory}" "${platform_selection}" <<'PY'
import sys

sys.path.insert(0, sys.argv[1])
from package_xcframework import DistributionError, parse_platform_groups

try:
    print(",".join(parse_platform_groups(sys.argv[2])))
except DistributionError as error:
    print(error, file=sys.stderr)
    raise SystemExit(1)
PY
)"; then
    fail "invalid platform selection: ${platform_selection}"
fi
IFS=',' read -r -a platform_array <<< "${platforms}"

work_directory="$(mktemp -d "${TMPDIR:-/tmp}/BibTeXKit-distribution-validation.XXXXXX")"
cleanup() {
    if [[ -n "${work_directory:-}" \
        && -d "${work_directory}" \
        && "${work_directory}" == *"/BibTeXKit-distribution-validation."* ]]; then
        /bin/rm -rf -- "${work_directory}"
    fi
}
trap cleanup EXIT INT TERM

# Build a real source-package client, independently of the repository's tests.
source_consumer="${work_directory}/SourceConsumer"
mkdir -p "${source_consumer}/Sources/SourceConsumer"
cat > "${source_consumer}/Package.swift" <<EOF
// swift-tools-version: 6.3
import PackageDescription
let package = Package(
    name: "BibTeXKitSourceSmoke",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "SourceConsumer", targets: ["SourceConsumer"])],
    dependencies: [.package(path: "${repository_root}")],
    targets: [
        .executableTarget(
            name: "SourceConsumer",
            dependencies: [.product(name: "BibTeXKit", package: "BibTeXKit")]
        )
    ]
)
EOF
cat > "${source_consumer}/Sources/SourceConsumer/main.swift" <<'EOF'
import BibTeXKit

let input = "@article{smoke, title={Native}, year={2026}}"
let entries = try BibTeXParser.parse(input)
struct UnexpectedSmokeResult: Error {}
guard entries.count == 1, entries[0].citationKey == "smoke" else {
    throw UnexpectedSmokeResult()
}
EOF
swift run \
    --package-path "${source_consumer}" \
    --configuration release \
    -Xswiftc -warnings-as-errors \
    SourceConsumer

# Build the dynamic product exposed by the same repository manifest.
dynamic_consumer="${work_directory}/DynamicConsumer"
mkdir -p "${dynamic_consumer}/Sources/DynamicConsumer"
cat > "${dynamic_consumer}/Package.swift" <<EOF
// swift-tools-version: 6.3
import PackageDescription
let package = Package(
    name: "BibTeXKitDynamicSmoke",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "DynamicConsumer", targets: ["DynamicConsumer"])],
    dependencies: [.package(path: "${repository_root}")],
    targets: [
        .executableTarget(
            name: "DynamicConsumer",
            dependencies: [
                .product(name: "BibTeXKitDynamic", package: "BibTeXKit")
            ]
        )
    ]
)
EOF
cat > "${dynamic_consumer}/Sources/DynamicConsumer/main.swift" <<'EOF'
import BibTeXKit

let input = "@article{smoke, title={Dynamic}, year={2026}}"
let entries = try BibTeXParser.parse(input)
struct UnexpectedSmokeResult: Error {}
guard entries.count == 1, entries[0].title == "Dynamic" else {
    throw UnexpectedSmokeResult()
}
EOF
swift run \
    --package-path "${dynamic_consumer}" \
    --configuration release \
    -Xswiftc -warnings-as-errors \
    DynamicConsumer

# Build a direct XCFramework client for every generic destination.
binary_consumer="${work_directory}/BinaryConsumer"
mkdir -p \
    "${binary_consumer}/Artifacts" \
    "${binary_consumer}/Sources/BinaryConsumer"
ditto "${xcframework}" "${binary_consumer}/Artifacts/BibTeXKit.xcframework"
cat > "${binary_consumer}/Package.swift" <<'EOF'
// swift-tools-version: 6.3
import PackageDescription
let package = Package(
    name: "BibTeXKitXCFrameworkSmoke",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [.library(name: "BinaryConsumer", targets: ["BinaryConsumer"])],
    targets: [
        .binaryTarget(
            name: "BibTeXKit",
            path: "Artifacts/BibTeXKit.xcframework"
        ),
        .target(
            name: "BinaryConsumer",
            dependencies: ["BibTeXKit"]
        )
    ]
)
EOF
cat > "${binary_consumer}/Sources/BinaryConsumer/BinaryConsumer.swift" <<'EOF'
import BibTeXKit

public enum BinaryConsumer {
    public static func parseCount(_ input: String) throws -> Int {
        try BibTeXParser.parse(input).count
    }
}
EOF

build_xcframework_consumer() {
    local identifier="$1"
    local destination="$2"
    echo "Validating XCFramework consumer for ${identifier}"
    (
        cd "${binary_consumer}"
        xcodebuild \
            -scheme BibTeXKitXCFrameworkSmoke \
            -destination "${destination}" \
            -derivedDataPath "${work_directory}/DerivedData/${identifier}" \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            COMPILER_INDEX_STORE_ENABLE=NO \
            GCC_TREAT_WARNINGS_AS_ERRORS=YES \
            SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
            build
    )
}

for platform in "${platform_array[@]}"; do
    case "${platform}" in
        macos)
            build_xcframework_consumer macos "generic/platform=macOS"
            ;;
        catalyst)
            build_xcframework_consumer maccatalyst "generic/platform=macOS,variant=Mac Catalyst"
            ;;
        ios)
            build_xcframework_consumer ios "generic/platform=iOS"
            build_xcframework_consumer ios-simulator "generic/platform=iOS Simulator"
            ;;
        tvos)
            build_xcframework_consumer tvos "generic/platform=tvOS"
            build_xcframework_consumer tvos-simulator "generic/platform=tvOS Simulator"
            ;;
        watchos)
            build_xcframework_consumer watchos "generic/platform=watchOS"
            build_xcframework_consumer watchos-simulator "generic/platform=watchOS Simulator"
            ;;
        visionos)
            build_xcframework_consumer visionos "generic/platform=visionOS"
            build_xcframework_consumer visionos-simulator "generic/platform=visionOS Simulator"
            ;;
        *)
            fail "unsupported platform group: ${platform}"
            ;;
    esac
done

echo "Automatic, dynamic, and XCFramework consumers built successfully."
