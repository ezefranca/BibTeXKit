//
//  PublicAPIContractTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import SwiftUI
import Testing

@testable import BibTeXKit

@Suite("Given BibTeXKit public API values")
struct PublicAPIContractTests {
    struct ParserErrorScenario: Sendable {
        let error: BibTeXParser.Error
        let expectedDescription: String
    }

    @Test(
        "Given publication metadata, when convenience fields are read, then their original textual values are preserved"
    )
    func publicationFieldAccessorsPreserveValues() {
        let entry = BibTeXEntry(
            type: .inproceedings,
            citationKey: "lovelace1843",
            fields: [
                "author": "Ada Lovelace",
                "title": "Notes",
                "booktitle": "Scientific Memoirs",
                "year": " 1843 ",
                "volume": "3",
                "number": "4",
                "pages": "666--731",
                "month": "September",
            ]
        )

        #expect(entry.year == 1843)
        #expect(entry.yearString == " 1843 ")
        #expect(entry.booktitle == "Scientific Memoirs")
        #expect(entry.volume == "3")
        #expect(entry.number == "4")
        #expect(entry.pages == "666--731")
        #expect(entry.month == "September")
    }

    @Test(
        "Given complete and incomplete entries, when validation results are queried, then validity reflects required-field diagnostics"
    )
    func validationResultValidityReflectsMissingRequirements() {
        let complete = BibTeXEntry(
            type: .article,
            citationKey: "complete",
            fields: [
                "author": "Ada Lovelace",
                "title": "Notes",
                "journal": "Scientific Memoirs",
                "year": "1843",
            ]
        )
        let incomplete = complete.settingField("journal", to: nil)

        let completeResult = complete.validate()
        let incompleteResult = incomplete.validate()

        #expect(completeResult.isValid)
        #expect(completeResult.missingRequired.isEmpty)
        #expect(!(incompleteResult.isValid))
        #expect(incompleteResult.missingRequired == ["journal"])
    }

    @Test(
        "Given an entry, when its description is requested, then it equals canonical standard formatting"
    )
    func entryDescriptionUsesCanonicalFormatting() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "description",
            fields: [
                "title": "A deterministic description",
                "year": "2026",
            ]
        )

        #expect(entry.description == entry.formatted(style: .standard))
        #expect(
            entry.description == """
                @misc{description,
                    title = {A deterministic description},
                    year = {2026}
                }
                """)
    }

    @Test(
        "Given every parser error, when its localized description is requested, then precise context is reported",
        arguments: [
            ParserErrorScenario(
                error: .emptyInput,
                expectedDescription: "The input string is empty"
            ),
            ParserErrorScenario(
                error: .noEntriesFound,
                expectedDescription: "No valid BibTeX entries were found"
            ),
            ParserErrorScenario(
                error: .invalidEntryType(position: 7),
                expectedDescription: "Invalid entry type at position 7"
            ),
            ParserErrorScenario(
                error: .missingCitationKey(entryType: "article", position: 11),
                expectedDescription: "Missing citation key for @article at position 11"
            ),
            ParserErrorScenario(
                error: .missingOpeningBrace(position: 13),
                expectedDescription: "Missing opening brace at position 13"
            ),
            ParserErrorScenario(
                error: .unmatchedBraces(position: 17),
                expectedDescription: "Unmatched braces at position 17"
            ),
            ParserErrorScenario(
                error: .invalidFieldValue(field: "title", position: 19),
                expectedDescription: "Invalid value for field 'title' at position 19"
            ),
            ParserErrorScenario(
                error: .unexpectedCharacter(character: "!", position: 23),
                expectedDescription: "Unexpected character '!' at position 23"
            ),
        ]
    )
    func parserErrorsProvidePreciseDescriptions(_ scenario: ParserErrorScenario) {
        #expect(scenario.error.errorDescription == scenario.expectedDescription)
    }

    @Test(
        "Given every token kind, when its description is requested, then the documented human-readable label is returned"
    )
    func tokenDescriptionsCoverTheCompleteVocabulary() {
        let expectedDescriptions: [BibTeXToken: String] = [
            .entryType: "Entry Type",
            .citationKey: "Citation Key",
            .fieldName: "Field Name",
            .string: "String Value",
            .number: "Number",
            .operator: "Operator",
            .punctuation: "Punctuation",
            .comment: "Comment",
            .special: "Special Directive",
            .constant: "Constant",
            .command: "LaTeX Command",
            .math: "Math Mode",
            .environment: "Environment",
            .accent: "Accent",
            .specialChar: "Special Character",
            .whitespace: "Whitespace",
            .text: "Text",
        ]

        #expect(expectedDescriptions.count == BibTeXToken.allCases.count)
        for token in BibTeXToken.allCases {
            #expect(token.description == expectedDescriptions[token])
        }
    }

    #if os(macOS)
    @MainActor
    @Test(
        "Given raw BibTeX and an explicit theme, when inline text renders, then highlighted content produces an image"
    )
    func inlineTextWithExplicitThemeRenders() throws {
        let content = BibTeXText(
            bibtex: "@article{render, title = {Inline text}, year = 2026}"
        )
        .bibTeXTheme(MonokaiTheme())
        .frame(width: 480, height: 100)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1

        let image = try #require(renderer.cgImage)
        #expect(image.width == 480)
        #expect(image.height == 100)
    }

    @MainActor
    @Test(
        "Given an entry without an explicit theme, when inline text renders in both color schemes, then each adaptive rendering succeeds"
    )
    func inlineEntryTextRendersWithDefaultThemes() throws {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "adaptive",
            fields: [
                "author": "Ada Lovelace",
                "title": "Notes",
                "journal": "Scientific Memoirs",
                "year": "1843",
            ]
        )

        for colorScheme in [ColorScheme.light, .dark] {
            let content = BibTeXText(entry: entry, style: .minimal)
                .environment(\.colorScheme, colorScheme)
                .frame(width: 480, height: 100)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 1

            let image = try #require(renderer.cgImage)
            #expect(image.width == 480)
            #expect(image.height == 100)
        }
    }
    #endif
}
