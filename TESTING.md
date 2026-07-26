# Testing and quality

BibTeXKit treats tests as executable API and safety specifications. Behavioral
tests use Swift Testing. XCTest remains only for its `measure` facility, which
Swift Testing does not currently provide.

The final 1.1.0 source has:

- 554 Swift Testing cases in 28 suites;
- six XCTest performance probes;
- 22 Python tests for coverage, mutation, and distribution tooling.

All tests are deterministic, isolated, independent of execution order, and
safe to run in parallel.

## Test design

Suites express behavior in a Given/When/Then form:

- the `@Suite` name states the Given context;
- each `@Test` name states the When action and Then result;
- parameterized cases cover input classes without duplicating setup.

The behavioral suite covers:

| Scenario | Representative coverage |
|---|---|
| Positive | Parsing, constants, formatting, highlighting, DOI and LaTeX conversion |
| Negative | Invalid identifiers, delimiters, directives, DOI forms, and layout values |
| Boundary | Empty values, Unicode indices, integer limits, long suffixes, and 50,000-level nesting |
| Error handling | Every parser error, malformed decoding, pasteboard rejection, and cancelled feedback |
| Concurrency | Shared parsers, models, themes, highlighters, DOI input, and conversion work |
| Regression | Parser progress, exact output, round trips, case collisions, adaptive-theme destruction, and geometry sanitization |

The library has no network, persistence, or wall-clock dependency. Entry
identity accepts an injected UUID, while the platform pasteboard and
copy-feedback sleep operation are protocol- or closure-backed boundaries.
Tests use fixed identities and deterministic in-memory doubles. Any new
external dependency must be injectable and tested with an isolated double.

Performance probes cover parsing with and without LaTeX conversion,
tokenization, highlighting, LaTeX conversion, and DOI extraction. They report
trends in a release build; they are not timing gates because shared CI
hardware is noisy.

## Local prerequisites

Use a Swift 6.3 toolchain. Distribution and quality tooling also requires
Python 3.9 or newer; building the pinned mutation tool requires Git. The
commands below were verified with Xcode 26.6, Python 3.9.6, and Apple Git
2.50.1:

```bash
export DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer
xcodebuild -version
swift --version
python3 --version
git --version
```

GitHub Actions uses the Swift 6.3 toolchain in Xcode 26.6 on the supported
`macos-26` runner. Keeping `DEVELOPER_DIR` explicit prevents runner-default
drift.

## Unit tests and warnings

Run the complete debug suite:

```bash
swift test
```

Run the optimized checks used by CI:

```bash
python3 -m unittest discover -s Scripts/Tests -p 'test_*.py'
swift build --configuration release -Xswiftc -warnings-as-errors
swift test --configuration release -Xswiftc -warnings-as-errors
```

The final optimized run passes all 554 behavioral cases and six performance
probes with no compiler warnings.

## Performance measurements

Run the six release-mode probes independently:

```bash
swift test \
  --configuration release \
  --filter BibTeXKitPerformanceTests \
  -Xswiftc -warnings-as-errors
```

The following snapshot was recorded on 26 July 2026. It is the mean of ten
XCTest iterations from the second isolated, warmed run on an Apple M5 Pro with
macOS 27.0, Xcode 26.6, and Swift 6.3:

| Workload | Mean wall time |
|---|---:|
| Parse 100 entries with default conversion | 1.58 ms |
| Parse 400 plain entries with LaTeX conversion disabled | 3.53 ms |
| Tokenize 100 entries | 1.83 ms |
| Convert 1,000 repeated LaTeX accents | 0.62 ms |
| Highlight 50 entries | 7.12 ms |
| Extract 1,000 presented DOI links | 4.09 ms |

These measurements are a local engineering snapshot, not an API guarantee or
CI threshold. Hardware load, SDKs, compiler optimization, and thermal state
affect wall-clock results. The probes first verify exact output, so a faster
incorrect implementation cannot pass.

## Sanitizers

Run each behavioral suite in an independent build directory:

```bash
swift test --scratch-path .build/sanitizers/asan \
  --sanitize address \
  --filter BibTeXKitTests \
  -Xswiftc -warnings-as-errors

swift test --scratch-path .build/sanitizers/ubsan \
  --sanitize undefined \
  --filter BibTeXKitTests \
  -Xswiftc -warnings-as-errors

swift test --scratch-path .build/sanitizers/tsan \
  --sanitize thread \
  --filter BibTeXKitTests \
  -Xswiftc -warnings-as-errors
```

