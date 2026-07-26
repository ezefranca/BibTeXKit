//
//  MutationClosureTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Testing

@testable import BibTeXKit

@Suite("Given parser and converter mutation boundaries")
struct MutationClosureTests {
    @Test(
        "When a structural token ends at end-of-input, then parsing returns an error without indexing past the buffer",
        arguments: [
            "@",
            "@misc{k,",
            "@misc{k,title",
            #"@preamble{"value""#,
            "@string{",
            "@string{name",
            #"@string{name="value""#,
            "@misc{k,title=",
            "@misc{k,year=2024",
            "@misc{k,month=unknown",
        ]
    )
    func terminalParserBoundariesThrow(_ source: String) {
        #expect(throws: BibTeXParser.Error.self) {
            try BibTeXParser.parse(source)
        }
    }

    @Test("When a delimiter-free comment ends the input, then it is ignored safely")
    func delimiterFreeCommentAtEndOfInputIsIgnored() throws {
        let entries = try BibTeXParser.parse("@comment")

        #expect(entries.isEmpty)
    }

    @Test("When a string directive has a trailing comma, then the comma remains valid syntax")
    func stringDirectiveAcceptsTrailingComma() throws {
        let source = #"""
            @string{name = "Journal of Testing",}
            @misc{sample, title = name}
            """#

        let entry = try #require(BibTeXParser.parse(source).first)

        #expect(entry.title == "Journal of Testing")
    }

    @Test(
        "When a padded string constant is concatenated inside another constant, then definition boundaries are trimmed before concatenation"
    )
    func stringConstantsTrimBeforeNestedConcatenation() throws {
        let source = #"""
            @string{padded = " A "}
            @string{joined = "left" # padded # "right"}
            @misc{sample, title = joined}
            """#

        let entry = try #require(BibTeXParser.parse(source).first)

        #expect(entry.title == "leftAright")
    }

    @Test(
        "When LaTeX conversion is disabled for a string constant, then expansion retains the original command"
    )
    func disabledLaTeXConversionAppliesToStringDefinitions() throws {
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false
        let source = #"""
            @string{symbol = {\alpha}}
            @misc{sample, title = symbol}
            """#

        let entry = try #require(BibTeXParser.parse(source, options: options).first)

        #expect(entry.title == #"\alpha"#)
    }

    @Test(
        "When a quoted value closes braces in reverse order, then parsing rejects the malformed nesting"
    )
    func quotedValueRejectsReversedBraceNesting() {
        #expect(throws: BibTeXParser.Error.self) {
            try BibTeXParser.parse(#"@misc{sample, title = "}{", year = 2024}"#)
        }
    }

    @Test("When a quoted value is empty, then delimiter stripping returns an empty value safely")
    func emptyQuotedValueTrimsWithoutCrossingStringBounds() throws {
        let entry = try #require(
            BibTeXParser.parse(#"@misc{sample, title = ""}"#).first
        )

        #expect(entry.title == "")
    }

    @Test(
        "When an identifier contains a control scalar, then parsing rejects it rather than admitting an unsafe field name"
    )
    func controlScalarsAreRejectedInsideIdentifiers() {
        let source = "@misc{sample, ti\u{0000}tle = {unsafe}}"

        #expect(throws: BibTeXParser.Error.self) {
            try BibTeXParser.parse(source)
        }
    }

    @Test(
        "When a field contains a doubled closing apostrophe, then parser conversion produces a closing typographic quote"
    )
    func parserDetectsDoubledClosingApostrophe() throws {
        let entry = try #require(
            BibTeXParser.parse(#"@misc{sample, title = {Pilots'' report}}"#).first
        )

        #expect(entry.title == "Pilots” report")
    }

    @Test(
        "Given plain and LaTeX-sensitive field values, when conversion is preflighted, then only syntax-bearing values select the converter",
        arguments: [
            ("O'Connor", false),
            ("well-formed", false),
            ("plain text", false),
            (#"M\"uller"#, true),
            ("`quoted", true),
            ("{N}ASA", true),
            ("Pilots'' report", true),
            ("pages 1--2", true),
        ]
    )
    func laTeXConversionPreflightClassifiesExactSyntax(
        _ value: String,
        _ expected: Bool
    ) {
        #expect(
            BibTeXParser().mayContainLaTeXSyntax(value) == expected,
            "Value: \(value)"
        )
    }

    @Test(
        "When an accent or empty delimiter group ends prematurely, then conversion preserves the incomplete source without indexing past the buffer",
        arguments: [
            (#"\'"#, #"\'"#),
            (#"\' "#, #"\' "#),
            (#"\'{"#, #"\'{"#),
            ("\\'\\", "\\'\\"),
            (#"\alpha{"#, "α{"),
        ]
    )
    func incompleteLaTeXSyntaxIsPreserved(_ input: String, _ expected: String) {
        #expect(LaTeXConverter.toUnicode(input) == expected)
    }
}
