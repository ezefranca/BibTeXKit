# BibTeXKit

<p align="center">
  <img src="https://github.com/ezefranca/BibTeXKit/actions/workflows/build.yml/badge.svg" alt="Build Status" />
  <img src="https://img.shields.io/badge/platforms-iOS%2015%2B%20%7C%20macOS%2012%2B%20%7C%20tvOS%2015%2B%20%7C%20watchOS%208%2B%20%7C%20visionOS%201%2B-blue.svg" alt="Platforms" />
  <img src="https://img.shields.io/badge/Swift-6.1%2B-orange.svg" alt="Swift 6.1+" />
  <img src="https://img.shields.io/badge/SPM-compatible-brightgreen.svg" alt="Swift Package Manager" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg" alt="MIT License" />
</p>

![logo](https://github.com/ezefranca/BibTeXKit/blob/main/.github/images/example1.png?raw=true)

**BibTeXKit** is a modern, Swift-native framework for parsing, displaying, and manipulating BibTeX bibliographic data. Built with SwiftUI, it provides beautiful syntax highlighting and a highly customizable viewing experience across all Apple platforms.

## ✨ Features

-  **Beautiful Syntax Highlighting** — 7 built-in themes including Monokai, Solarized, and Xcode styles
-  **Responsive Design** — Adapts perfectly from Apple Watch to Mac
-  **Highly Customizable** — Toggle copy buttons, line numbers, metadata, and more
-  **Complete BibTeX Support** — All 17 standard entry types plus custom types
-  **LaTeX Conversion** — Automatic LaTeX to Unicode conversion (ü → ü)
-  **Quality API** — SwiftUI view modifiers that feel native
- **100% Test Coverage** — Comprehensive test suite
- **Thread Safe** — Full `Sendable` conformance for modern concurrency

## 📦 Installation

### Swift Package Manager

Add BibTeXKit to your project via Xcode:

1. File → Add Package Dependencies...
2. Enter: `https://github.com/ezefranca/BibTeXKit.git`
3. Select "Up to Next Major Version" with `1.0.1`

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ezefranca/BibTeXKit.git", from: "1.0.1")
]
```

## 🚀 Quick Start

### Display BibTeX with Syntax Highlighting

```swift
import SwiftUI
import BibTeXKit

struct ContentView: View {
    let bibtex = """
    @article{einstein1905,
        author = {Albert Einstein},
        title = {On the Electrodynamics of Moving Bodies},
        journal = {Annalen der Physik},
        year = {1905}
    }
    """
    
    var body: some View {
        BibTeXView(bibtex: bibtex)
    }
}
```

### Parse BibTeX

```swift
import BibTeXKit

let bibtex = "@article{key, author = {John Doe}, title = {Example}}"

do {
    let entries = try BibTeXParser.parse(bibtex)
    
    for entry in entries {
        print("Type: \(entry.type)")        // article
        print("Key: \(entry.key)")          // key
        print("Author: \(entry.author)")    // John Doe
    }
} catch {
    print("Parse error: \(error)")
}
```

## 🎨 Customization

### View Modifiers

BibTeXKit uses familiar SwiftUI view modifier patterns:

```swift
BibTeXView(bibtex: myBibTeX)
    .lineNumbers(true)
    .bibTeXTheme(MonokaiTheme())
    .copyButtonHidden()
    .showMetadata(true)
    .formattingStyle(.aligned)
    .cornerRadius(12)
    .maxHeight(400)
```

### Available Modifiers

| Modifier | Description |
|----------|-------------|
| `.bibTeXTheme(_:)` | Set syntax highlighting theme |
| `.lineNumbers(_:)` | Show/hide line numbers |
| `.copyButtonHidden(_:)` | Show/hide copy button |
| `.copyButtonPosition(_:)` | Position: `.topTrailing`, `.bottomLeading`, etc. |
| `.copyButtonStyle(_:)` | Style: `.iconOnly`, `.labeled`, `.compact` |
| `.showMetadata(_:)` | Show entry type badge and field count |
| `.formattingStyle(_:)` | `.standard`, `.compact`, `.minimal`, `.aligned` |
| `.maxHeight(_:)` | Maximum height before scrolling |
| `.minHeight(_:)` | Minimum height |
| `.cornerRadius(_:)` | Container corner radius |
| `.bordered(_:)` | Show/hide border |
| `.textSelection(_:)` | Enable/disable text selection |
| `.contentPadding(_:)` | Content padding |
| `.preset(_:)` | Apply a configuration preset |

### Built-in Themes

```swift
BibTeXView(bibtex: bibtex)
    .bibTeXTheme(DefaultLightTheme())   // Default light theme
    .bibTeXTheme(DefaultDarkTheme())    // Default dark theme
    .bibTeXTheme(XcodeLightTheme())     // Xcode light
    .bibTeXTheme(XcodeDarkTheme())      // Xcode dark
    .bibTeXTheme(MonokaiTheme())        // Monokai (dark)
    .bibTeXTheme(SolarizedLightTheme()) // Solarized light
    .bibTeXTheme(SolarizedDarkTheme())  // Solarized dark
```

### Configuration Presets

```swift
// Minimal - just the content
BibTeXView(bibtex: bibtex)
    .preset(.minimal)

// Compact - for tight spaces
BibTeXView(bibtex: bibtex)
    .preset(.compact)

// Full - all features enabled
BibTeXView(bibtex: bibtex)
    .preset(.full)

