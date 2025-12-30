# BibTeXKit Agent Guide

This document provides instructions for AI agents on how to use the BibTeXKit API effectively.

## Overview

BibTeXKit is a Swift framework for parsing, displaying, and manipulating BibTeX bibliographic data. When working with this library, you'll primarily interact with these components:

- **BibTeXParser** - Parse BibTeX strings into structured entries
- **BibTeXEntry** - Work with individual bibliography entries
- **LaTeXConverter** - Convert between LaTeX and Unicode
- **BibTeXView** - Display BibTeX with syntax highlighting (SwiftUI)

---

## Quick Reference

### Parsing BibTeX

```swift
import BibTeXKit

// Parse a BibTeX string
let bibtex = """
@article{einstein1905,
    author = {Albert Einstein},
    title = {On the Electrodynamics of Moving Bodies},
    journal = {Annalen der Physik},
    year = {1905}
}
"""

do {
    let entries = try BibTeXParser.parse(bibtex)
    // entries is [BibTeXEntry]
} catch {
    // Handle BibTeXParser.Error
}
```

### Parser Options

```swift
var options = BibTeXParser.Options()
options.convertLaTeXToUnicode = true   // Convert \"{u} → ü
options.normalizeFieldNames = true      // Lowercase field names
options.stripDelimiters = true          // Remove extra whitespace
options.preserveRawBibTeX = false       // Keep original string

let entries = try BibTeXParser.parse(bibtex, options: options)
```

### Accessing Entry Fields

```swift
let entry = entries.first!

// Type and key
entry.type          // BibTeXEntryType (e.g., .article, .book)
entry.citationKey   // String (e.g., "einstein1905")

// Common fields (all return String?)
entry.author        // "Albert Einstein"
entry.title         // "On the Electrodynamics..."
entry.year          // "1905"
entry.journal       // "Annalen der Physik"
entry.publisher     // nil if not present
entry.doi           // nil if not present
entry.abstract      // nil if not present

// Subscript access (case-insensitive)
entry["author"]     // Same as entry.author
entry["TITLE"]      // Case insensitive lookup

// Parsed authors
entry.authors       // [String] - splits "and"-separated authors
```

### Entry Types

Available `BibTeXEntryType` cases:

| Standard Types | Additional Types |
|---------------|------------------|
| `.article` | `.online` |
| `.book` | `.software` |
| `.booklet` | `.dataset` |
| `.inbook` | `.custom(String)` |
| `.incollection` | |
| `.inproceedings` | |
| `.conference` | |
| `.manual` | |
| `.mastersthesis` | |
| `.phdthesis` | |
| `.proceedings` | |
| `.techreport` | |
| `.unpublished` | |
| `.misc` | |

### Validation

```swift
let validation = entry.validate()
validation.isValid           // Bool
validation.missingRequired   // [String] - required fields not present
validation.missingOptional   // [String] - optional fields not present
```

### Formatting Entries

```swift
// Format as BibTeX string
entry.formatted(style: .standard)  // Standard indentation
entry.formatted(style: .compact)   // Minimal whitespace
entry.formatted(style: .minimal)   // Single line per field
entry.formatted(style: .aligned)   // Aligned equals signs

// Generate citations
entry.citation(style: .apa)        // APA format
entry.citation(style: .mla)        // MLA format
entry.citation(style: .chicago)    // Chicago format
entry.citation(style: .ieee)       // IEEE format
entry.citation(style: .harvard)    // Harvard format
```

### Modifying Entries

```swift
// Create modified copies (entries are immutable)
let updated = entry
    .with(field: "note", value: "Important paper")
    .with(key: "newCitationKey")
    .with(type: .book)
    .with(fields: ["abstract": "...", "keywords": "..."])
```

### LaTeX Conversion

```swift
// LaTeX to Unicode
LaTeXConverter.toUnicode("M\\\"uller")     // "Müller"
LaTeXConverter.toUnicode("Caf\\'e")        // "Café"
LaTeXConverter.toUnicode("\\alpha")        // "α"
LaTeXConverter.toUnicode("\\infty")        // "∞"

// Unicode to LaTeX
LaTeXConverter.toLaTeX("Müller")           // "M\"uller"
LaTeXConverter.toLaTeX("α")                // "\\alpha"
```

---

## SwiftUI Components

### BibTeXView

Display BibTeX with syntax highlighting:

```swift
import SwiftUI
import BibTeXKit

struct ContentView: View {
    var body: some View {
        BibTeXView(bibtex: bibtexString)
            .bibTeXTheme(MonokaiTheme())
            .lineNumbers(true)
            .copyButtonHidden(false)
            .showMetadata(true)
    }
}
```

### Available View Modifiers

