//
//  MutationRegressionTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Testing

@testable import BibTeXKit

@Suite("Given mutation-sensitive public behavior")
struct MutationRegressionTests {
    @Test("When strict options are selected, then every strict policy is explicit")
    func strictOptionsExposeEveryPolicy() {
        let options = BibTeXParser.Options.strict

        #expect(options.preserveRawBibTeX)
        #expect(options.normalizeFieldNames)
        #expect(options.stripDelimiters)
        #expect(!options.convertLaTeXToUnicode)
        #expect(options.requireEntries)
    }

    @Test("When only requireEntries is supplied, then the remaining initializer defaults are retained")
    func requireEntriesInitializerRetainsDefaults() {
        let options = BibTeXParser.Options(requireEntries: true)

        #expect(!options.preserveRawBibTeX)
        #expect(options.normalizeFieldNames)
        #expect(options.stripDelimiters)
        #expect(options.convertLaTeXToUnicode)
        #expect(options.requireEntries)
    }

    @Test(
        "When single-line formatting presets are inspected, then neither requests equals-sign alignment"
    )
    func singleLineFormattingPresetsDisableAlignment() {
        #expect(!BibTeXEntry.FormattingStyle.compact.alignEquals)
        #expect(!BibTeXEntry.FormattingStyle.minimal.alignEquals)
        #expect(BibTeXEntry.FormattingStyle.aligned.alignEquals)
    }

    @Test(
        "When an uppercase preamble directive is tokenized, then ASCII case folding retains special-directive semantics"
    )
    func uppercasePreambleRemainsSpecial() {
        let source = #"@PREAMBLE{"Generated bibliography"}"#
        let tokens = BibTeXTokenizer().tokenize(source)

        #expect(tokens.first?.token == .special)
        #expect(tokens.first?.text == "@PREAMBLE")
        #expect(tokens.allSatisfy { $0.token != .citationKey })
        #expect(tokens.map(\.text).joined() == source)
    }

    @Test(
        "When a padded LaTeX string constant is expanded, then whitespace is trimmed and capitalization groups survive conversion"
    )
    func stringConstantTrimsAndPreservesGroupingBraces() throws {
        let source = #"""
            @string{shared = "  Caf\'{e} {N}ASA  "}
            @misc{constant, title = shared}
            """#

        let entry = try #require(BibTeXParser.parse(source).first)

        #expect(entry.title == "Café {N}ASA")
    }

    @Test(
        "When volume and issue metadata are cited, then each supported summary retains the issue number"
    )
    func citationStylesRetainIssueNumber() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "lovelace2026",
            fields: [
                "author": "Ada Lovelace",
                "title": "Deterministic Engines",
                "journal": "Journal of Flight Control",
                "volume": "42",
                "number": "7",
                "pages": "10--19",
                "year": "2026",
            ]
        )

        #expect(
            entry.citation(style: .mla)
                == "Ada Lovelace. \"Deterministic Engines.\" "
                + "*Journal of Flight Control*, vol. 42, no. 7, 2026, pp. 10--19."
        )
        #expect(
            entry.citation(style: .chicago)
                == "Ada Lovelace. \"Deterministic Engines.\" "
                + "*Journal of Flight Control* 42, no. 7 (2026): 10--19."
        )
        #expect(
            entry.citation(style: .ieee)
                == "Ada Lovelace \"Deterministic Engines,\" "
                + "*Journal of Flight Control*, vol. 42, no. 7, pp. 10--19, 2026."
        )
        #expect(
            entry.citation(style: .harvard)
                == "Ada Lovelace (2026) 'Deterministic Engines', "
                + "*Journal of Flight Control*, vol. 42, no. 7, pp. 10--19."
        )
    }

    @Test(
        "When Chicago metadata has no journal, then its year and pages remain visible through the fallback"
    )
    func chicagoCitationRetainsFallbackYearAndPages() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "fallback2026",
            fields: [
                "year": "2026",
                "pages": "10--19",
            ]
        )

        #expect(entry.citation(style: .chicago) == "(2026). 10--19.")
    }

    @Test(
        "When a retained group precedes a presentation group, then preservation does not leak across the boundary"
    )
    func adjacentGroupsResetBracePreservation() {
        #expect(LaTeXConverter.toUnicode("{AB}{C}") == "{AB}C")
    }
}
