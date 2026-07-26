//
//  CoreCoverageCompletionTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import Testing

@testable import BibTeXKit

@Suite("Given executable edge paths in BibTeXKit core types")
struct CoreCoverageCompletionTests {
    @Test(
        "Given structurally incomplete directives and entries, when parsed, then the exact deterministic error is reported"
    )
    func parserReportsExactStructuralFailures() {
        let failures: [(source: String, error: BibTeXParser.Error)] = [
            ("@article=key", .missingOpeningBrace(position: 8)),
            (
                "@article{key !}",
                .unexpectedCharacter(character: "!", position: 13)
            ),
            ("@article{key,", .unmatchedBraces(position: 8)),
            ("@article{key,title", .unmatchedBraces(position: 8)),
            (#"@preamble{"x""#, .unmatchedBraces(position: 9)),
            (
                #"@preamble{"x",}"#,
                .unexpectedCharacter(character: ",", position: 13)
            ),
            ("@string{", .unmatchedBraces(position: 7)),
            ("@string{name", .unmatchedBraces(position: 7)),
            (
                "@string{name,",
                .unexpectedCharacter(character: ",", position: 12)
            ),
            (#"@string{name="Ada""#, .unmatchedBraces(position: 7)),
            (
                #"@string{name="Ada" extra}"#,
                .unexpectedCharacter(character: "e", position: 19)
            ),
        ]

        for failure in failures {
            #expect(throws: failure.error, "Source: \(failure.source)") {
                try BibTeXParser.parse(failure.source)
            }
        }
    }

    @Test(
        "Given fieldless and comma-terminated constructs, when parsed, then valid compact syntax remains accepted"
    )
    func parserAcceptsFieldlessEntriesAndTrailingDirectiveCommas() throws {
        let source = """
            @string{name = "Ada",}
            @misc{fieldless}
            @misc{expanded, author = name}
            """

        let entries = try BibTeXParser.parse(source)

        #expect(entries.count == 2)
        #expect(entries[0].citationKey == "fieldless")
        #expect(entries[0].fields.isEmpty)
        #expect(entries[1].author == "Ada")
    }

    @Test(
        "Given TeX quotation ligatures in a parsed field, when conversion is enabled, then both quotation directions are preserved"
    )
    func parserConvertsTeXQuotationLigatures() throws {
        let source = "@misc{quote, title = {``Flight Safety''}}"

        let entry = try #require(BibTeXParser.parse(source).first)

        #expect(entry.title == "“Flight Safety”")
    }

    @Test(
        "Given two missing alternative requirement groups, when validated, then diagnostics are stably ordered"
    )
    func validationOrdersMultipleAlternativeGroups() {
        let entry = BibTeXEntry(type: .inbook, citationKey: "incomplete")

        let result = entry.validate()

        #expect(
            result.missingRequiredAlternatives == [
                ["author", "editor"],
                ["chapter", "pages"],
            ]
        )
        #expect(!result.isValid)
    }

    @Test(
        "Given existing aliases and multiple updates, when fields are set in bulk, then aliases collapse without losing unrelated values"
    )
    func bulkFieldUpdatesCollapseExistingAliases() {
        let original = BibTeXEntry(
            type: .misc,
            citationKey: "updates",
            fields: [
                "AUTHOR": "Old author",
                "Title": "Old title",
                "year": "2025",
            ]
        )

        let updated = original.settingFields([
            "zeta": "Last",
            "author": "New author",
            "alpha": "First",
        ])

        #expect(updated.author == "New author")
        #expect(updated.title == "Old title")
        #expect(updated.year == 2025)
        #expect(updated["alpha"] == "First")
        #expect(updated["zeta"] == "Last")
        #expect(updated.fields.filter { $0.key.lowercased() == "author" }.count == 1)
    }

