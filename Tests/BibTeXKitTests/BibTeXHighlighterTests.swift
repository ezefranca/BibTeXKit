//
//  BibTeXHighlighterTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI
import Testing

@testable import BibTeXKit

@Suite("Given BibTeX syntax highlighting input")
struct BibTeXHighlighterTests {

    // MARK: - Initialization Tests

    @Test("When initialized with an explicit theme, then the highlighter exposes that theme")
    func initWithTheme() {
        let theme = MonokaiTheme()
        let highlighter = BibTeXHighlighter(theme: theme)

        #expect(highlighter.theme.name == "Monokai")
    }

    @Test("When initialized without a theme, then the default light theme is selected")
    func initWithDefaultTheme() {
        let highlighter = BibTeXHighlighter()

        #expect(highlighter.theme.name == "Default Light")
    }

    @Test("When initialized for a light color scheme, then the default light theme is selected")
    func initWithColorSchemeLight() {
        let highlighter = BibTeXHighlighter(colorScheme: .light)

        #expect(highlighter.theme.name == "Default Light")
    }

    @Test("When initialized for a dark color scheme, then the default dark theme is selected")
    func initWithColorSchemeDark() {
        let highlighter = BibTeXHighlighter(colorScheme: .dark)

        #expect(highlighter.theme.name == "Default Dark")
    }

    // MARK: - Basic Highlighting Tests

    @Test("When highlighting an empty string, then the attributed result is empty")
    func highlightEmptyString() {
        let highlighter = BibTeXHighlighter()
        let result = highlighter.highlight("")

        #expect(result.characters.isEmpty)
    }

    @Test("When highlighting a simple entry, then styled output preserves the complete source")
    func highlightSimpleEntry() {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, title = {Hello}}"

        let result = highlighter.highlight(bibtex)

