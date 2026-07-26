# BibTeXKit API quick reference

Use this public reference when writing integrations against BibTeXKit 1.1.0.
The README explains product and integration decisions; this file concentrates
on API behavior and concise, copyable examples.

## Requirements

| Platform | Minimum version |
|---|---:|
| iOS | 17.0 |
| macOS | 14.0 |
| Mac Catalyst | 17.0 |
| tvOS | 17.0 |
| watchOS | 10.0 |
| visionOS | 1.0 |

BibTeXKit requires Swift 6.3. It is a pure-Swift package with no third-party
runtime dependency.

## Parse BibTeX

Parsing untrusted text can fail. Prefer `try`, propagate the typed error when
the caller can handle it, and avoid force-unwrapping the result.

```swift
import BibTeXKit

func parseBibliography(_ source: String) throws -> [BibTeXEntry] {
    try BibTeXParser.parse(source)
}
```

The parser accepts entries, comments, preambles, named string constants,
concatenated values, brace or parenthesis delimiters, LaTeX, and Unicode.
Comment- or directive-only input returns an empty array by default.

Use options when a boundary requires different behavior:

```swift
import BibTeXKit

func parseWithoutConversion(_ source: String) throws -> [BibTeXEntry] {
    let options = BibTeXParser.Options(
        preserveRawBibTeX: true,
        normalizeFieldNames: true,
        stripDelimiters: true,
        convertLaTeXToUnicode: false,
        requireEntries: true
    )

    return try BibTeXParser.parse(source, options: options)
}
```

`BibTeXParser.Options.strict` selects the configuration above.
`BibTeXParser.parseOrNil(_:)` is available for intentionally optional parsing,
but typed errors are preferable when diagnostics matter.

The parser can throw:

- `emptyInput`
- `noEntriesFound`
- `invalidEntryType(position:)`
- `missingCitationKey(entryType:position:)`
- `missingOpeningBrace(position:)`
- `unmatchedBraces(position:)`
- `invalidFieldValue(field:position:)`
- `unexpectedCharacter(character:position:)`

## Read and create entries

```swift
import BibTeXKit

func inspectFirstEntry(in source: String) throws {
    guard let entry = try BibTeXParser.parse(source).first else {
        return
    }

    print(entry.type)
    print(entry.citationKey)
    print(entry.title as Any)
    print(entry.year as Any)
    print(entry["JOURNAL"] as Any)
}
```

Field lookup is case-insensitive. Frequently used accessors include:

| API | Type |
|---|---|
| `title`, `author`, `authorString` | `String?` |
| `authors` | `[String]` |
| `year` | `Int?` |
| `yearString` | `String?` |
| `journal`, `booktitle`, `publisher` | `String?` |
| `volume`, `number`, `pages`, `doi` | `String?` |
| `url`, `doiURL` | `URL?` |
| `abstract`, `month` | `String?` |
| `keywords` | `[String]` |

Create an entry directly when the data is already structured:

```swift
import BibTeXKit

let entry = BibTeXEntry(
    type: .article,
    citationKey: "smith2026",
    fields: [
        "author": "A. Smith",
        "title": "A Swift Bibliography",
        "journal": "Swift Journal",
        "year": "2026"
    ]
)
```

The initializer accepts an `id` argument. Inject a fixed UUID in deterministic
tests. Codable payloads use the current 1.1.0 schema and must contain `id`,
`type`, `citationKey`, and `fields`.

## Validate and update entries

```swift
import BibTeXKit

func revisedEntry(_ entry: BibTeXEntry) -> BibTeXEntry? {
    guard entry.validate().isValid else {
        return nil
    }

    return entry
        .with(field: "doi", value: "10.1000/example")
        .with(key: "smith2026-revised")
}
```

Entries use value semantics. `with(...)`, `settingField(_:to:)`, and
`settingFields(_:)` return new values and preserve the original. Field
canonicalization, equality, hashing, ordering, and formatting are
case-insensitive and deterministic.

Validation exposes `missingRequired` and `missingOptional`. Some entry types
accept alternative required groups, such as `author` or `editor`.

## Format and summarize

```swift
import BibTeXKit

func renderings(for entry: BibTeXEntry) -> [String] {
    [
        entry.formatted(style: .standard),
        entry.formatted(style: .compact),
        entry.formatted(style: .minimal),
        entry.formatted(style: .aligned),
        entry.citation(style: .apa),
        entry.citation(style: .ieee),
    ]
}
```

Citation summaries also support `.mla`, `.chicago`, and `.harvard`. They are
compact Markdown-flavored summaries, not a complete CSL implementation.

## Entry types

Standard and extended cases are:

```text
article, book, booklet, inbook, incollection, inproceedings,
conference, manual, mastersthesis, phdthesis, proceedings,
techreport, unpublished, misc, online, software, dataset
```

