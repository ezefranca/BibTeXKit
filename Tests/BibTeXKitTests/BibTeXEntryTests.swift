//
//  BibTeXEntryTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation
import Testing

@testable import BibTeXKit

@Suite("Given a BibTeX entry value")
struct BibTeXEntryTests {

    private struct ReadSnapshot: Equatable, Sendable {
        let title: String?
        let authors: [String]
        let year: Int?
        let fieldCount: Int
        let formatted: String
    }

    // MARK: - Test Data

    private var sampleEntry: BibTeXEntry {
        BibTeXEntry(
            type: .article,
            citationKey: "einstein1905",
            fields: [
                "author": "Albert Einstein",
                "title": "Zur Elektrodynamik bewegter Körper",
                "journal": "Annalen der Physik",
                "volume": "17",
                "pages": "891--921",
                "year": "1905",
                "doi": "10.1002/andp.19053221004",
            ]
        )
    }

    private var bookEntry: BibTeXEntry {
        BibTeXEntry(
            type: .book,
            citationKey: "knuth1997",
            fields: [
                "author": "Donald E. Knuth",
                "title": "The Art of Computer Programming",
                "publisher": "Addison-Wesley",
                "year": "1997",
                "edition": "3rd",
            ]
        )
    }

    private func comparableEntry(
        type: BibTeXEntryType = .article,
        citationKey: String = "key",
        year: String? = "2026",
        author: String? = "Author",
        title: String? = "Title",
        extraFields: [String: String] = [:]
    ) -> BibTeXEntry {
        var fields = extraFields
        fields["year"] = year
        fields["author"] = author
        fields["title"] = title
        return BibTeXEntry(
            type: type,
            citationKey: citationKey,
            fields: fields
        )
    }

    // MARK: - Initialization Tests

    @Test(
        "Given a type, citation key, and fields, when an entry is initialized, then every value is stored"
    )
    func basicInitialization() {
        let entry = sampleEntry

        #expect(entry.type == .article)
        #expect(entry.citationKey == "einstein1905")
        #expect(entry.fields.count == 7)
    }

    @Test(
        "Given original BibTeX source, when an entry is initialized, then the raw source is retained"
    )
    func initializationWithRawBibTeX() {
        let raw = "@article{test, author = {Test}}"
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["author": "Test"],
            rawBibTeX: raw
        )

