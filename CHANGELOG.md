# Changelog

All notable changes to BibTeXKit are documented in this file.

## 1.1.0 - 2026-07-26

### Added

- Swift Testing behavioral suites organized with Given/When/Then descriptions,
  retaining XCTest only for `measure`-based performance probes.
- Filtered production and core coverage reports with line, function, and region
  no-regression gates, plus explicit reporting when LLVM branch counters are
  unavailable.
- Scheduled mutation testing with a pinned `swift-mutation-testing` revision,
  JSON/HTML/Sonar artifacts, surviving-mutant reporting, and independently
  enforced mutation-quality gates.
- Pull-request CI for warning-clean optimized tests and generic builds across
  macOS, Mac Catalyst, iOS, tvOS, watchOS, and visionOS.
- Address, Undefined Behavior, and Thread Sanitizer execution for the complete
  behavioral suite on pull requests and relevant branch pushes.
- Automatic and dynamic library products in one package manifest,
  library-evolution XCFramework generation, deterministic archive packaging,
  exact slice and architecture validation, source/dynamic/XCFramework consumer
  smoke builds, and tagged-release publishing.
- Case-insensitive `@string` resolution and `#` concatenation across quoted,
  braced, numeric, month, and named values.
- `BibTeXEntry.ValidationResult`, value-style `with(...)` APIs, stable
  `Codable` identity, deterministic `Comparable` ordering, and an `author`
  convenience property.
- `BibTeXParser.Options.requireEntries` for callers that need entry-free input
  to fail.
- Explicit validation diagnostics for interchangeable requirements, including
  `author` or `editor` and `chapter` or `pages`.
- Adversarial coverage for malformed input, 50,000-level nesting, long DOI
  names, Unicode, concurrency, rendering, round trips, and value semantics.
- A concise README, dedicated contribution and security policies, verified
  source and binary integration guidance, and an updated agent API reference.

### Fixed

- Canonical BibTeX scanning for whitespace after `@`, identifier grammar,
  brace/quote balance, parenthesized citation keys, directives, comments,
  duplicate fields, and case-insensitive duplicate citation keys.
- Parser hangs and partial results for malformed fields, truncated values,
  mismatched delimiters, invalid separators, and entry-free input.
- Token boundaries and recovery after comments, directives, operators, nested
  values, unterminated math, and custom identifiers. LaTeX commands inside
  quoted and braced values now retain semantic tokens.
- Case-insensitive field access, updates, equality, hashing, deterministic
  formatting, and total entry ordering, including custom-type case variants.
- Lossless `standard`, `compact`, `minimal`, and `aligned` formatting. Valid
  brace-containing citation keys now round-trip with parenthesized entries.
- BibTeX-required field alternatives and blank-value validation.
- LaTeX control-word boundaries, grouping/case protection, dotless-letter
  accents, unknown commands, malformed-input preservation, and literal
  punctuation round trips without recursive stack growth.
- Custom entry types whose spelling collides with standard types now retain
  their exact `Codable` identity.
- DOI syntax, extraction, presentation decoding, URL encoding, punctuation,
  Unicode graphic suffixes, adjacent identifiers, and hostile long input.
- Adaptive theme resolution, fixed-theme contrast, intrinsic SwiftUI sizing,
  real inline copy layout, selection tinting, line-number alignment, dynamic
  fonts, accessibility, and watchOS/tvOS availability.
- An injectable platform pasteboard boundary and deterministic copy-feedback
  clock, allowing the user-initiated copy behavior to be tested without
  changing the system pasteboard.
- Recursive adaptive-theme destruction that could terminate a process under
  adversarial nesting; nested theme normalization is now iterative.
- Overflow-prone formatting and line-number capacity estimates, plus invalid
  negative or non-finite SwiftUI geometry inputs.
- Release metadata, platform documentation, examples, and CI coverage.

### Performance

- Replaced regular-expression work and whole-string rewrites with bounded,
  pure-Swift scanners.
- Removed quadratic success-path error-offset calculations and added
  release-mode probes for 100- and 400-entry parser workloads.
- Reduced parser and tokenizer substring creation, temporary collections, and
  repeated lookahead traversal.
- Applied syntax attributes in place to one `AttributedString` instead of
  constructing and appending one attributed value per token.
- Reused static entry metadata, canonical field indexes, and reserved output
  buffers in mutation, formatting, and citation hot paths.

### Quality

- Raised production and core line, function, and region coverage gates to
  100%. LLVM branch counters remain unavailable for this Swift package and are
  reported explicitly.
- Expanded platform-adapter coverage for pasteboard rejection, copy-feedback
  timing, and every native copy-control presentation.

### Compatibility

- This release intentionally does not promise source compatibility with 1.0.x.
  The release namespace is now `BibTeXKitMetadata`, avoiding a public type that
  shadows the imported `BibTeXKit` module. Parser options and entry decoding use
  only the current 1.1.0 schema.
- Observable parsing, token classification, equality, hashing, formatting,
  and custom-type identity behavior is more strictly canonicalized.
- Requires Swift 6.3 and the platform versions declared in `Package.swift`.