The CI commands above run all 554 behavioral tests. Address Sanitizer,
Undefined Behavior Sanitizer, and Thread Sanitizer each pass without a
finding. The six performance probes are excluded from CI sanitizer jobs
because instrumented timings are not useful performance evidence.

The final release audit also ran the complete 560-test suite under each debug
sanitizer, plus the complete optimized suite under Thread Sanitizer. Every run
passed with zero sanitizer diagnostics and zero compiler warnings.

## Coverage

Generate all reports and enforce the thresholds:

```bash
Scripts/coverage.sh
```

The script writes:

| Path | Purpose |
|---|---|
| `.build/reports/coverage/coverage.txt` | LLVM file summary |
| `.build/reports/coverage/coverage.json` | Machine-readable coverage |
| `.build/reports/coverage/coverage.lcov` | LCOV interchange report |
| `.build/reports/coverage/html/index.html` | Annotated source |
| `.build/reports/coverage/summary.md` | CI gate summary |

Tests, SwiftPM-generated runners, and assertion-free performance probes are
excluded. Every file under `Sources/BibTeXKit` remains in the production scope.
The core scope is `Models`, `Parsing`, and `BibTeXHighlighter`.

Final Xcode 26.6 results:

| Scope | Lines | Functions | Regions |
|---|---:|---:|---:|
| Production | 100.00% (4,868/4,868) | 100.00% (582/582) | 100.00% (2,154/2,154) |
| Core | 100.00% (3,892/3,892) | 100.00% (321/321) | 100.00% (1,777/1,777) |
| Required | 100% | 100% | 100% |

The 100% thresholds are justified because every emitted production counter is
reachable through meaningful public, internal-behavior, rendering, or
platform-adapter tests. Separate core thresholds prevent declarative SwiftUI
code from hiding a loss in parser or model coverage. A new unreachable counter
must be redesigned, excluded with a documented structural reason, or covered
through observable behavior; assertion-free tests are not acceptable.

The Swift 6.3 compiler emits no LLVM branch counters for this package. Reports
therefore mark branch coverage unavailable. Regions are not relabeled as
branches. If a future compiler emits branch counters, establish an evidence-
based threshold before making it a required gate.

## Mutation testing