        #expect(entry.rawBibTeX == raw)
    }

    // MARK: - Subscript Access Tests

    @Test(
        "Given an entry with fields, when subscripting by name, then values are returned and missing fields are nil"
    )
    func subscriptAccess() {
        let entry = sampleEntry

        #expect(entry["author"] == "Albert Einstein")
        #expect(entry["title"] == "Zur Elektrodynamik bewegter Körper")
        #expect(entry["year"] == "1905")
        #expect(entry["nonexistent"] == nil)
    }

    @Test(
        "Given lowercase field keys, when subscripting with case variants, then the same values are returned"
    )
    func subscriptCaseInsensitive() {
        let entry = sampleEntry

        #expect(entry["AUTHOR"] == "Albert Einstein")
        #expect(entry["Author"] == "Albert Einstein")
        #expect(entry["TITLE"] == "Zur Elektrodynamik bewegter Körper")
    }

    // MARK: - Common Properties Tests

    @Test(
        "Given an entry with one author, when parsed authors are queried, then that author is returned"
    )
    func authorProperty() {
        #expect(sampleEntry.authors.first == "Albert Einstein")
    }

    @Test(
        "Given an entry with a title field, when the title property is queried, then its value is returned"
    )
    func titleProperty() {
        #expect(sampleEntry.title == "Zur Elektrodynamik bewegter Körper")
    }

    @Test(
        "Given an entry with a numeric year, when the year property is queried, then an integer is returned"
    )
    func yearProperty() {
        #expect(sampleEntry.year == 1905)
    }

    @Test(
        "Given an entry with a DOI, when the DOI property is queried, then its value is returned")
    func dOIProperty() {
        #expect(sampleEntry.doi == "10.1002/andp.19053221004")
    }

    @Test(
        "Given a book with a publisher, when the publisher property is queried, then its value is returned"
    )
    func publisherProperty() {
        #expect(bookEntry.publisher == "Addison-Wesley")
    }

    @Test(
        "Given an article with a journal, when the journal property is queried, then its value is returned"
    )
    func journalProperty() {
        #expect(sampleEntry.journal == "Annalen der Physik")
    }

    @Test(
        "Given an entry without an abstract, when the abstract property is queried, then nil is returned"
    )
    func abstractPropertyMissing() {
        #expect(sampleEntry.abstract == nil)
    }

    // MARK: - Formatting Tests

    @Test(
        "Given a populated entry, when standard formatting is requested, then a multiline BibTeX entry is produced"
    )
    func formattingStandard() {
        let formatted = sampleEntry.formatted(style: .standard)

        #expect(formatted.hasPrefix("@article{einstein1905"))
        #expect(formatted.contains("author = {Albert Einstein}"))
        #expect(formatted.contains("title = {"))
        #expect(formatted.hasSuffix("}"))
    }

    @Test(
        "Given a populated entry, when compact formatting is requested, then all fields appear on one readable line"
    )
    func formattingCompact() {
        let formatted = sampleEntry.formatted(style: .compact)

        #expect(formatted.hasPrefix("@article{einstein1905, author = {"))
        #expect(!(formatted.contains("\n")))
        #expect(formatted.contains("journal = {Annalen der Physik}"))
        #expect(formatted.contains("pages = {891--921}"))
    }

    @Test(
        "Given a populated entry, when minimal formatting is requested, then all optional whitespace is removed"
    )
    func formattingMinimal() {
        let formatted = sampleEntry.formatted(style: .minimal)

        #expect(formatted.hasPrefix("@article{einstein1905,author={"))
        #expect(!(formatted.contains("\n")))
        #expect(!(formatted.contains(" = ")))
        #expect(formatted.contains("journal={Annalen der Physik}"))
        #expect(formatted.contains("pages={891--921}"))
    }

    @Test(
        "Given a populated entry, when aligned formatting is requested, then field rows are indented"
    )
    func formattingAligned() {
        let formatted = sampleEntry.formatted(style: .aligned)

        // Aligned style should have proper indentation
        #expect(formatted.contains("    "))
    }

    // MARK: - Citation Style Tests

    @Test(
        "Given a complete article, when each citation style renders it, then author and year are retained",
        arguments: BibTeXEntry.CitationStyle.allCases
    )
    func citationStylesRetainAuthorAndYear(_ style: BibTeXEntry.CitationStyle) {
        let citation = sampleEntry.citation(style: style)

        #expect(citation.contains("Einstein"))
        #expect(citation.contains("1905"))
    }

    // MARK: - Validation Tests

    @Test(
        "Given an article with every required field, when validated, then it is valid"
    )
    func validationComplete() {
        let result = sampleEntry.isValid
        #expect(result)
    }

    @Test(
        "Given an article missing required fields, when validated, then it is invalid"
    )
    func validationMissingFields() {
        let incomplete = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )

        let result = incomplete.isValid
        #expect(!(result))
    }

    // MARK: - Author Parsing Tests

    @Test(
        "Given a single-author field, when authors are parsed, then one unchanged name is returned"
    )
    func authorListSingleAuthor() {
        let authors = sampleEntry.authors
        #expect(authors.count == 1)
        #expect(authors.first == "Albert Einstein")
    }

    @Test(
        "Given three and-separated authors, when authors are parsed, then all names retain their order"
    )
    func authorListMultipleAuthors() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["author": "John Doe and Jane Smith and Bob Johnson"]
        )

        let authors = entry.authors
        #expect(authors.count == 3)
        #expect(authors[0] == "John Doe")
        #expect(authors[1] == "Jane Smith")
        #expect(authors[2] == "Bob Johnson")
    }

    @Test(
        "Given an entry without authors, when authors are parsed, then an empty collection is returned"
    )
    func authorListEmpty() {
        let entry = BibTeXEntry(type: .misc, citationKey: "test", fields: [:])
        #expect(entry.authors.isEmpty)
    }

    // MARK: - Identifiable Tests

    @Test(
        "Given two new entries, when identifiers are compared, then each entry has a distinct identity"
    )
    func identifiable() {
        let entry1 = sampleEntry
        let entry2 = bookEntry

        #expect(entry1.id != entry2.id)
        #expect(entry1.citationKey == "einstein1905")
    }

    // MARK: - Equatable Tests

    @Test(
        "Given entries that differ by key or field content, when compared, then semantic equality distinguishes every case"
    )
    func equatable() {
        let entry1 = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["author": "Test"]
        )
        let entry2 = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["author": "Test"]
        )
        let entry3 = BibTeXEntry(
            type: .article,
            citationKey: "test2",
            fields: ["author": "Test"]
        )
        let entry4 = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["author": "Different"]
        )

        #expect(entry1 == entry2)
        #expect(entry1 != entry3)
        #expect(entry1 != entry4)
    }

    // MARK: - Hashable Tests

    @Test("Given distinct entries, when inserted into a set, then both values remain addressable")
    func hashable() {
        var set = Set<BibTeXEntry>()
        set.insert(sampleEntry)
        set.insert(bookEntry)

        #expect(set.count == 2)
        #expect(set.contains(bookEntry))
    }

    // MARK: - Case-Insensitive Field Regression Tests

    @Test(
        "Given mixed-case field keys, when values and validation are queried, then lookup remains case-insensitive"
    )
    func mixedCaseFieldsRemainAccessible() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "case",
            fields: [
                "AUTHOR": "Ada Lovelace",
                "Title": "Notes",
                "JOURNAL": "Scientific Memoirs",
                "Year": "1843",
            ]
        )

        #expect(entry["author"] == "Ada Lovelace")
        #expect(entry["AuThOr"] == "Ada Lovelace")
        #expect(entry.author == "Ada Lovelace")
        #expect(entry.title == "Notes")
        #expect(entry.year == 1843)
        #expect(entry.isValid)
    }

    @Test(
        "Given duplicate case variants of one field, when read, then the canonical lowercase field wins"
    )
    func canonicalFieldWinsMalformedCaseCollision() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "collision",
            fields: [
                "AUTHOR": "Uppercase",
                "Author": "Mixed",
                "author": "Canonical",
            ]
        )

        #expect(entry["AUTHOR"] == "Canonical")
        #expect(entry["author"] == "Canonical")
        #expect(
            entry.formatted(
                style: .init(fieldOrder: ["author"], includeUnorderedFields: false)
            ) == """
                @misc{collision,
                    author = {Canonical}
                }
                """)
    }

    @Test(
        "Given entries differing only by key casing, when compared and hashed, then they are semantically identical"
    )
    func caseInsensitiveEqualityAndHashing() {
        let lowercase = BibTeXEntry(
            type: .article,
            citationKey: "Key",
            fields: ["author": "Ada", "title": "Notes"]
        )
        let uppercase = BibTeXEntry(
            type: .article,
            citationKey: "KEY",
            fields: ["AUTHOR": "Ada", "TITLE": "Notes"]
        )

        #expect(lowercase == uppercase)
        #expect(Set([lowercase, uppercase]).count == 1)
        #expect(!(lowercase < uppercase))
        #expect(!(uppercase < lowercase))
    }

    // MARK: - Value Semantics and Copy APIs

    @Test(
        "Given a copied entry, when its subscript is mutated, then the original value remains unchanged"
    )
    func subscriptMutationUsesValueSemantics() {
        let original = sampleEntry
        var copy = original

        copy["TITLE"] = "A Revised Title"
        copy["doi"] = nil

        #expect(original.title == "Zur Elektrodynamik bewegter Körper")
        #expect(original.doi == "10.1002/andp.19053221004")
        #expect(copy.title == "A Revised Title")
        #expect(copy.doi == nil)
        #expect(copy.id == original.id)
    }

    @Test(
        "Given entry copy APIs, when fields, key, and type are changed, then identity and the original value are preserved"
    )
    func copyAPIsPreserveIdentityAndOriginalValue() {
        let original = sampleEntry
        let updated =
            original
            .with(field: "NOTE", value: "Historically significant")
            .with(fields: ["KEYWORDS": "relativity; physics"])
            .with(key: "einstein1905-revised")
            .with(type: .inproceedings)

        #expect(updated.id == original.id)
        #expect(updated.type == .inproceedings)
        #expect(updated.citationKey == "einstein1905-revised")
        #expect(updated["note"] == "Historically significant")
        #expect(updated.keywords == ["relativity", "physics"])
        #expect(original["note"] == nil)
        #expect(original.type == .article)
        #expect(original.citationKey == "einstein1905")
    }

    @Test(
        "Given colliding field-key case variants, when a field is set, then one canonical value remains"
    )
    func settingFieldsResolvesCaseCollisionsDeterministically() {
        let entry = BibTeXEntry(type: .misc, citationKey: "updates")
            .settingFields([
                "AUTHOR": "Uppercase",
                "Author": "Mixed",
                "author": "Canonical",
            ])

        #expect(entry.author == "Canonical")
        #expect(entry.fields.filter { $0.key.lowercased() == "author" }.count == 1)
    }

    // MARK: - Validation Regression Tests

    @Test(
        "Given a whitespace-only required field, when validated, then the field is reported missing"
    )
    func whitespaceOnlyRequiredFieldIsMissing() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "blank",
            fields: [
                "author": "Ada",
                "title": "Notes",
                "journal": " \n\t ",
                "year": "1843",
            ]
        )

        #expect(!(entry.isValid))
        #expect(entry.missingRequiredFields == ["journal"])
        #expect(entry.validate().missingRequired == ["journal"])
    }

    @Test(
        "Given a book, when either author or editor is present, then its alternative requirement is satisfied"
    )
    func bookAcceptsAuthorOrEditor() {
        let commonFields = [
            "title": "Collected Works",
            "publisher": "Example Press",
            "year": "2026",
        ]
        let authored = BibTeXEntry(
            type: .book,
            citationKey: "authored",
            fields: commonFields.merging(["author": "A. Author"]) { _, new in new }
        )
        let edited = BibTeXEntry(
            type: .book,
            citationKey: "edited",
            fields: commonFields.merging(["EDITOR": "E. Editor"]) { _, new in new }
        )
        let anonymous = BibTeXEntry(
            type: .book,
            citationKey: "anonymous",
            fields: commonFields
        )

        #expect(authored.isValid)
        #expect(edited.isValid)
        #expect(!(anonymous.isValid))
        #expect(anonymous.missingRequiredFields == ["author", "editor"])
        #expect(anonymous.validate().missingRequiredAlternatives == [["author", "editor"]])
    }

    @Test(
        "Given an in-book entry, when both alternative groups are supplied, then all requirements are satisfied"
    )
    func inbookAcceptsBothRequiredAlternativeGroups() {
        let entry = BibTeXEntry(
            type: .inbook,
            citationKey: "chapter",
            fields: [
                "editor": "E. Editor",
                "title": "A Selection",
                "pages": "10--20",
                "publisher": "Example Press",
                "year": "2026",
            ]
        )
        #expect(entry.isValid)

        let missingLocation = entry.settingField("pages", to: nil)
        #expect(!(missingLocation.isValid))
        #expect(missingLocation.missingRequiredFields == ["chapter", "pages"])
    }

    @Test(
        "Given a miscellaneous entry with arbitrary fields, when validated, then no required fields are imposed"
    )
    func miscAllowsArbitraryFieldsAndNoRequiredFields() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "extension",
            fields: ["x-private-field": "value"]
        )

        #expect(entry.isValid)
        #expect(entry.validate().missingRequired.isEmpty)
    }

    @Test(
        "Given several missing requirements, when diagnostics are requested, then field names are sorted"
    )
    func validationDiagnosticsAreSorted() {
        let entry = BibTeXEntry(type: .article, citationKey: "empty")
        let validation = entry.validate()

        #expect(validation.missingRequired == ["author", "journal", "title", "year"])
        #expect(validation.missingOptional == validation.missingOptional.sorted())
    }

    // MARK: - Name and Scalar Parsing Regression Tests

    @Test(
        "Given author separators with varied whitespace and casing, when parsed, then every author is recognized"
    )
    func authorParserUnderstandsWhitespaceAndCaseVariants() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "authors",
            fields: [
                "author": "Ada Lovelace\n  and\tGrace Hopper  AND  Alan Turing"
            ]
        )

        #expect(entry.authors == ["Ada Lovelace", "Grace Hopper", "Alan Turing"])
    }

    @Test(
        "Given a braced organization containing and, when authors are parsed, then the organization remains intact"
    )
    func authorParserDoesNotSplitBracedOrganizations() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "organization",
            fields: [
                "author": "{Research and Development Group} and Ada Lovelace"
            ]
        )

        #expect(entry.authors == ["{Research and Development Group}", "Ada Lovelace"])
    }

    @Test(
        "Given escaped text and malformed braces, when authors are parsed, then splitting remains safe and deterministic"
    )
    func authorParserHandlesEscapesAndMalformedBracesSafely() {
        let escaped = BibTeXEntry(
            type: .misc,
            citationKey: "escaped",
            fields: ["author": #"A \and B and C"#]
        )
        let unmatchedClosingBrace = BibTeXEntry(
            type: .misc,
            citationKey: "closing",
            fields: ["author": "Alice } and Bob"]
        )
        let unmatchedOpeningBrace = BibTeXEntry(
            type: .misc,
            citationKey: "opening",
            fields: ["author": "Alice { and Bob"]
        )

        #expect(escaped.authors == [#"A \and B"#, "C"])
        #expect(unmatchedClosingBrace.authors == ["Alice }", "Bob"])
        #expect(unmatchedOpeningBrace.authors == ["Alice { and Bob"])
    }

    @Test(
        "Given keywords with braced separators, when parsed, then only top-level separators split values"
    )
    func keywordsRespectBracedSeparators() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "keywords",
            fields: ["keywords": " Swift ; {parsing, syntax}, safety\n"]
        )

        #expect(entry.keywords == ["Swift", "{parsing, syntax}", "safety"])
    }

    @Test(
        "Given padded and empty year and URL fields, when accessed, then values are trimmed and empties are rejected"
    )
    func yearAndURLTrimWhitespaceAndRejectEmptyValues() {
        let entry = BibTeXEntry(
            type: .online,
            citationKey: "trimmed",
            fields: [
                "year": " \n2026\t",
                "url": " https://swift.org/ ",
            ]
        )
        #expect(entry.year == 2026)
        #expect(entry.url?.absoluteString == "https://swift.org/")

        let malformed = BibTeXEntry(
            type: .online,
            citationKey: "malformed",
            fields: ["year": "2026a", "url": " \n "]
        )
        #expect(malformed.year == nil)
        #expect(malformed.url == nil)
    }

    // MARK: - Deterministic Formatting and Citation Tests

    @Test(
        "Given a fixed entry, when each formatting style renders it, then exact output is deterministic"
    )
    func formattingHasDeterministicExactOutput() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "format",
            fields: [
                "Zeta": "last",
                "TITLE": "A Title",
                "author": "A. Author",
                "alpha": "first",
            ]
        )

        #expect(
            entry.formatted() == """
                @article{format,
                    author = {A. Author},
                    TITLE = {A Title},
                    alpha = {first},
                    Zeta = {last}
                }
                """)
    }

    @Test(
        "Given duplicate field-key case variants, when formatted, then one canonical field is emitted in stable order"
    )
    func formattingStyleIsCaseInsensitiveAndDeduplicatesOrder() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "style",
            fields: ["TITLE": "Title", "author": "Author", "note": "Ignored"]
        )
        let style = BibTeXEntry.FormattingStyle(
            fieldOrder: ["TITLE", "title", "AUTHOR"],
            includeUnorderedFields: false,
            indentation: "\t"
        )

        #expect(
            entry.formatted(style: style)
                == "@misc{style,\n\tTITLE = {Title},\n\tauthor = {Author}\n}")
    }

    @Test(
        "Given Unicode field names of different widths, when aligned, then padding uses characters without truncation"
    )
    func alignedFormattingUsesCharacterWidthWithoutTruncation() {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "unicode",
            fields: ["é": "accent", "long": "value"]
        )

        #expect(
            entry.formatted(style: .aligned) == """
                @misc{unicode,
                    long = {value},
                    é    = {accent}
                }
                """)
    }

    @Test(
        "Given a fieldless entry, when formatted, then its exact canonical representation is returned"
    )
    func emptyEntryFormattingIsExact() {
        #expect(BibTeXEntry(type: .misc, citationKey: "empty").formatted() == "@misc{empty}")
    }

    @Test(
        "Given a populated entry, when each built-in format is parsed again, then no fields are lost"
    )
    func builtInFormattingStylesRoundTripWithoutDroppingFields() throws {
        let original = BibTeXEntry(
            type: .custom("white-paper"),
            citationKey: "lossless",
            fields: [
                "author": "Ada Lovelace",
                "title": "Notes",
                "year": "1843",
                "custom": "Preserved",
                "url": "https://example.com/paper",
            ]
        )
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        for style in [
            BibTeXEntry.FormattingStyle.standard,
            .compact,
            .minimal,
            .aligned,
        ] {
            let parsed = try #require(
                BibTeXParser.parse(original.formatted(style: style), options: options).first)
            #expect(parsed.type == original.type)
            #expect(parsed.citationKey == original.citationKey)
            #expect(parsed.fields == original.fields)
        }
    }

    @Test(
        "Given a citation key containing braces, when each built-in format is parsed again, then the key is preserved"
    )
    func builtInFormattingStylesRoundTripBraceContainingCitationKeys() throws {
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        for citationKey in ["left{brace", "right}brace", "both{}braces"] {
            let original = BibTeXEntry(
                type: .misc,
                citationKey: citationKey,
                fields: ["title": "Value"]
            )

            for style in [
                BibTeXEntry.FormattingStyle.standard,
                .compact,
                .minimal,
                .aligned,
            ] {
                let formatted = original.formatted(style: style)
                #expect(formatted.hasPrefix("@misc("))

                let parsed = try #require(BibTeXParser.parse(formatted, options: options).first)
                #expect(parsed.citationKey == citationKey)
                #expect(parsed.fields == original.fields)
            }
        }
    }

    @Test(
        "Given a fieldless entry with braces in its key, when formatted, then a canonical trailing comma disambiguates it"
    )
    func fieldlessBraceContainingCitationKeyUsesCanonicalTrailingComma() throws {
        let original = BibTeXEntry(
            type: .misc,
            citationKey: "right}brace"
        )
        let formatted = original.formatted()

        #expect(formatted == "@misc(right}brace,)")
        #expect(try BibTeXParser.parse(formatted).first?.citationKey == original.citationKey)
    }

    @Test(
        "Given blank citation fields and a DOI resolver URL, when cited, then blanks and duplicate resolver text are omitted"
    )
    func citationsIgnoreBlankFieldsAndDoNotDuplicateDOIResolver() {
        let blank = BibTeXEntry(
            type: .article,
            citationKey: "blank",
            fields: ["author": " ", "title": "\n", "year": "\t"]
        )
        #expect(blank.citation(style: .apa) == "")

        let entry = sampleEntry.settingField(
            "doi",
            to: "https://doi.org/10.1002/andp.19053221004"
        )
        #expect(
            entry.citation(style: .apa)
                .components(separatedBy: "https://doi.org/").count == 2)
    }

    @Test(
        "Given valid and invalid DOI values, when cited, then only a canonical validated resolver URL is emitted"
    )
    func citationDOIUsesCanonicalValidatedResolverURL() {
        let urn = sampleEntry.settingField(
            "doi",
            to: "urn:doi:10.1000/example"
        )
        #expect(
            urn.citation(style: .apa)
                .contains("https://doi.org/10.1000/example"))
        #expect(!(urn.citation(style: .apa).contains("urn:doi:")))

        let unicode = sampleEntry.settingField(
            "doi",
            to: "10.1000/café/航空"
        )
        #expect(
            unicode.citation(style: .apa).contains(
                "https://doi.org/10.1000/caf%C3%A9%2F%E8%88%AA%E7%A9%BA"
            ))

        let invalid = sampleEntry.settingField("doi", to: "not a DOI")
        #expect(invalid.citation(style: .apa).hasSuffix("not a DOI"))
        #expect(!(invalid.citation(style: .apa).contains("doi.org/not")))
    }

    @Test(
        "Given a fixed article, when every citation style renders it, then exact summaries are deterministic"
    )
    func citationStylesHaveDeterministicExactOutput() {
        #expect(
            sampleEntry.citation(style: .apa)
                == "Albert Einstein (1905). Zur Elektrodynamik bewegter Körper. "
                + "*Annalen der Physik*, *17*, 891--921. "
                + "https://doi.org/10.1002/andp.19053221004")
        #expect(
            sampleEntry.citation(style: .mla)
                == "Albert Einstein. \"Zur Elektrodynamik bewegter Körper.\" "
                + "*Annalen der Physik*, vol. 17, 1905, pp. 891--921.")
        #expect(
            sampleEntry.citation(style: .chicago)
                == "Albert Einstein. \"Zur Elektrodynamik bewegter Körper.\" "
                + "*Annalen der Physik* 17 (1905): 891--921.")
        #expect(
            sampleEntry.citation(style: .ieee)
                == "Albert Einstein \"Zur Elektrodynamik bewegter Körper,\" "
                + "*Annalen der Physik*, vol. 17, pp. 891--921, 1905.")
        #expect(
            sampleEntry.citation(style: .harvard)
                == "Albert Einstein (1905) 'Zur Elektrodynamik bewegter Körper', "
                + "*Annalen der Physik*, vol. 17, pp. 891--921.")
    }

    @Test(
        "Given an author with a surname particle and suffix, when IEEE formatting is requested, then the name is ordered correctly"
    )
    func iEEENameFormattingHandlesSuffix() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "name",
            fields: [
                "author": "de la Cruz, Jr., Juan Carlos",
                "title": "Paper",
                "journal": "Journal",
                "year": "2026",
            ]
        )

        #expect(entry.citation(style: .ieee).hasPrefix("J. C. de la Cruz, Jr."))
    }

    // MARK: - Codable, Comparable, and Concurrency

    @Test(
        "Given an entry with identity, mixed-case fields, and raw source, when round-tripped, then every value is preserved"
    )
    func codableRoundTripPreservesIdentityAndMixedCaseFields() throws {
        let identity = try #require(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        let original = BibTeXEntry(
            type: .article,
            citationKey: "Codable",
            fields: ["AUTHOR": "Ada", "Title": "Notes"],
            rawBibTeX: "@article{Codable}",
            id: identity
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BibTeXEntry.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded == original)
        #expect(decoded.author == "Ada")
        #expect(decoded.title == "Notes")
        #expect(decoded.rawBibTeX == original.rawBibTeX)
    }

    @Test("Given a payload without identity or fields, when decoded, then the current schema rejects it")
    func decodingPayloadWithoutRequiredIdentityOrFieldsFails() {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                BibTeXEntry.self,
                from: Data(#"{"type":"misc","citationKey":"incomplete"}"#.utf8)
            )
        }
    }

    @Test(
        "Given an unknown encoded type, when an entry is decoded, then the type remains a custom value"
    )
    func decodingUnknownTypePreservesCustomValue() throws {
        let data = Data(
            #"""
            {
              "id":"00000000-0000-0000-0000-000000000002",
              "type":"whitepaper",
              "citationKey":"unknown",
              "fields":{}
            }
            """#.utf8
        )

        let entry = try JSONDecoder().decode(BibTeXEntry.self, from: data)

        #expect(entry.type == .custom("whitepaper"))
        #expect(entry.type.rawValue == "whitepaper")
        #expect(entry.citationKey == "unknown")
    }

    @Test(
        "Given a malformed encoded entry, when decoding it, then a decoding error is reported",
        arguments: [
            #"{"citationKey":"missing-type"}"#,
            #"{"type":"misc"}"#,
            #"{"type":42,"citationKey":"invalid-type"}"#,
            #"{"type":"misc","citationKey":42}"#,
            #"{"type":"misc","citationKey":"invalid-fields","fields":"not-an-object"}"#,
        ]
    )
    func decodingMalformedPayloadFails(_ payload: String) {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                BibTeXEntry.self,
                from: Data(payload.utf8)
            )
        }
    }

    @Test(
        "Given entries that differ at one ordering dimension, when compared both ways, then every tie-breaker is strict"
    )
    func comparableAppliesEveryTieBreaker() {
        let orderedPairs: [(BibTeXEntry, BibTeXEntry)] = [
            (
                comparableEntry(year: "2026"),
                comparableEntry(year: "2025")
            ),
            (
                comparableEntry(year: "2025"),
                comparableEntry(year: nil)
            ),
            (
                comparableEntry(author: "Ada"),
                comparableEntry(author: "Grace")
            ),
            (
                comparableEntry(title: "Alpha"),
                comparableEntry(title: "Beta")
            ),
            (
                comparableEntry(citationKey: "Alpha"),
                comparableEntry(citationKey: "beta")
            ),
            (
                comparableEntry(type: .article),
                comparableEntry(type: .book)
            ),
            (
                comparableEntry(type: .custom("alpha")),
                comparableEntry(type: .custom("beta"))
            ),
            (
                comparableEntry(extraFields: ["zeta": "same"]),
                comparableEntry(extraFields: ["zulu": "same"])
            ),
            (
                comparableEntry(extraFields: ["zeta": "alpha"]),
                comparableEntry(extraFields: ["zeta": "beta"])
            ),
            (
                comparableEntry(),
                comparableEntry(extraFields: ["zeta": "value"])
            ),
        ]

        for (predecessor, successor) in orderedPairs {
            #expect(predecessor < successor)
            #expect(!(successor < predecessor))
        }
    }

    @Test(
        "Given a deterministic entry set, when Comparable laws are evaluated, then ordering is strict and transitive"
    )
    func comparableSatisfiesStrictOrderingLaws() {
        let first = comparableEntry(citationKey: "alpha")
        let second = comparableEntry(citationKey: "beta")
        let third = comparableEntry(citationKey: "gamma")
        let entries = [
            third,
            comparableEntry(year: nil),
            first,
            comparableEntry(author: "Zed"),
            second,
        ]

        for entry in entries {
            #expect(!(entry < entry))
        }

        for lhs in entries {
            for rhs in entries where lhs != rhs {
                #expect((lhs < rhs) != (rhs < lhs))
            }
        }

        #expect(first < second)
        #expect(second < third)
        #expect(first < third)
        #expect(entries.sorted() == entries.sorted())
        #expect(
            entries.sorted().map(\.citationKey)
                == entries.reversed().sorted().map(\.citationKey)
        )
    }

    @Test(
        "Given entries with dates and citation-key ties, when sorted, then the total order is deterministic"
    )
    func comparableProvidesDeterministicTotalOrder() {
        let first = BibTeXEntry(
            type: .article,
            citationKey: "a",
            fields: ["author": "Same", "title": "Same", "year": "2026"]
        )
        let second = BibTeXEntry(
            type: .article,
            citationKey: "b",
            fields: ["author": "Same", "title": "Same", "year": "2026"]
        )
        let older = BibTeXEntry(
            type: .article,
            citationKey: "older",
            fields: ["author": "Same", "title": "Same", "year": "2025"]
        )
        let undated = BibTeXEntry(
            type: .article,
            citationKey: "undated",
            fields: ["author": "Same", "title": "Same"]
        )

        #expect(first < second)
        #expect(second < older)
        #expect(older < undated)
        #expect(
            [undated, second, older, first].sorted().map(\.citationKey) == [
                "a", "b", "older", "undated",
            ])
    }

    @Test(
        "Given case variants of one custom type, when compared, then equality and ordering remain consistent"
    )
    func comparableRespectsCaseInsensitiveCustomTypeEquality() {
        let uppercase = BibTeXEntry(
            type: .custom("ALPHA"),
            citationKey: "same",
            fields: ["title": "Same"]
        )
        let lowercase = BibTeXEntry(
            type: .custom("alpha"),
            citationKey: "same",
            fields: ["title": "Same"]
        )
        let middle = BibTeXEntry(
            type: .custom("beta"),
            citationKey: "same",
            fields: ["title": "Different"]
        )

        #expect(uppercase == lowercase)
        #expect(!(uppercase < lowercase))
        #expect(!(lowercase < uppercase))
        #expect((uppercase < middle) == (lowercase < middle))
        #expect((middle < uppercase) == (middle < lowercase))
    }

    @Test(
        "Given BibTeX value types, when checked at compile time, then they satisfy Sendable"
    )
    func sendableConformance() {
        func requireSendable<T: Sendable>(_: T.Type) {}
        requireSendable(BibTeXEntry.self)
        requireSendable(BibTeXEntry.FormattingStyle.self)
        requireSendable(BibTeXEntry.CitationStyle.self)
        requireSendable(BibTeXEntry.ValidationResult.self)
    }

    @Test(
        "Given one immutable entry, when many tasks read it concurrently, then every snapshot is identical"
    )
    func concurrentReadsProduceIdenticalSnapshots() async {
        let entry = sampleEntry
        let expected = ReadSnapshot(
            title: entry.title,
            authors: entry.authors,
            year: entry.year,
            fieldCount: entry.fields.count,
            formatted: entry.formatted(style: .minimal)
        )

        let snapshots = await withTaskGroup(
            of: ReadSnapshot.self,
            returning: [ReadSnapshot].self
        ) { group in
            for _ in 0..<32 {
                group.addTask {
                    ReadSnapshot(
                        title: entry.title,
                        authors: entry.authors,
                        year: entry.year,
                        fieldCount: entry.fields.count,
                        formatted: entry.formatted(style: .minimal)
                    )
                }
            }

            var snapshots: [ReadSnapshot] = []
            snapshots.reserveCapacity(32)
            for await snapshot in group {
                snapshots.append(snapshot)
            }
            return snapshots
        }

        #expect(snapshots.count == 32)
        #expect(snapshots.allSatisfy { $0 == expected })
    }
}
