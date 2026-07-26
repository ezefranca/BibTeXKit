//
//  CoreCoverageClosureTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import SwiftUI
import Testing

@testable import BibTeXKit

@Suite("Given the visual contracts of built-in BibTeX themes")
struct ThemeCoverageClosureTests {
    @Test(
        "Given every built-in palette, when its line-number color is requested, then the documented color is returned"
    )
    func lineNumberPalettesAreExact() {
        let scenarios: [(name: String, theme: any BibTeXTheme, expected: Color)] = [
            ("Default Light", DefaultLightTheme(), .gray),
            ("Default Dark", DefaultDarkTheme(), Color(white: 0.4)),
            (
                "Xcode Light",
                XcodeLightTheme(),
                Color(red: 0.67, green: 0.70, blue: 0.69)
            ),
            (
                "Xcode Dark",
                XcodeDarkTheme(),
                Color(red: 0.45, green: 0.50, blue: 0.54)
            ),
            (
                "Monokai",
                MonokaiTheme(),
                Color(red: 0.46, green: 0.44, blue: 0.37)
            ),
            (
                "Solarized Light",
                SolarizedLightTheme(),
                Color(red: 0.58, green: 0.63, blue: 0.63)
            ),
            (
                "Solarized Dark",
                SolarizedDarkTheme(),
                Color(red: 0.40, green: 0.48, blue: 0.51)
            ),
        ]

        for scenario in scenarios {
            #expect(
                scenario.theme.lineNumberColor == scenario.expected,
                "Theme: \(scenario.name)"
            )
        }
    }
}

@Suite("Given boundary-sensitive BibTeX entry values")
struct EntryCoverageClosureTests {
    @Test(
        "Given absent optional fields, when typed accessors are read, then they return safe empty values"
    )
    func absentOptionalAccessorsAreSafe() {
        let entry = BibTeXEntry(type: .misc, citationKey: "empty")

        #expect(entry.url == nil)
        #expect(entry.keywords.isEmpty)
    }

    @Test(
        "Given incomplete author delimiters, when authors are parsed, then no partial word is treated as a separator"
    )
    func incompleteAuthorDelimitersRemainLiteral() {
        let values = [
            "Ada a",
            "Ada ax",
            "Ada an",
            "Ada anx",
        ]

        for value in values {
            let entry = BibTeXEntry(
                type: .misc,
                citationKey: "author",
                fields: ["author": value]
            )

            #expect(entry.authors == [value], "Author value: \(value)")
        }
    }

    @Test(
        "Given multi-author entries, when they are ordered, then comparison uses only each first author"
    )
    func comparisonStopsAfterTheFirstParsedAuthor() {
        let ada = BibTeXEntry(
            type: .misc,
            citationKey: "same",
            fields: ["author": "Ada Lovelace and Grace Hopper"]
        )
        let barbara = BibTeXEntry(
            type: .misc,
            citationKey: "same",
            fields: ["author": "Barbara Liskov and Margaret Hamilton"]
        )

        #expect(ada < barbara)
        #expect(!(barbara < ada))
    }

    @Test(
        "Given malformed field-name aliases, when entries are read and formatted, then canonical selection is deterministic"
    )
    func fieldAliasSelectionIsDeterministic() {
        let aliasesOnly = BibTeXEntry(
            type: .misc,
            citationKey: "aliases",
            fields: [
                "Title": "Mixed",
                "TITLE": "Upper",
            ]
        )
        let canonical = BibTeXEntry(
            type: .misc,
            citationKey: "canonical",
            fields: [
                "Title": "Mixed",
                "TITLE": "Upper",
                "title": "Canonical",
                "Zulu": "Last",
                "alpha": "First",
            ]
        )

        #expect(aliasesOnly.title == "Upper")
        #expect(aliasesOnly.formatted(style: .minimal).contains("TITLE={Upper}"))
        #expect(canonical.title == "Canonical")
        #expect(canonical.formatted(style: .minimal).contains("title={Canonical}"))
        #expect(!canonical.formatted(style: .minimal).contains("TITLE={Upper}"))
    }

    @Test(
        "Given otherwise identical entries, when semantic fields differ, then key, value, and count form a total order"
    )
    func semanticFieldsProvideATotalOrder() {
        func entry(_ fields: [String: String]) -> BibTeXEntry {
            BibTeXEntry(type: .misc, citationKey: "same", fields: fields)
        }

        #expect(entry(["alpha": "same"]) < entry(["beta": "same"]))
        #expect(entry(["note": "a"]) < entry(["note": "b"]))
        #expect(
            entry(["note": "a"])
                < entry(["note": "a", "zeta": "last"])
        )
    }
}

@Suite("Given valid boundary forms in BibTeX parser input")
struct ParserCoverageClosureTests {
    @Test(
        "Given a parenthesized comment, when an entry follows it, then the complete comment is ignored"
    )
    func parenthesizedCommentsAreSkipped() throws {
        let entries = try BibTeXParser.parse(
            "@comment(ignored (nested) text) @misc{kept}"
        )

        #expect(entries.map(\.citationKey) == ["kept"])
    }

    @Test(
        "Given delimiter preservation, when quoted and braced values are parsed, then both outer delimiters remain"
    )
    func fieldDelimitersCanBePreserved() throws {
        var options = BibTeXParser.Options()
        options.stripDelimiters = false
        options.convertLaTeXToUnicode = false

        let entry = try #require(
            BibTeXParser.parse(
                #"@misc{delimiters, quoted = "value", braced = {value}}"#,
                options: options
            ).first
        )