    @Test(
        "Given malformed case-colliding fields, when values are read and compared, then canonical selection is deterministic"
    )
    func caseCollisionsHaveDeterministicReadAndEqualitySemantics() {
        let aliases = BibTeXEntry(
            type: .misc,
            citationKey: "collision",
            fields: [
                "Title": "Mixed",
                "TITLE": "Upper",
                "title": "Canonical",
            ]
        )
        let canonical = BibTeXEntry(
            type: .misc,
            citationKey: "collision",
            fields: ["title": "Canonical"]
        )

        #expect(aliases.title == "Canonical")
        #expect(aliases == canonical)
        #expect(aliases.hashValue == canonical.hashValue)

        let noncanonicalAliases = BibTeXEntry(
            type: .misc,
            citationKey: "selection",
            fields: [
                "Title": "Mixed",
                "TITLE": "Upper",
            ]
        )
        #expect(noncanonicalAliases.title == "Upper")
    }

    @Test(
        "Given escaped separators and a trailing partial author delimiter, when lists are parsed, then content is not split incorrectly"
    )
    func listParsingPreservesEscapedSeparatorsAndPartialDelimiters() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "lists",
            fields: [
                "author": "Ada Lovelace and",
                "keywords": #"safety\,critical, deterministic"#,
            ]
        )

        #expect(entry.authors == ["Ada Lovelace and"])
        #expect(entry.keywords == [#"safety\,critical"#, "deterministic"])
    }

    @Test(
        "Given one, two, and three authors, when citation summaries render, then conjunction and abbreviation rules are exact"
    )
    func citationAuthorCardinalityIsExact() {
        func entry(authors: String) -> BibTeXEntry {
            BibTeXEntry(
                type: .article,
                citationKey: "authors",
                fields: [
                    "author": authors,
                    "title": "Safety",
                    "journal": "Journal",
                    "year": "2026",
                ]
            )
        }

        #expect(entry(authors: "Ada").citation(style: .apa).hasPrefix("Ada "))
        #expect(
            entry(authors: "Ada and Grace")
                .citation(style: .apa)
                .hasPrefix("Ada & Grace ")
        )
        #expect(
            entry(authors: "Ada and Grace and Katherine")
                .citation(style: .apa)
                .hasPrefix("Ada et al. ")
        )
        #expect(
            entry(authors: "Ada and Grace")
                .citation(style: .ieee)
                .hasPrefix("Ada, Grace ")
        )
    }

    @Test(
        "Given volume and issue metadata, when APA output renders, then the issue remains attached to the volume"
    )
    func apaCitationRetainsIssueNumber() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "issue",
            fields: [
                "journal": "Journal",
                "volume": "42",
                "number": "7",
            ]
        )

        #expect(entry.citation(style: .apa) == "*Journal*, *42*(7).")
    }

    @Test(
        "Given an IEEE name without usable initials, when cited, then the original author spelling is retained"
    )
    func ieeeCitationRetainsNamesWithoutInitials() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "symbols",
            fields: ["author": "Surname, ---"]
        )

        #expect(entry.citation(style: .ieee) == "Surname, ---")
    }

    @Test(
        "Given entries without authors or titles, when ordered, then citation keys provide a stable fallback"
    )
    func comparableUsesEmptyMetadataFallbacks() {
        let first = BibTeXEntry(type: .misc, citationKey: "alpha")
        let second = BibTeXEntry(type: .misc, citationKey: "beta")

        #expect(first < second)
        #expect(!(second < first))
    }

    @Test(
        "Given every entry type, when sorting ranks are inspected, then the standard catalog precedes custom types without gaps"
    )
    func sortingRanksFormAStableTotalOrder() {
        let types = BibTeXEntryType.allStandardTypes + [.custom("extension")]

        #expect(types.map(\.sortingRank) == Array(0...17))
    }

    @Test(
        "Given malformed accent targets and incomplete empty groups, when converted, then conversion is lossless and terminating"
    )
    func latexConversionPreservesMalformedCommandStructure() {
        #expect(LaTeXConverter.toUnicode(#"\^{\q}"#) == #"\^{\q}"#)
        #expect(LaTeXConverter.toUnicode(#"\alpha{x}"#) == "αx")
        #expect(LaTeXConverter.toUnicode(#"\alpha{{"#) == "α{{")
    }
}

