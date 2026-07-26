# Security policy

BibTeXKit parses data that may originate outside an application. Reports about
unexpected traps, excessive resource use, malformed-input acceptance,
concurrency violations, pasteboard behavior, or distribution integrity are
security-relevant when they cross an application's trust boundary.

## Supported versions

Formal security support begins with 1.1.0. After that release, fixes are made
against the latest published minor version. The unreleased default branch is
development software, and 1.0.x does not receive a compatibility guarantee.

| Version | Status |
|---|---|
| 1.1.x | Supported after `v1.1.0` is published |
| 1.0.x | No formal security-support commitment |
| Unreleased source | Evaluated for the next release |

## Reporting a vulnerability

Do not include exploit details, sensitive bibliography data, or an
uncoordinated disclosure in a public issue.

Email the maintainer at
[ezequiel.ifsp@gmail.com](mailto:ezequiel.ifsp@gmail.com) with the subject
`BibTeXKit security report`. Do not attach confidential material until the
maintainer confirms receipt. Include:

- the affected version and integration model;
- the platform, architecture, and Xcode version;
- a minimal reproduction or malformed input;
- the expected and observed result;
- sanitizer output or a crash log with secrets removed;
- your assessment of impact and whether the issue is already public.

General hardening suggestions that do not disclose a vulnerability can use
[GitHub Issues](https://github.com/ezefranca/BibTeXKit/issues).

## Security boundaries

BibTeXKit performs no networking, telemetry, analytics, or persistence. DOI
helpers construct URLs but do not resolve them. The SwiftUI copy control writes
the displayed BibTeX to the system pasteboard only after a user action.

Parsing and conversion use pure-Swift iterative scanners and typed errors.
Tests cover malformed syntax, deep nesting, long identifiers, Unicode,
arithmetic boundaries, concurrent calls, and sanitizer configurations. These
checks reduce risk; they are not a substitute for application-level input-size
limits. Memory exhaustion, process termination by the operating system, and
unsafe behavior introduced by a host application remain outside the
framework's control.

Release XCFrameworks are produced with library evolution, exact architecture
validation, a reproducible ZIP, and a SwiftPM checksum. Consumers should pin a
released semantic version and must not accept a replaced binary under an
existing version.