| Modifier | Parameter | Description |
|----------|-----------|-------------|
| `.bibTeXTheme(_:)` | `any BibTeXTheme` | Set syntax highlighting theme |
| `.lineNumbers(_:)` | `Bool` | Show/hide line numbers |
| `.copyButtonHidden(_:)` | `Bool` | Hide copy button |
| `.copyButtonPosition(_:)` | `CopyButtonPosition` | Button position |
| `.copyButtonStyle(_:)` | `CopyButtonStyle` | Button style |
| `.showMetadata(_:)` | `Bool` | Show entry type badge |
| `.formattingStyle(_:)` | `FormattingStyle` | BibTeX formatting |
| `.maxHeight(_:)` | `CGFloat?` | Maximum height |
| `.minHeight(_:)` | `CGFloat?` | Minimum height |
| `.cornerRadius(_:)` | `CGFloat` | Corner radius |
| `.bordered(_:)` | `Bool` | Show border |
| `.textSelection(_:)` | `Bool` | Enable text selection |
| `.contentPadding(_:)` | `EdgeInsets` or `CGFloat` | Padding |
| `.preset(_:)` | `BibTeXViewConfiguration` | Apply preset |

### Built-in Themes

```swift
DefaultLightTheme()    // Light theme (default)
DefaultDarkTheme()     // Dark theme
XcodeLightTheme()      // Xcode light style
XcodeDarkTheme()       // Xcode dark style
MonokaiTheme()         // Monokai (dark)
SolarizedLightTheme()  // Solarized light
SolarizedDarkTheme()   // Solarized dark
AdaptiveTheme()        // Adapts to system appearance
```

### Configuration Presets

```swift
BibTeXView(bibtex: bibtex)
    .preset(.minimal)   // Just content
    .preset(.compact)   // For tight spaces
    .preset(.full)      // All features
    .preset(.mobile)    // Phone optimized
```

---

## Common Tasks

### Task: Parse and extract all authors from a .bib file

```swift
let entries = try BibTeXParser.parse(bibFileContents)
let allAuthors = entries.flatMap { $0.authors }
let uniqueAuthors = Set(allAuthors)
```

### Task: Find entries by year

```swift
let entries = try BibTeXParser.parse(bibtex)
let papers2024 = entries.filter { $0.year == "2024" }
```

### Task: Generate APA citations for all entries

```swift
let entries = try BibTeXParser.parse(bibtex)
let citations = entries.map { $0.citation(style: .apa) }
```

### Task: Convert LaTeX in a string to readable Unicode

```swift
let readable = LaTeXConverter.toUnicode(latexString)
```

### Task: Check if entries have required fields

```swift
let entries = try BibTeXParser.parse(bibtex)
for entry in entries {
    let validation = entry.validate()
    if !validation.isValid {
        print("\(entry.citationKey) missing: \(validation.missingRequired)")
    }
}
```

### Task: Create a new entry programmatically

```swift
let entry = BibTeXEntry(
    type: .article,
    citationKey: "smith2024",
    fields: [
        "author": "John Smith",
        "title": "My Paper",
        "journal": "Nature",
        "year": "2024",
        "volume": "123",
        "pages": "1-10"
    ]
)
let bibtexString = entry.formatted(style: .standard)
```

---

## Error Handling

The parser throws `BibTeXParser.Error`:

```swift
do {
    let entries = try BibTeXParser.parse(bibtex)
} catch BibTeXParser.Error.emptyInput {
    // Input string is empty
} catch BibTeXParser.Error.noEntriesFound {
    // No valid entries found
} catch BibTeXParser.Error.invalidEntryType(let position) {
    // Invalid @type at position
} catch BibTeXParser.Error.missingCitationKey(let type, let position) {
    // Missing key for @type
} catch BibTeXParser.Error.unmatchedBraces(let position) {
    // Brace mismatch at position
} catch {
    // Other error
}
```

---

## Token Types (for syntax highlighting)

When implementing custom themes, these are the `BibTeXToken` cases:

| Token | Description | Example |
|-------|-------------|---------|
| `.entryType` | Entry declaration | `@article` |
| `.citationKey` | Citation key | `einstein1905` |
| `.fieldName` | Field name | `author`, `title` |
| `.string` | Quoted string value | `"value"` |
| `.number` | Numeric value | `2024` |
| `.operator` | Operators | `=`, `#` |
| `.punctuation` | Braces, commas | `{`, `}`, `,` |
| `.comment` | Comments | `% comment` |
| `.special` | Directives | `@preamble`, `@string` |
| `.constant` | String constants | `jan`, `feb` |
| `.command` | LaTeX commands | `\textbf` |
| `.math` | Math mode | `$E=mc^2$` |
| `.environment` | Environments | `\begin{equation}` |
| `.text` | Plain text | content |
| `.whitespace` | Whitespace | spaces, newlines |

---

## Platform Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS | 17.0+ |
| macOS | 14.0+ |
| tvOS | 17.0+ |
| watchOS | 9.0+ |
| visionOS | 1.0+ |

---

## Tips for Agents

1. **Always use try/catch** when parsing - BibTeX input may be malformed
2. **Entries are immutable** - use `.with()` methods to create modified copies
3. **Field access is case-insensitive** - `entry["Author"]` equals `entry["author"]`
4. **Authors are separated by "and"** - use `entry.authors` to get the array
5. **LaTeX conversion is automatic** by default in parser options
6. **Themes are Sendable** - safe to use across concurrency boundaries
7. **Check validation** before relying on fields for citations
