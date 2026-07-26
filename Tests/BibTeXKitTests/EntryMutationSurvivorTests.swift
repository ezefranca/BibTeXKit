//
//  EntryMutationSurvivorTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import Testing

@testable import BibTeXKit

@Suite("Given BibTeX entries at mutation-sensitive behavioral boundaries")
struct EntryMutationSurvivorTests {

    @Test(
        "Given an in-book satisfying both alternative groups, when validated, then no alternative is reported missing"
    )
    func satisfiedAlternativeRequirementsProduceNoDiagnostics() {
        let entry = BibTeXEntry(
            type: .inbook,
            citationKey: "complete",
            fields: [
                "editor": "E. Editor",
                "title": "Collected Work",
                "pages": "1--10",
                "publisher": "Example Press",
                "year": "2026",
            ]
        )

        let result = entry.validate()

        #expect(result.isValid)
        #expect(result.missingRequired.isEmpty)
        #expect(result.missingRequiredAlternatives.isEmpty)
    }

    @Test(
        "Given every case spelling of an existing field, when updated singly or in bulk, then only the lowercase key remains"
    )
    func updatesCollapseExistingAliasesToCanonicalStorage() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "aliases",
            fields: [
                "AUTHOR": "Uppercase",
                "Author": "Mixed",
                "author": "Canonical",
            ]
        )

        let singleUpdate = entry.settingField("AUTHOR", to: "Updated")
        let bulkUpdate = entry.settingFields(["AUTHOR": "Updated"])

        #expect(singleUpdate.fields == ["author": "Updated"])
        #expect(bulkUpdate.fields == ["author": "Updated"])
    }

    @Test(
        "Given many colliding bulk field spellings, when updated, then every explicit lowercase spelling wins deterministically"
    )
    func bulkUpdatesPreferExplicitCanonicalSpellings() {
        let canonicalNames = [
            "alpha",
            "bravo",
            "charlie",
            "delta",
            "echo",
            "foxtrot",
            "golf",
            "hotel",
            "india",
            "juliet",
            "lima",
            "mike",
        ]
        var updates: [String: String] = [:]
        var expected: [String: String] = [:]

        for name in canonicalNames {
            updates[name.uppercased()] = "\(name)-uppercase"
            updates[name.prefix(1).uppercased() + name.dropFirst()] = "\(name)-mixed"
            updates[name] = "\(name)-canonical"
            expected[name] = "\(name)-canonical"
        }

        // U+212A KELVIN SIGN case-folds to "k" but sorts after ASCII "k".
        // This proves canonical preference rather than relying on ASCII order.
        updates["\u{212A}"] = "kelvin-symbol"
        updates["k"] = "kelvin-canonical"
        expected["k"] = "kelvin-canonical"

        let updated = BibTeXEntry(
            type: .misc,
            citationKey: "bulk"
        ).settingFields(updates)

        #expect(updated.fields == expected)
    }

    @Test(
        "Given only noncanonical aliases in a bulk update, when applied, then the lexicographically first spelling supplies the value"
    )
    func bulkUpdatesResolveNoncanonicalAliasesDeterministically() {
        let updated = BibTeXEntry(
            type: .misc,
            citationKey: "bulk-aliases"
        ).settingFields([
            "TITLE": "Uppercase",
            "Title": "Mixed",
        ])

        #expect(updated.fields == ["title": "Uppercase"])
    }

    @Test(
        "Given only noncanonical aliases in stored fields, when compared and hashed, then the lexicographically first spelling supplies the value"
    )
    func semanticFieldsResolveNoncanonicalAliasesDeterministically() {
        let aliases = BibTeXEntry(
            type: .misc,
            citationKey: "semantic",
            fields: [
                "TITLE": "Uppercase",
                "Title": "Mixed",
            ]
        )
        let canonical = BibTeXEntry(
            type: .misc,
            citationKey: "semantic",
            fields: ["title": "Uppercase"]
        )

        #expect(aliases == canonical)
        #expect(Set([aliases, canonical]).count == 1)
    }

    @Test(
        "Given leading and repeated empty keyword segments, when parsed, then only trimmed nonempty keywords remain"
    )
    func emptyKeywordSegmentsAreDiscardedSafely() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "empty-keywords",
            fields: ["keywords": ",; alpha,, ; beta;"]
        )

        #expect(entry.keywords == ["alpha", "beta"])
    }

    @Test(
        "Given an unmatched closing brace before a keyword separator, when parsed, then the separator remains top-level"
    )
    func unmatchedClosingBraceDoesNotHideKeywordSeparators() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "unmatched-keywords",
            fields: ["keywords": "alpha}, beta"]
        )

        #expect(entry.keywords == ["alpha}", "beta"])
    }

    @Test(
        "Given entries whose author lists have opposite endpoints, when ordered, then only each first author determines precedence"
    )
    func comparisonUsesTheFirstParsedAuthor() {
        let zuluFirst = BibTeXEntry(
            type: .misc,
            citationKey: "same",
            fields: ["author": "Zulu and Alpha"]
        )
        let alphaFirst = BibTeXEntry(
            type: .misc,
            citationKey: "same",
            fields: ["author": "Alpha and Zulu"]
        )

        #expect(!(zuluFirst < alphaFirst))
        #expect(alphaFirst < zuluFirst)
    }

    @Test(
        "Given an escaped opening brace before an author delimiter, when parsed, then the escaped brace does not suppress the delimiter"
    )
    func escapedBraceDoesNotChangeAuthorNesting() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "escaped-author",
            fields: ["author": #"A \{ and B"#]
        )

        #expect(entry.authors == [#"A \{"#, "B"])
    }

    @Test(
        "Given an author delimiter followed only by whitespace, when parsed, then the trailing empty author is discarded without trapping"
    )
    func trailingAuthorDelimiterIsSafe() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "trailing-author",
            fields: ["author": "Alice and "]
        )

        #expect(entry.authors == ["Alice"])
    }

    @Test(
        "Given a two-component comma-form author, when formatted for IEEE, then initials precede the surname"
    )
    func ieeeFormatsTwoComponentAuthorNames() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "ieee-author",
            fields: ["author": "Lovelace, Ada"]
        )

        #expect(entry.citation(style: .ieee) == "A. Lovelace")
    }

    @Test(
        "Given equal entries except for their first field key, when ordered both ways, then ordering is antisymmetric"
    )
    func comparisonOrdersBothSemanticFieldCollectionsAscending() {
        let alpha = BibTeXEntry(
            type: .misc,
            citationKey: "same",
            fields: [
                "alpha": "same",
                "omega": "same",
            ]
        )
        let beta = BibTeXEntry(
            type: .misc,
            citationKey: "same",
            fields: [
                "beta": "same",
                "omega": "same",
            ]
        )

        #expect(alpha < beta)
        #expect(!(beta < alpha))
    }

    @Test(
        "Given one semantic field list that is a strict prefix of another, when ordered, then the shorter list precedes safely"
    )
    func comparisonHandlesStrictPrefixFieldCollections() {
        let shorter = BibTeXEntry(
            type: .misc,
            citationKey: "same",
            fields: ["alpha": "same"]
        )
        let longer = BibTeXEntry(
            type: .misc,
            citationKey: "same",
            fields: [
                "alpha": "same",
                "omega": "same",
            ]
        )

        #expect(shorter < longer)
        #expect(!(longer < shorter))
    }
}
