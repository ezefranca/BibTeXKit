# Contributing

BibTeXKit accepts focused changes that improve observable behavior,
interoperability, safety, performance, or platform integration. A contribution
should be understandable from its tests and documentation without relying on
private context.

## Before writing code

Search [open issues](https://github.com/ezefranca/BibTeXKit/issues) for related
work. Open an issue before a broad API change, parser grammar change, new
dependency, or distribution change so the design can be reviewed before the
implementation grows.

For defects, provide a minimal BibTeX input, expected result, actual result,
platform, and Xcode version. Remove private bibliography data.

## Implementation standards

- Use Swift 6.3 language and concurrency checks.
- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
  and established naming in the module.
- Prefer value semantics, explicit errors, bounded iterative processing, and
  standard-library or platform APIs.
- Keep the library pure Swift and avoid a dependency unless its benefit and
  maintenance cost are documented.
- Treat malformed and adversarial input as normal parser input. It must return
  a value or a typed error without trapping.
- Document every public API and update examples when behavior changes.
- State intentional source or behavior compatibility changes in
  `CHANGELOG.md`.

Generated source does not belong in mutation or coverage targets unless the
generated file is itself the maintained implementation. Test the generator
instead.

## Tests

Use Swift Testing for behavioral coverage. Use XCTest only when a required
facility, such as `measure`, is unavailable in Swift Testing.

Organize behavior in a Given/When/Then form:

```swift
import Testing
@testable import BibTeXKit

@Suite("Given a bibliography with a named string")
struct NamedStringTests {
    @Test("When the string is referenced, then the parser resolves its value")
    func resolvesNamedString() throws {
        let source = """
        @string{venue = "Swift Journal"}
        @article{sample, title = venue}
        """

        let entries = try BibTeXParser.parse(source)

        #expect(entries.first?.title == "Swift Journal")
    }
}
```

Tests must be deterministic, isolated, independent of execution order, and
safe to run in parallel. Inject protocol-backed test doubles for any new
network, persistence, clock, randomness, pasteboard, or other external
dependency.

From the repository root, run:

```bash
export DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer

python3 -m unittest discover -s Scripts/Tests -p 'test_*.py'
swift build --configuration release -Xswiftc -warnings-as-errors
swift test --configuration release -Xswiftc -warnings-as-errors
Scripts/coverage.sh
```

Run the relevant sanitizers for parsing, concurrency, indexing, allocation, or
unsafe-input changes. Full commands and mutation-testing setup are in
[Testing and quality](TESTING.md).

## Documentation

Keep public writing direct and factual. Examples must compile against the
current tree, avoid force unwraps, and make error handling visible where input
can be malformed. Keep badges useful and restrained. Do not add product claims
without evidence or claims of Apple affiliation.

If an automated or generative tool materially contributed to a change,
disclose that in the pull request. The contributor remains responsible for
understanding, reviewing, testing, and licensing the complete result.

## Pull requests

A pull request should contain:

- the problem and user-visible outcome;
- the design tradeoffs for nontrivial changes;
- positive, negative, boundary, error, concurrency, and regression tests as
  applicable;
- measured evidence for a performance claim;
- updated public documentation and changelog entries;
- confirmation that the local checks relevant to the change pass.

CI builds with warnings as errors, runs the complete suite and coverage gates,
compiles every supported platform, and runs sanitizers. Mutation testing runs
on its dedicated schedule and before a release.

By contributing, you agree that your work is licensed under the repository's
[MIT License](LICENSE).