Use `.custom("patent")` for another type. Custom type identity is
case-insensitive, while a custom spelling that matches a standard name remains
distinct from the corresponding standard enum case.

## Convert LaTeX and inspect DOIs

```swift
import BibTeXKit

let readable = LaTeXConverter.toUnicode(#"M\"uller and \alpha"#)
let latex = LaTeXConverter.toLaTeX("Müller and α")

let doi = DOIDetector.extractDOI(
    from: "Available at https://doi.org/10.1000/example."
)
let url = doi.flatMap { DOIDetector.doiURL(for: $0) }
```

Available DOI operations are `containsDOI(_:)`, `extractDOI(from:)`,
`extractAllDOIs(from:)`, `isValidDOI(_:)`, `normalize(_:)`, and
`doiURL(for:)`. Entry conveniences are `doiURL`, `hasValidDOI`, and
`normalizedDOI`. These APIs do not perform network requests.

Conversion preserves unknown or malformed LaTeX when a lossless conversion
cannot be established.

## Tokenize and highlight

```swift
import BibTeXKit
import Foundation

func highlightedBibliography(
    _ source: String
) -> AttributedString {
    let tokenizer = BibTeXTokenizer()
    let positionedTokens = tokenizer.tokenize(source)
    let pairs = tokenizer.tokenizePairs(source)
    print(positionedTokens.count, pairs.count)

    let highlighter = BibTeXHighlighter(theme: MonokaiTheme())
    return highlighter.highlight(source)
}
```

`tokenize(_:)` returns `BibTeXTokenInfo` values with exact source ranges.
`tokenizePairs(_:)` omits ranges. Token cases cover entry types, citation keys,
field names, strings, numbers, operators, punctuation, comments, directives,
constants, LaTeX commands, accents, escaped special characters, math,
environments, text, and whitespace.

Built-in themes are `DefaultLightTheme`, `DefaultDarkTheme`,
`XcodeLightTheme`, `XcodeDarkTheme`, `MonokaiTheme`,
`SolarizedLightTheme`, `SolarizedDarkTheme`, and `AdaptiveTheme`. Custom
themes conform to `BibTeXTheme`.

## Present content in SwiftUI

```swift
import BibTeXKit
import SwiftUI

struct EntryView: View {
    let entry: BibTeXEntry

    var body: some View {
        BibTeXView(entry: entry)
            .preset(.full)
            .bibTeXTheme(AdaptiveTheme())
            .formattingStyle(.aligned)
    }
}
```

Raw `BibTeXView(bibtex:)` input is highlighted exactly as supplied. A parsed
entry is formatted with the configured style. `BibTeXText` provides highlighted
text without metadata, borders, line numbers, or copy controls.

Common view modifiers are:

| Modifier | Purpose |
|---|---|
| `.bibTeXTheme(_:)` | Select a theme |
| `.lineNumbers(_:)` | Show line numbers |
| `.copyButtonHidden(_:)` | Hide the copy action |
| `.copyButtonPosition(_:)` | Position the copy action |
| `.copyButtonStyle(_:)` | Select icon, label, or compact presentation |
| `.showMetadata(_:)` | Show entry metadata |
| `.formattingStyle(_:)` | Format parsed entries |
| `.maxHeight(_:)`, `.minHeight(_:)` | Constrain layout |
| `.cornerRadius(_:)`, `.bordered(_:)` | Configure the container |
| `.textSelection(_:)` | Configure selection where supported |
| `.contentPadding(_:)` | Set content insets |
| `.preset(_:)` | Replace the complete configuration |

Apply a preset before focused modifiers because `.preset(_:)` replaces the
whole configuration. Available presets are `.minimal`, `.compact`, `.full`,
and `.mobile`.

The copy control is available on iOS, macOS, Mac Catalyst, and visionOS. It is
omitted on watchOS and tvOS. Text selection is also ignored on watchOS and
tvOS.

## Concurrency and safety

Parsers, entries, tokens, themes, highlighters, and configurations are
`Sendable`. They keep no mutable shared parser state and can cross task
boundaries. Continue to apply application-specific input-size limits when
processing remote files; no finite library can guarantee operation after
process-wide memory exhaustion or operating-system termination.

## Integration rules

1. Treat parsing failure as normal input handling.
2. Avoid force unwraps and `try!` in generated integration code.
3. Use value-style entry updates.
4. Use `entry.authors` instead of manually splitting `author`.
5. Use typed accessors where they preserve the intended value type.
6. Do not describe citation summaries as publisher-conformant CSL output.
7. Do not claim DOI helpers perform resolution or validation over the network.
8. Keep platform availability consistent with `Package.swift`.