// Mobile - optimized for phones
BibTeXView(bibtex: bibtex)
    .preset(.mobile)
```

### Custom Themes

Create your own theme by conforming to `BibTeXTheme`:

```swift
struct MyCustomTheme: BibTeXTheme {
    let name = "My Theme"
    let font = Font.system(size: 14, design: .monospaced)
    let backgroundColor = Color(hex: "#1e1e1e")
    let borderColor = Color.gray.opacity(0.3)
    
    func color(for token: BibTeXToken) -> Color {
        switch token {
        case .entryType: return Color(hex: "#ff6b6b")
        case .citationKey: return Color(hex: "#4ecdc4")
        case .fieldName: return Color(hex: "#45b7d1")
        case .string: return Color(hex: "#96ceb4")
        case .comment: return Color(hex: "#6c757d")
        default: return Color(hex: "#f8f9fa")
        }
    }
}

// Use it
BibTeXView(bibtex: bibtex)
    .bibTeXTheme(MyCustomTheme())
```

## 📖 Parsing Options

### Parser Configuration

```swift
var options = BibTeXParser.Options()
options.convertLaTeXToUnicode = true    // Convert \"{u} to ü
options.normalizeFieldNames = true       // Lowercase field names
options.stripDelimiters = true           // Remove extra whitespace
options.preserveRawBibTeX = true         // Keep original string

let entries = try BibTeXParser.parse(bibtex, options: options)
```

### Entry Properties

```swift
let entry = entries.first!

// Convenience properties
entry.author      // Author field
entry.title       // Title field
entry.year        // Year field
entry.doi         // DOI field
entry.journal     // Journal field
entry.publisher   // Publisher field

// Subscript access (case-insensitive)
entry["author"]   // Same as entry.author
entry["TITLE"]    // Case insensitive

// Author parsing
entry.authors  // ["First Author", "Second Author"]

// Validation
let validation = entry.validate()
validation.isValid           // true if all required fields present
validation.missingRequired   // ["journal", "year"]
validation.missingOptional   // ["volume", "pages"]
```

### Entry Formatting

```swift
// Different formatting styles
entry.formatted(style: .standard)  // Standard indentation
entry.formatted(style: .compact)   // Minimal whitespace
entry.formatted(style: .minimal)   // Single line per field
entry.formatted(style: .aligned)   // Aligned equals signs

// Citation formatting
entry.citation(style: .apa)      // APA format
entry.citation(style: .mla)      // MLA format
entry.citation(style: .chicago)  // Chicago format
entry.citation(style: .ieee)     // IEEE format
entry.citation(style: .harvard)  // Harvard format
```

### Modifying Entries

```swift
// Create modified copies
let updated = entry
    .with(field: "note", value: "Important")
    .with(key: "newkey")
    .with(type: .book)
    .with(fields: ["abstract": "...", "keywords": "..."])
```

## 🔤 LaTeX Conversion

BibTeXKit includes comprehensive LaTeX to Unicode conversion:

```swift
import BibTeXKit

// Accents
LaTeXConverter.toUnicode("M\\\"uller")     // "Müller"
LaTeXConverter.toUnicode("Caf\\'e")        // "Café"
LaTeXConverter.toUnicode("\\~nino")        // "ñino"

// Special characters
LaTeXConverter.toUnicode("\\ss")           // "ß"
LaTeXConverter.toUnicode("\\ae")           // "æ"

// Greek letters
LaTeXConverter.toUnicode("\\alpha")        // "α"
LaTeXConverter.toUnicode("\\Omega")        // "Ω"

// Math symbols
LaTeXConverter.toUnicode("\\infty")        // "∞"
LaTeXConverter.toUnicode("\\pm")           // "±"

// Reverse conversion
LaTeXConverter.toLaTeX("Müller")           // "M\\\"uller"
```

## 📱 Platform Support

| Platform | Minimum Version |
|----------|-----------------|
| iOS | 17.0+ |
| macOS | 14.0+ |
| tvOS | 17.0+ |
| watchOS | 9.0+ |
| visionOS | 1.0+ |

## 🏗️ Architecture

```
BibTeXKit/
├── Models/
│   ├── BibTeXEntry.swift        # Entry model
│   └── BibTeXEntryType.swift    # Entry types enum
├── Parsing/
│   ├── BibTeXParser.swift       # Main parser
│   ├── BibTeXTokenizer.swift    # Tokenizer
│   ├── BibTeXToken.swift        # Token types
│   └── LaTeXConverter.swift     # LaTeX ↔ Unicode
├── Highlighting/
│   ├── BibTeXTheme.swift        # Theme protocol + themes
│   └── BibTeXHighlighter.swift  # AttributedString generator
└── Views/
    ├── BibTeXView.swift         # Main view component
    ├── BibTeXText.swift         # Simple inline text
    └── BibTeXViewConfiguration.swift  # Configuration
```

## 🧪 Testing

BibTeXKit has comprehensive test coverage:

```bash
swift test
```

Run with coverage:

```bash
swift test --enable-code-coverage
```

## 📄 License

BibTeXKit is available under the MIT license. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a PR.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 🤖 AI Contributing

AI contributions are welcome! When submitting a PR, please add the model you used and the prompt to obtain that code. [Like this](https://github.com/ezefranca/BibTeXKit/pull/1)

For AI agents looking to integrate with BibTeXKit, see the [Agent Guide](Agents.md) for comprehensive API documentation and usage patterns.
