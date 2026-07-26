# Distribution

BibTeXKit uses one repository and one public package manifest for source and
dynamic linkage. Release automation also produces a library-evolution
XCFramework for projects that embed precompiled frameworks directly.

## Swift Package Manager

After `v1.1.0` is published, add the same repository for either linkage model:

```swift
dependencies: [
    .package(
        url: "https://github.com/ezefranca/BibTeXKit.git",
        from: "1.1.0"
    )
]
```

Choose one product in the consuming target:

```swift
// SwiftPM chooses static or dynamic linkage.
.product(name: "BibTeXKit", package: "BibTeXKit")

// Force a dynamically linked framework from the same source target.
.product(name: "BibTeXKitDynamic", package: "BibTeXKit")
```

Both products expose `import BibTeXKit`, resolve from
`https://github.com/ezefranca/BibTeXKit.git`, and compile the same source at
the selected version. This follows the source/dynamic-product model used by
established Swift packages and avoids a second package repository.

## Precompiled XCFramework

Releases produced by the current workflow publish:

- `BibTeXKit.xcframework.zip`
- `BibTeXKit.xcframework.checksum`
- `release-metadata.json`

Extract the archive and add `BibTeXKit.xcframework` to an Xcode project that
needs a precompiled framework. Select **Embed & Sign** for application targets.
Do not combine the XCFramework with either SwiftPM product in the same target.

## Building locally

Use Xcode 26.6 with Swift 6.3 and Python 3.9 or newer. The optional mutation
bootstrap documented in [Testing and quality](TESTING.md) also requires Git.
Select the required Xcode installation and build all supported Apple platforms:

```bash
export DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer

platforms=all
xcframework_path=.build/xcframework/BibTeXKit.xcframework
distribution_directory=.build/distribution

Scripts/build_xcframework.sh \
  --version 1.1.0 \
  --platforms "${platforms}" \
  --output "${xcframework_path}"
```

The complete artifact has the following contract:

| Destination | Architectures |
|---|---|
| macOS | `arm64`, `x86_64` |
| Mac Catalyst | `arm64`, `x86_64` |
| iOS device | `arm64` |
| iOS Simulator | `arm64`, `x86_64` |
| tvOS device | `arm64` |
| tvOS Simulator | `arm64`, `x86_64` |
| watchOS device | `arm64`, `arm64_32` |
| watchOS Simulator | `arm64`, `x86_64` |
| visionOS device | `arm64` |
| visionOS Simulator | `arm64`, `x86_64` |

The packager rejects an artifact whose architecture sets differ from this
contract, preventing runner architecture from silently narrowing a release.

For a machine without every optional SDK component, explicitly request the
installed subset, for example:

```bash
platforms=macos,catalyst,ios,watchos
xcframework_path=.build/xcframework-subset/BibTeXKit.xcframework
distribution_directory=.build/distribution-subset

Scripts/build_xcframework.sh \
  --version 1.1.0 \
  --platforms "${platforms}" \
  --output "${xcframework_path}"
```

The script refuses to overwrite an existing artifact. Use a fresh output path
for each build. Keep `platforms`, `xcframework_path`, and
`distribution_directory` unchanged for the packaging and validation commands
that follow. The packager also refuses to replace an existing ZIP, checksum,
or metadata file, so `distribution_directory` must be fresh for each run.

## Packaging and checksums

Create a reproducible ZIP, checksum, and release metadata:

```bash
python3 Scripts/package_xcframework.py \
  --xcframework "${xcframework_path}" \
  --output-directory "${distribution_directory}" \
  --version 1.1.0 \
  --artifact-url \
    https://github.com/ezefranca/BibTeXKit/releases/download/v1.1.0/BibTeXKit.xcframework.zip \
  --platforms "${platforms}"

computed_checksum="$(
  swift package compute-checksum \
    "${distribution_directory}/BibTeXKit.xcframework.zip"
)"
recorded_checksum="$(
  tr -d '[:space:]' \
    < "${distribution_directory}/BibTeXKit.xcframework.checksum"
)"
test "${computed_checksum}" = "${recorded_checksum}"
```

The packager sorts entries and normalizes ZIP timestamps and modes. It accepts
stable `MAJOR.MINOR.PATCH` release versions and rejects prerelease/build
suffixes, unsafe symbolic links, insecure artifact URLs, missing slices, empty
binaries, and frameworks without public library-evolution interfaces.

Validate automatic and dynamic SwiftPM consumers, then compile a direct
XCFramework consumer for every included destination:

```bash
Scripts/validate_distribution.sh \
  --xcframework "${xcframework_path}" \
  --platforms "${platforms}"
```

Run the distribution tooling tests:

```bash
python3 -m unittest discover -s Scripts/Tests -p 'test_*.py'
bash -n Scripts/build_xcframework.sh Scripts/validate_distribution.sh
```

## Release process

The `XCFramework Distribution` workflow performs a warning-as-error,
library-evolution build. It validates every requested slice, independently
verifies SwiftPM's checksum, builds automatic, dynamic, and direct-XCFramework
consumers, and retains the release files as workflow artifacts.

A stable semantic-version tag such as `v1.1.0` creates the corresponding
GitHub release if needed and uploads the validated assets. Existing release
assets are not overwritten. The tag version must exactly match
`BibTeXKitMetadata.version`; a mismatch fails before publication.

## Compatibility and reproducibility

- The framework uses `BUILD_LIBRARY_FOR_DISTRIBUTION=YES`, providing module
  stability and public `.swiftinterface` files. This does not promise semantic
  or ABI compatibility after a breaking API change.
- Release artifacts are tied to the Xcode/Swift compiler and Apple SDK
  versions recorded in their framework metadata. Rebuild releases only with
  the workflow's pinned Xcode version; changing Xcode requires a new artifact
  and checksum.
- The deterministic packager produces stable ZIP bytes for identical
  XCFramework contents under the same Python and zlib runtime. Compiler, SDK,
  or packaging-runtime changes may legitimately change the archive bytes.
- Never replace an already-published release ZIP. Publish a new package version
  and checksum for every changed binary.
- Dynamic frameworks must be embedded and signed by the final application.
  SwiftPM and Xcode perform that step for application targets.
- A precompiled XCFramework does not expose source, support source-level
  debugging in the same way, or participate in whole-module optimization with
  the application.