@Suite("Given malformed and boundary-sensitive tokenizer input")
struct TokenizerCoverageCompletionTests {
    private let tokenizer = BibTeXTokenizer()

    @Test(
        "Given malformed quoted values and incomplete commands, when tokenized, then scanning remains lossless and makes progress"
    )
    func malformedQuotedValuesAndCommandsRemainLossless() {
        let sources = [
            #"@misc{k,title="unterminated}"#,
            "\\",
            #"\"# + "?",
            #"\begin{equation"#,
            #"@misc{k,title="$$x{rest"}"#,
        ]

        for source in sources {
            let tokens = tokenizer.tokenize(source)

            #expect(!tokens.isEmpty, "Source: \(source)")
            #expect(tokens.map(\.text).joined() == source, "Source: \(source)")
            #expect(tokens.allSatisfy { !$0.text.isEmpty }, "Source: \(source)")
        }
    }

    @Test(
        "Given grouped accents, starred commands, and ungrouped environments, when tokenized, then command boundaries are exact"
    )
    func commandBoundariesAreExact() {
        let source = #"\u{a} \section*{Title} \begin text"#
        let tokens = tokenizer.tokenize(source)

        #expect(tokens.map(\.text).joined() == source)
        #expect(tokens.contains { $0.token == .accent && $0.text == #"\u{a}"# })
        #expect(tokens.contains { $0.token == .command && $0.text == #"\section*"# })
        #expect(tokens.contains { $0.token == .environment && $0.text == #"\begin"# })
    }

    @Test(
        "Given inline and display math with escaped delimiters, when tokenized in each value context, then math ranges remain exact"
    )
    func escapedMathDelimitersRemainInsideMathTokens() {
        let source = #"$$x\$y$$ @misc{k,a={$x\$y$},b="$$p\$q$$"}"#
        let tokens = tokenizer.tokenize(source)
        let math = tokens.filter { $0.token == .math }.map(\.text)

        #expect(tokens.map(\.text).joined() == source)
        #expect(math == [#"$$x\$y$$"#, #"$x\$y$"#, #"$$p\$q$$"#])
    }

    @Test(
        "Given an unterminated display expression inside a braced value, when tokenized, then closing braces remain structural"
    )
    func unterminatedDisplayMathCannotConsumeClosingBraces() {
        let source = "@misc{k,title={$$x$y}}"
        let tokens = tokenizer.tokenize(source)

        #expect(tokens.map(\.text).joined() == source)
        #expect(tokens.contains { $0.token == .math && $0.text == "$$x$y" })
        #expect(tokens.suffix(2).allSatisfy { $0.token == .punctuation })
    }

    @Test(
        "Given every mixed-case month at top level, when tokenized, then all twelve names are constants"
    )
    func topLevelMonthsAreRecognizedCaseInsensitively() {
        let source = "JAN Feb MAR apr MAY jun JUL aug SEP oct NOV dec"
        let nonWhitespace = tokenizer.tokenize(source).filter { $0.token != .whitespace }

        #expect(nonWhitespace.count == 12)
        #expect(nonWhitespace.allSatisfy { $0.token == .constant })
        #expect(nonWhitespace.map(\.text).joined(separator: " ") == source)
    }

    @Test(
        "Given a dangling identifier followed only by a comment, when tokenized, then lookahead terminates at end of input"
    )
    func fieldLookaheadTerminatesAfterTrailingComment() {
        let source = "@misc{k, dangling   % trailing comment"
        let tokens = tokenizer.tokenize(source)

        #expect(tokens.map(\.text).joined() == source)
        #expect(tokens.contains { $0.text == "dangling" && $0.token == .text })
        #expect(tokens.last?.token == .comment)
    }
}