Mutation testing uses
[`swift-mutation-testing` 1.3.0](https://github.com/ericodx/swift-mutation-testing/releases/tag/v1.3.0)
at commit `8d8d03e28f06665c3fc6f36ccdc7cac244a584f6`, with
SwiftSyntax 603.0.2 pinned to
`79e4b74a295b6eb74a8b585e3a39d29e70c1dbd1`.

Build the exact tool and run the same gate locally:

```bash
tool_root="$(mktemp -d)"
git -C "${tool_root}" init
git -C "${tool_root}" remote add origin \
  https://github.com/ericodx/swift-mutation-testing.git
git -C "${tool_root}" fetch --depth 1 origin \
  8d8d03e28f06665c3fc6f36ccdc7cac244a584f6
git -C "${tool_root}" checkout --detach FETCH_HEAD

swift package --package-path "${tool_root}" resolve
python3 Scripts/check_package_pin.py \
  "${tool_root}/Package.resolved" \
  --schema-version 3 \
  --identity swift-syntax \
  --kind remoteSourceControl \
  --location https://github.com/apple/swift-syntax.git \
  --version 603.0.2 \
  --revision 79e4b74a295b6eb74a8b585e3a39d29e70c1dbd1
swift build --package-path "${tool_root}" \
  --configuration release \
  --disable-automatic-resolution

MUTATION_TESTING_BIN="${tool_root}/.build/release/swift-mutation-testing" \
  MUTATION_NO_CACHE=1 \
  Scripts/mutation.sh
```

The full resolve is intentional: SwiftPM must first construct the dependency
graph. The pin checker then rejects any SwiftSyntax source, version, or revision
other than the approved dependency before the build disables automatic
resolution.

`MUTATION_NO_CACHE=1` is required for a release audit. JSON, HTML, Sonar JSON,
and Markdown reports are written to `.build/reports/mutation/`.

The gate uses the standard Stryker score, where killed, crashed, and timed-out
mutants count as detected. The release policy is stricter: it requires a 100%
score, no survivor, no timeout, no uncovered mutant, and no more than 5%
unviable mutants.

The final cache-disabled audit completed in 48 minutes 23 seconds:

| Result | Count |
|---|---:|
| Counted and killed | 1,066 |
| Survived | 0 |
| Timed out | 0 |
| Uncovered | 0 |
| Unviable | 2 (0.19%) |

Every counted mutant was detected. The two unviable mutations were rejected by
the compiler and do not enter the mutation-score denominator. The 5% unviable
ceiling allows limited compiler-version variation while failing a material
loss of viable mutation coverage.

The selected operators replace relational, Boolean, and logical expressions
and negate conditions. Empirical baselines exclude operators that produced
only unviable mutations, behavior-equivalent capacity changes, or broad
non-advancing deletion mutants. These reasons are documented in
`.swift-mutation-testing.yml`.

Release metadata and the declarative token enum are excluded. The current tool
also excludes the complete highlighter, theme, highlighted-text view, and main
SwiftUI view files, including adaptive-theme resolution and copy-feedback
adapter logic. Empirical runs made those files unsuitable mutation targets:
their operator mutations were predominantly unviable or visually equivalent.
Their behavior remains specified by exact palette and attributed-text
assertions, deep adaptive-theme regressions, injected pasteboard/clock tests,
ImageRenderer checks, and platform builds. No generated production source is
present.

The scheduled workflow performs a fresh or cached audit on weekday nights and
supports a manual no-cache release run. Reports are retained as workflow
artifacts even when the quality gate fails.

## Platform builds

CI compiles the package with warnings as errors for:

```text
generic/platform=macOS
generic/platform=macOS,variant=Mac Catalyst
generic/platform=iOS
generic/platform=tvOS
generic/platform=watchOS
generic/platform=visionOS
```

To reproduce one destination:

```bash
destination="generic/platform=iOS"

for scheme in BibTeXKit BibTeXKitDynamic; do
  xcodebuild \
    -scheme "${scheme}" \
    -destination "${destination}" \
    -derivedDataPath ".build/platform-ios-${scheme}" \
    CODE_SIGNING_ALLOWED=NO \
    GCC_TREAT_WARNINGS_AS_ERRORS=YES \
    SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
    build
done
```

Repeat with each destination above. The final matrix passes both products at
all six destinations. These are compile and availability checks; the complete
behavioral suite executes on macOS, and SwiftUI rendering tests use the macOS
renderer.

## XCFramework checks

The distribution workflow repeats release tests for tags, archives every
device and simulator slice with library evolution, validates exact
architectures and public interfaces, computes the SwiftPM checksum, and builds
independent consumers of the automatic `BibTeXKit` product, dynamic
`BibTeXKitDynamic` product, and direct XCFramework.

Run the complete local process in [Distribution](DISTRIBUTION.md). Also verify
the scripts themselves:

```bash
bash -n Scripts/build_xcframework.sh Scripts/validate_distribution.sh
python3 -m unittest discover -s Scripts/Tests -p 'test_*.py'
```

## CI policy

`Build, Test, and Coverage` runs for every pull request and pushes to `main`,
`develop`, and `release/**`. `XCFramework Distribution` runs on the same
events and semantic-version tags. Mutation testing uses a dedicated weekday
schedule because a fresh audit is substantially slower.

For a semantic-version tag, `XCFramework Distribution` also invokes the
complete quality workflow and a no-cache mutation workflow against the exact
tagged commit. Release publication depends on both reusable workflows and the
distribution build, so an asset cannot be published from a commit that missed
coverage, sanitizers, platform builds, or mutation gates.

All reusable actions are pinned to full commit SHAs. Checkout credentials are
not persisted. Repository permissions are read-only except for the isolated
tag-release job. Cache keys include OS, architecture, Xcode, tool revisions,
manifests, sources, and tests; there is no broad restore fallback. Concurrency
groups cancel superseded runs. Coverage, mutation, and distribution artifacts
are retained for 30 days.

Any failed test, warning gate, coverage threshold, mutation-quality threshold,
sanitizer run, platform build, slice validation, checksum check, or consumer
build fails its workflow.

## Known limits

- The compiler does not provide branch counters for this package.
- Tests render SwiftUI and exercise injected clipboard behavior on macOS, but
  they do not automate VoiceOver, physical-device pasteboards, or every
  platform's interaction loop.
- Generic platform jobs compile rather than execute the suite on each Apple
  operating system.
- Performance probes detect trends but do not enforce a time budget.
- Sanitizers and deep-input tests cannot prove behavior under unbounded memory
  pressure, operating-system termination, hardware faults, or host-application
  misuse.