        #expect(entry["quoted"] == #""value""#)
        #expect(entry["braced"] == "{value}")
    }

    @Test(
        "Given every standard month constant, when fields are parsed, then each expands to its full English name"
    )
    func everyMonthConstantExpands() throws {
        let abbreviations = [
            "jan", "feb", "mar", "apr", "may", "jun",
            "jul", "aug", "sep", "oct", "nov", "dec",
        ]
        let expected = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December",
        ]
        let fields = abbreviations.enumerated()
            .map { "m\($0.offset + 1) = \($0.element)" }
            .joined(separator: ", ")
        let entry = try #require(
            BibTeXParser.parse("@misc{months, \(fields)}").first
        )

        for (offset, month) in expected.enumerated() {
            #expect(
                entry["m\(offset + 1)"] == month,
                "Month: \(abbreviations[offset])"
            )
        }
    }
}

@Suite("Given malformed math and short identifiers in tokenizer input")
struct TokenizerCoverageClosureBoundaryTests {
    private let tokenizer = BibTeXTokenizer()

    @Test(
        "Given unterminated or ambiguous math, when tokenized, then scanning is lossless and math boundaries remain deterministic"
    )
    func malformedMathRemainsLossless() {
        let scenarios = [
            (source: "@misc{k,title={$x", math: "$x"),
            (source: #"@misc{k,title="$$x$y"}"#, math: "$$x$y"),
            (source: #"@misc{k,title="$x$"}"#, math: "$x$"),
            (source: #"@misc{k,title="$x"#, math: "$x"),
        ]

        for scenario in scenarios {
            let tokens = tokenizer.tokenize(scenario.source)

            #expect(
                tokens.map(\.text).joined() == scenario.source,
                "Source: \(scenario.source)"
            )
            #expect(
                tokens.contains {
                    $0.token == .math && $0.text == scenario.math
                },
                "Source: \(scenario.source)"
            )
        }
    }

    @Test(
        "Given one- and two-character words, when tokenized at top level, then they remain ordinary text"
    )
    func shortWordsAreNotMonthConstants() {
        let tokens = tokenizer.tokenize("a ax").filter {
            $0.token != .whitespace
        }

        #expect(tokens.map(\.text) == ["a", "ax"])
        #expect(tokens.allSatisfy { $0.token == .text })
    }
}

@Suite("Given DOI presentation and punctuation boundaries")
struct DOICoverageClosureTests {
    @Test(
        "Given paired Unicode wrappers inside DOI suffixes, when extracted, then balanced punctuation is preserved"
    )
    func unicodeWrapperPairsArePreserved() {
        let wrappers: [(opening: Character, closing: Character)] = [
            ("„", "“"),
            ("‚", "‘"),
            ("«", "»"),
            ("‹", "›"),
            ("「", "」"),
            ("『", "』"),
            ("【", "】"),
            ("〈", "〉"),
            ("《", "》"),
            ("〔", "〕"),
            ("〖", "〗"),
            ("〘", "〙"),
            ("〚", "〛"),
            ("（", "）"),
            ("［", "］"),
            ("｛", "｝"),
            ("＜", "＞"),
            ("〝", "〞"),
        ]

        for wrapper in wrappers {
            let doi = "10.1/a\(wrapper.opening)b\(wrapper.closing)"

            #expect(
                DOIDetector.extractDOI(from: "Reference \(doi).") == doi,
                "Wrapper: \(wrapper.opening)\(wrapper.closing)"
            )
        }
    }

    @Test(
        "Given supported enclosing Unicode quotes, when DOI presentations are extracted, then the quotes are removed"
    )
    func enclosingUnicodeQuotesAreRemoved() {
        let scenarios = [
            "‹doi:10.1/value›",
            "〝doi:10.1/value〞",
        ]

        for source in scenarios {
            #expect(
                DOIDetector.extractDOI(from: source) == "10.1/value",
                "Source: \(source)"
            )
        }
    }

    @Test(
        "Given incomplete or non-ASCII adjacent presentation prefixes, when scanned, then valid suffix text is retained without stalling"
    )
    func malformedAdjacentPresentationPrefixesRemainSuffixText() {
        let values = [
            "10.1/value,doi",
            "10.1/value,döi:10.2/next",
        ]

        for value in values {
            #expect(DOIDetector.extractDOI(from: value) == value)
        }
    }

    @Test(
        "Given lowercase hexadecimal escapes, when URI presentations are extracted, then bytes decode case-insensitively"
    )
    func lowercasePercentEscapesDecode() {
        #expect(
            DOIDetector.extractDOI(from: "doi:10.1/a%2fb%3fc")
                == "10.1/a/b?c"
        )
    }

    @Test(
        "Given an entry without a DOI, when DOI conveniences are read, then they return safe absence"
    )
    func entryWithoutDOIHasNoDerivedDOIValues() {
        let entry = BibTeXEntry(type: .misc, citationKey: "without-doi")

        #expect(entry.doiURL == nil)
        #expect(!entry.hasValidDOI)
        #expect(entry.normalizedDOI == nil)
    }
}

@Suite("Given malformed letter-named LaTeX accents")
struct LaTeXCoverageClosureTests {
    @Test(
        "Given an immediate ungrouped target, when a letter-named accent is converted, then the malformed command remains lossless"
    )
    func letterNamedAccentsRequireSeparatedTargets() {
        let values = [
            #"\c1"#,
            #"\v9"#,
        ]

        for value in values {
            #expect(LaTeXConverter.toUnicode(value) == value)
        }
    }
}
