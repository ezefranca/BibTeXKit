//
//  CrashSafetyTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import SwiftUI
import Testing

@testable import BibTeXKit

@Suite("Given hostile or resource-intensive public input")
struct CrashSafetyTests {
    @Test("Given deeply composed adaptive themes, when resolved and inspected, then work stays off the call stack")
    func deeplyNestedAdaptiveThemesResolveIteratively() {
        var theme: any BibTeXTheme = MonokaiTheme()

        for _ in 0..<20_000 {
            theme = AdaptiveTheme(light: theme, dark: theme)
        }

        #expect(theme.resolved(for: .light).name == "Monokai")
        #expect(theme.resolved(for: .dark).name == "Monokai")
        #expect(theme.name == "Monokai")
    }

    @Test("Given deeply nested BibTeX, when parsed, tokenized, and converted, then every scanner completes iteratively")
    func deeplyNestedInputCompletesIteratively() throws {
        let openingBraces = String(repeating: "{", count: 50_000)
        let closingBraces = String(repeating: "}", count: 50_000)
        let source = "@misc{deep,title={\(openingBraces)x\(closingBraces)}}"

        let entries = try BibTeXParser.parse(source)
        let entry = try #require(entries.first)
        let tokens = BibTeXTokenizer().tokenize(source)

        #expect(entry.citationKey == "deep")
        #expect(entry.title?.contains("x") == true)
        #expect(tokens.map(\.text).joined() == source)
        #expect(
            LaTeXConverter.toUnicode(openingBraces + "x" + closingBraces)
                == "x"
        )
    }

    @Test("Given deeply nested incomplete input, when every parser scans it, then failure is reported without recursion")
    func deeplyNestedIncompleteInputFailsWithoutRecursion() {
        let openingBraces = String(repeating: "{", count: 50_000)
        let source = "@misc{deep,title={\(openingBraces)x"

        #expect(throws: BibTeXParser.Error.self) {
            try BibTeXParser.parse(source)
        }
        #expect(BibTeXTokenizer().tokenize(source).map(\.text).joined() == source)
        #expect(
            LaTeXConverter.toUnicode(openingBraces + "x")
                == openingBraces + "x"
        )
    }

    @Test("Given malformed state transitions, when public scanners consume them, then each input is preserved or rejected deterministically")
    func malformedStateTransitionsAlwaysComplete() {
        let fragments = [
            "", "@", "@ ", "@article", "@article{", "@article(",
            "@article{,", "@article{key,", "@article{key,title=",
            "\"", "\"{", "\"}", "{", "}", "(", ")", "\\", "\\{",
            "\\}", "$", "$$", "%", "%\n", "#", "=", "\0", "\u{2028}",
        ]
        var corpus = fragments
        corpus.reserveCapacity(fragments.count * fragments.count)

        for prefix in fragments {
            for suffix in fragments {
                corpus.append(prefix + suffix)
            }
        }

        let tokenizer = BibTeXTokenizer()
        for source in corpus {
            #expect(tokenizer.tokenize(source).map(\.text).joined() == source)
            #expect(tokenizer.tokenizePairs(source).map(\.text).joined() == source)
            _ = try? BibTeXParser.parse(source)
            _ = LaTeXConverter.toUnicode(source)
            _ = LaTeXConverter.toLaTeX(source)
            _ = DOIDetector.extractAllDOIs(from: source)
        }
    }

    @Test("Given many fields sharing a large value, when formatted, then capacity estimation cannot overflow or alter output")
    func sharedLargeFieldValuesFormatLosslessly() {
        let value = String(repeating: "a", count: 16_384)
        var fields: [String: String] = [:]

        for index in 0..<64 {
            fields["field\(index)"] = value
        }

        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "large",
            fields: fields
        )
        let formatted = entry.formatted(style: .minimal)

        #expect(formatted.hasPrefix("@misc{large,"))
        #expect(formatted.hasSuffix("}"))
        #expect(formatted.contains("field0={\(value)}"))
        #expect(formatted.contains("field63={\(value)}"))
    }

    @MainActor
    @Test("Given non-finite and negative layout dimensions, when the view renders, then invalid geometry is neutralized")
    func invalidLayoutDimensionsAreNeutralized() throws {
        let configuration = BibTeXViewConfiguration(
            showLineNumbers: true,
            maxHeight: .nan,
            minHeight: -.infinity,
            contentPadding: EdgeInsets(
                top: .nan,
                leading: .infinity,
                bottom: -.infinity,
                trailing: 8
            ),
            cornerRadius: -1,
            lineSpacing: .infinity,
            borderWidth: .nan
        )

        #expect(configuration.renderedMinimumHeight == nil)
        #expect(configuration.renderedMaximumHeight == nil)
        #expect(configuration.renderedCornerRadius == 0)
        #expect(configuration.renderedLineSpacing == 0)
        #expect(configuration.renderedBorderWidth == 0)
        #expect(configuration.renderedContentPadding.top == 0)
        #expect(configuration.renderedContentPadding.leading == 0)
        #expect(configuration.renderedContentPadding.bottom == 0)
        #expect(configuration.renderedContentPadding.trailing == 8)

        let content = BibTeXView(
            bibtex: "@misc{safety,\n  title = {Safe}\n}",
            configuration: configuration
        )
        .frame(width: 320, height: 180)
        let renderer = ImageRenderer(content: content)

        #expect(renderer.cgImage != nil)
    }
}