        #expect(!(result.characters.isEmpty))
        #expect(String(result.characters) == bibtex)
    }

    @Test("When highlighting a multiline entry, then every source character is preserved")
    func highlightPreservesText() {
        let highlighter = BibTeXHighlighter()
        let bibtex = """
            @article{einstein1905,
                author = {Albert Einstein},
                title = {Relativity},
                year = {1905}
            }
            """

        let result = highlighter.highlight(bibtex)

        #expect(String(result.characters) == bibtex)
    }

    // MARK: - Entry Highlighting Tests

    @Test("When highlighting a model entry, then its type and citation key appear in the output")
    func highlightEntry() {
        let highlighter = BibTeXHighlighter()
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test", "year": "2024"]
        )

        let result = highlighter.highlight(entry: entry)

        #expect(!(result.characters.isEmpty))
        let text = String(result.characters)
        #expect(text.contains("@article"))
        #expect(text.contains("test"))
    }

    @Test(
        "When highlighting an entry with different formatting styles, then each output retains its entry type"
    )
    func highlightEntryWithStyle() {
        let highlighter = BibTeXHighlighter()
        let entry = BibTeXEntry(
            type: .book,
            citationKey: "knuth1997",
            fields: ["title": "TAOCP", "author": "Knuth"]
        )

        let compact = highlighter.highlight(entry: entry, style: .compact)
        let aligned = highlighter.highlight(entry: entry, style: .aligned)

        // Both should contain the same basic info
        #expect(String(compact.characters).contains("@book"))
        #expect(String(aligned.characters).contains("@book"))
    }

    // MARK: - Theme Application Tests

    @Test(
        "When the same source uses different themes, then text remains equal while attributes differ"
    )
    func differentThemesProduceDifferentResults() {
        let lightHighlighter = BibTeXHighlighter(theme: DefaultLightTheme())
        let darkHighlighter = BibTeXHighlighter(theme: DefaultDarkTheme())

        let bibtex = "@article{test, title = {Hello}}"

        let lightResult = lightHighlighter.highlight(bibtex)
        let darkResult = darkHighlighter.highlight(bibtex)

        #expect(String(lightResult.characters) == String(darkResult.characters))
        #expect(lightResult != darkResult)
    }

    @Test("When highlighting with the Monokai theme, then nonempty styled output is produced")
    func monokaiThemeHighlighting() {
        let highlighter = BibTeXHighlighter(theme: MonokaiTheme())
        let bibtex = "@article{test, title = {Hello}}"

        let result = highlighter.highlight(bibtex)

        #expect(!(result.characters.isEmpty))
    }

    @Test("When highlighting with the Solarized theme, then nonempty styled output is produced")
    func solarizedThemeHighlighting() {
        let highlighter = BibTeXHighlighter(theme: SolarizedLightTheme())
        let bibtex = "@article{test, title = {Hello}}"

        let result = highlighter.highlight(bibtex)

        #expect(!(result.characters.isEmpty))
    }

    @Test("When highlighting with the Xcode theme, then nonempty styled output is produced")
    func xcodeThemeHighlighting() {
        let highlighter = BibTeXHighlighter(theme: XcodeDarkTheme())
        let bibtex = "@article{test, title = {Hello}}"

        let result = highlighter.highlight(bibtex)

        #expect(!(result.characters.isEmpty))
    }

    // MARK: - Complex Content Tests

    @Test("When highlighting an entry containing LaTeX, then styled output remains nonempty")
    func highlightWithLaTeX() {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, author = {M\\\"uller}}"

        let result = highlighter.highlight(bibtex)

        #expect(!(result.characters.isEmpty))
    }

    @Test("When highlighting comments, then their original text is preserved")
    func highlightWithComments() {
        let highlighter = BibTeXHighlighter()
        let bibtex = """
            % This is a comment
            @article{test, title = {Hello}}
            """

        let result = highlighter.highlight(bibtex)

        #expect(String(result.characters).contains("% This is a comment"))
    }

    @Test("When highlighting multiple entries, then every entry type remains present")
    func highlightWithMultipleEntries() {
        let highlighter = BibTeXHighlighter()
        let bibtex = """
            @article{entry1, title = {First}}
            @book{entry2, title = {Second}}
            """

        let result = highlighter.highlight(bibtex)
        let text = String(result.characters)

        #expect(text.contains("@article"))
        #expect(text.contains("@book"))
    }

    @Test("When highlighting nested braces, then nested value text remains present")
    func highlightWithNestedBraces() {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, title = {Hello {Nested} World}}"

        let result = highlighter.highlight(bibtex)

        #expect(String(result.characters).contains("Nested"))
    }

    @Test("When highlighting inline math, then its mathematical content remains present")
    func highlightWithMath() {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, title = {Energy $E = mc^2$}}"

        let result = highlighter.highlight(bibtex)

        #expect(String(result.characters).contains("E = mc^2"))
    }

    // MARK: - BibTeXEntry Extension Tests

    @Test(
        "When using the entry highlighting convenience method, then it returns nonempty attributed text"
    )
    func entryHighlightedMethod() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )

        let result = entry.highlighted()

        #expect(!(result.characters.isEmpty))
    }

    @Test(
        "When the entry convenience method receives a theme, then it returns nonempty attributed text"
    )
    func entryHighlightedWithTheme() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )

        let result = entry.highlighted(theme: MonokaiTheme())

        #expect(!(result.characters.isEmpty))
    }

    @Test(
        "When the entry convenience method receives formatting styles, then each result is nonempty"
    )
    func entryHighlightedWithStyle() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )

        let compact = entry.highlighted(style: .compact)
        let aligned = entry.highlighted(style: .aligned)

        #expect(!(compact.characters.isEmpty))
        #expect(!(aligned.characters.isEmpty))
    }

    @Test("When the entry convenience method receives color schemes, then each result is nonempty")
    func entryHighlightedWithColorScheme() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )

        let light = entry.highlighted(colorScheme: .light)
        let dark = entry.highlighted(colorScheme: .dark)

        #expect(!(light.characters.isEmpty))
        #expect(!(dark.characters.isEmpty))
    }

    @Test(
        "When highlighting Unicode BibTeX with distinct theme attributes, then every token range receives its exact mapping"
    )
    func highlightingAppliesExactTokenAttributes() throws {
        let theme = AttributeTestTheme()
        let bibtex = #"""
            @article{flight, title = {Café \textbf{Rocket} $x$ K\"orper \& \begin{equation}y\end{equation}}, year = 2026, month = jan}
            % note
            @string{name = "Proceedings"}
            """#
        let tokens = BibTeXTokenizer().tokenize(bibtex)
        let highlighted = BibTeXHighlighter(theme: theme).highlight(bibtex)

        let expectedTokenKinds: Set<BibTeXToken> = [
            .entryType, .citationKey, .fieldName, .string, .number, .operator,
            .punctuation, .comment, .special, .constant, .command, .math,
            .environment, .accent, .specialChar, .whitespace,
        ]
        #expect(expectedTokenKinds.isSubset(of: Set(tokens.map(\.token))))
        func attributedRange(
            for token: BibTeXTokenInfo
        ) throws -> Range<AttributedString.Index> {
            let lower = try #require(
                AttributedString.Index(token.range.lowerBound, within: highlighted)
            )
            let upper = try #require(
                AttributedString.Index(token.range.upperBound, within: highlighted)
            )
            return lower..<upper
        }

        for token in tokens {
            let range = try attributedRange(for: token)
            let attributedToken = highlighted[range]

            #expect(String(attributedToken.characters) == token.text)
            #expect(
                attributedToken.foregroundColor == theme.color(for: token.token),
                "Unexpected color for \(token.token) token \(String(reflecting: token.text))"
            )
        }

        let entryType = try #require(tokens.first { $0.token == .entryType })
        let special = try #require(tokens.first { $0.token == .special })
        let comment = try #require(tokens.first { $0.token == .comment })
        let citationKey = try #require(tokens.first { $0.token == .citationKey })

        #expect(highlighted[try attributedRange(for: entryType)].font == theme.font.bold())
        #expect(highlighted[try attributedRange(for: special)].font == theme.font.bold())
        #expect(highlighted[try attributedRange(for: comment)].font == theme.font.italic())
        #expect(highlighted[try attributedRange(for: citationKey)].font == theme.font)
    }

    // MARK: - Thread Safety Tests

    @Test("When a highlighter crosses a task boundary, then it produces the expected source text")
    func highlighterIsSendable() async {
        let highlighter = BibTeXHighlighter()

        let result = await Task.detached {
            highlighter.highlight("@article{test}")
        }.value

        #expect(!(result.characters.isEmpty))
        #expect(String(result.characters) == "@article{test}")
    }

    @Test("When one highlighter runs concurrently, then every task produces identical text")
    func concurrentHighlighting() async throws {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, title = {Hello}}"

        let results = await withTaskGroup(of: AttributedString.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    highlighter.highlight(bibtex)
                }
            }

            var results: [AttributedString] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        #expect(results.count == 10)

        let firstText = String(try #require(results.first).characters)
        for result in results {
            #expect(String(result.characters) == firstText)
        }
    }

    private struct AttributeTestTheme: BibTeXTheme {
        let name = "Attribute Test"
        let backgroundColor = Color.white
        let entryTypeColor = Color.red
        let citationKeyColor = Color.orange
        let fieldNameColor = Color.yellow
        let stringColor = Color.green
        let numberColor = Color.blue
        let punctuationColor = Color.purple
        let operatorColor = Color.pink
        let commentColor = Color.gray
        let specialColor = Color.cyan
        let constantColor = Color.mint
        let commandColor = Color.indigo
        let mathColor = Color.teal
        let accentColor = Color.brown
        let textColor = Color.black
        let lineNumberColor = Color.secondary
        let selectionColor = Color.accentColor
        let borderColor = Color.clear
        let font = Font.system(size: 17, design: .monospaced)
    }
}
