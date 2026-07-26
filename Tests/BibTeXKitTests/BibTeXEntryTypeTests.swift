//
//  BibTeXEntryTypeTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation
import Testing

@testable import BibTeXKit

@Suite("Given a BibTeX entry type")
struct BibTeXEntryTypeTests {

    // MARK: - Initialization Tests

    @Test(
        "Given the standard type catalog, when enumerated, then every type exposes nonempty identity metadata"
    )
    func allStandardTypes() {
        let standardTypes: [BibTeXEntryType] = [
            .article, .book, .booklet, .conference, .inbook,
            .incollection, .inproceedings, .manual, .mastersthesis,
            .misc, .phdthesis, .proceedings, .techreport, .unpublished,
            .online, .software, .dataset,
        ]

        #expect(standardTypes.count == 17)

        for type in standardTypes {
            #expect(!(type.rawValue.isEmpty))
            #expect(!(type.localizedDescription.isEmpty))
            #expect(!(type.symbolName.isEmpty))
        }
    }

    @Test(
        "Given a custom type name, when metadata is queried, then its name and generic symbol are exposed"
    )
    func customType() {
        let custom = BibTeXEntryType.custom("Custom entry type")
        #expect(custom.rawValue == "Custom entry type")
        #expect(custom.localizedDescription.lowercased() == "Custom entry type".lowercased())
        #expect(custom.symbolName == "doc")
    }

    // MARK: - Initialization from Raw Value

    @Test(
        "Given a mixed-case raw value, when initialized, then the matching standard type is recovered"
    )
    func initFromRawValueCaseInsensitive() {
        let mixed = BibTeXEntryType(rawValue: "ArTiClE")

        #expect(mixed == .article)
    }

    @Test(
        "Given each standard entry type, when an uppercased raw value is initialized, then the standard case is recovered",
        arguments: BibTeXEntryType.allStandardTypes
    )
    func standardRawValuesInitializeCaseInsensitively(_ type: BibTeXEntryType) {
        #expect(BibTeXEntryType(rawValue: type.rawValue.uppercased()) == type)
    }

    // MARK: - Required Fields Tests

    @Test(
        "Given article metadata, when required fields are queried, then author, title, journal, and year are present"
    )
    func articleRequiredFields() {
        let required = BibTeXEntryType.article.requiredFields
        #expect(required.contains("author"))
        #expect(required.contains("title"))
        #expect(required.contains("journal"))
        #expect(required.contains("year"))
    }

    @Test(
        "Given book metadata, when requirements are queried, then core fields and the author-or-editor rule are exposed"
    )
    func bookRequiredFields() {
        let required = BibTeXEntryType.book.requiredFields
        #expect(required == ["title", "publisher", "year"])
        #expect(BibTeXEntryType.book.requiredFieldAlternatives == [["author", "editor"]])
    }

    @Test(
        "Given in-book metadata, when requirements are queried, then both alternative field groups are exposed"
    )
    func inbookRequiredFieldAlternatives() {
        #expect(BibTeXEntryType.inbook.requiredFields == ["title", "publisher", "year"])
        #expect(
            Set(BibTeXEntryType.inbook.requiredFieldAlternatives)
                == Set([
                    Set(["author", "editor"]),
                    Set(["chapter", "pages"]),
                ]))
    }

    @Test(
        "Given PhD thesis metadata, when required fields are queried, then author, title, school, and year are present"
    )
    func phdThesisRequiredFields() {
        let required = BibTeXEntryType.phdthesis.requiredFields
        #expect(required.contains("author"))
        #expect(required.contains("title"))
        #expect(required.contains("school"))
        #expect(required.contains("year"))
    }

    @Test(
        "Given a custom type, when field metadata is queried, then no requirements or suggestions are imposed"
    )
    func customTypeRequiredFields() {
        let custom = BibTeXEntryType.custom("dataset")
        #expect(custom.requiredFields.isEmpty)
        #expect(custom.requiredFieldAlternatives.isEmpty)
        #expect(custom.optionalFields.isEmpty)
    }

    @Test(
        "Given article metadata, when optional fields are queried, then common publication fields are present"
    )
    func optionalFields() {
        let optional = BibTeXEntryType.article.optionalFields
        #expect(optional.contains("volume"))
        #expect(optional.contains("number"))
        #expect(optional.contains("pages"))
        #expect(optional.contains("doi"))
    }

    @Test(
        "Given every classic BibTeX type, when optional fields are queried, then the standard sort key is present"
    )
    func classicBibTeXTypesIncludeStandardSortKeyField() {
        let classicTypes: [BibTeXEntryType] = [
            .article, .book, .booklet, .inbook, .incollection,
            .inproceedings, .conference, .manual, .mastersthesis,
            .phdthesis, .proceedings, .techreport, .unpublished, .misc,
        ]

        for type in classicTypes {
            #expect(
                type.optionalFields.contains("key"),
                "\(type.rawValue) omits BibTeX's standard key field")
        }
    }

    @Test(
        "Given every standard type, when required metadata is queried, then each field set matches the specification"
    )
    func requiredFieldMetadataForEveryStandardType() {
        let expected: [BibTeXEntryType: Set<String>] = [
            .article: ["author", "title", "journal", "year"],
            .book: ["title", "publisher", "year"],
            .booklet: ["title"],
            .inbook: ["title", "publisher", "year"],
            .incollection: ["author", "title", "booktitle", "publisher", "year"],
            .inproceedings: ["author", "title", "booktitle", "year"],
            .conference: ["author", "title", "booktitle", "year"],
            .manual: ["title"],
            .mastersthesis: ["author", "title", "school", "year"],
            .phdthesis: ["author", "title", "school", "year"],
            .proceedings: ["title", "year"],
            .techreport: ["author", "title", "institution", "year"],
            .unpublished: ["author", "title", "note"],
            .misc: [],
            .online: [],
            .software: [],
            .dataset: [],
        ]

        #expect(Set(expected.keys) == Set(BibTeXEntryType.allStandardTypes))
        for (type, requiredFields) in expected {
            #expect(type.requiredFields == requiredFields, "\(type)")
        }
    }

    @Test(
        "Given every standard type, when field categories are compared, then required and optional sets do not overlap"
    )
    func fieldMetadataCategoriesDoNotOverlap() {
        for type in BibTeXEntryType.allStandardTypes {
            #expect(type.requiredFields.isDisjoint(with: type.optionalFields), "\(type)")
            for alternatives in type.requiredFieldAlternatives {
                #expect(alternatives.isDisjoint(with: type.optionalFields), "\(type)")
            }
        }
    }

    // MARK: - Symbol Name Tests

    @Test(
        "Given representative entry types, when symbols are queried, then the expected SF Symbols names are returned"
    )
    func symbolNames() {
        #expect(BibTeXEntryType.article.symbolName == "doc.text")
        #expect(BibTeXEntryType.book.symbolName == "book")
        #expect(BibTeXEntryType.phdthesis.symbolName == "graduationcap")
        #expect(BibTeXEntryType.mastersthesis.symbolName == "graduationcap")
        #expect(BibTeXEntryType.proceedings.symbolName == "person.3")
        #expect(BibTeXEntryType.techreport.symbolName == "doc.badge.gearshape")
        #expect(BibTeXEntryType.misc.symbolName == "doc.questionmark")
    }

    // MARK: - Localized Description Tests

    @Test(
        "Given representative entry types, when descriptions are queried, then human-readable labels are returned"
    )
    func localizedDescriptions() {
        #expect(BibTeXEntryType.article.localizedDescription == "Journal article")
        #expect(BibTeXEntryType.book.localizedDescription == "Book")
        #expect(BibTeXEntryType.phdthesis.localizedDescription == "PhD thesis")
        #expect(BibTeXEntryType.inproceedings.localizedDescription == "Conference paper")
    }

    // MARK: - Equatable Tests

    @Test(
        "Given standard and custom types, when equality is evaluated, then custom names compare case-insensitively"
    )
    func equatable() {
        #expect(BibTeXEntryType.article == BibTeXEntryType.article)
        #expect(BibTeXEntryType.article != BibTeXEntryType.book)
        #expect(BibTeXEntryType.custom("dataset") == BibTeXEntryType.custom("dataset"))
        #expect(BibTeXEntryType.custom("WhitePaper") == BibTeXEntryType.custom("whitepaper"))
        #expect(BibTeXEntryType.custom("dataset") != BibTeXEntryType.custom("software"))
        #expect(BibTeXEntryType.custom("ARTICLE") != .article)
    }

    // MARK: - Hashable Tests

    @Test(
        "Given duplicate custom type spellings, when values are inserted into a set, then hashes agree with equality"
    )
    func hashable() {
        var set = Set<BibTeXEntryType>()
        set.insert(.article)
        set.insert(.book)
        set.insert(.custom("dataset"))
        set.insert(.custom("DATASET"))

        #expect(set.count == 3)
        #expect(set.contains(.article))
        #expect(set.contains(.custom("dataset")))
    }

    // MARK: - All Standard Cases

    @Test(
        "Given the standard type catalog, when uniqueness is checked, then all 17 cases and raw values are distinct"
    )
    func allStandardCases() {
        let all = BibTeXEntryType.allStandardTypes
        #expect(all.count == 17)
        #expect(Set(all).count == all.count)
        #expect(Set(all.map(\.rawValue)).count == all.count)
        #expect(all.contains(.article))
        #expect(all.contains(.book))
    }

    // MARK: - Codable and Concurrency

    @Test(
        "Given each standard entry type, when encoded and decoded, then its identity is preserved",
        arguments: BibTeXEntryType.allStandardTypes
    )
    func codableRoundTrip(_ type: BibTeXEntryType) throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let decoded = try decoder.decode(
            BibTeXEntryType.self,
            from: encoder.encode(type)
        )

        #expect(decoded == type)
    }

    @Test(
        "Given a custom entry type, when encoded and decoded, then spelling and case-insensitive identity are preserved"
    )
    func customTypeCodableRoundTripPreservesSpellingAndIdentity() throws {
        let original = BibTeXEntryType.custom("WhitePaper")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BibTeXEntryType.self, from: encoded)

        #expect(decoded.rawValue == "WhitePaper")
        #expect(decoded == .custom("whitepaper"))
        #expect(Set([decoded, .custom("WHITEPAPER")]).count == 1)
    }

    @Test(
        "Given custom types that collide with standard names, when round-tripped, then they remain custom"
    )
    func customTypesCollidingWithStandardNamesRoundTripAsCustom() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for standardType in BibTeXEntryType.allStandardTypes {
            let original = BibTeXEntryType.custom(
                standardType.rawValue.uppercased()
            )
            let encoded = try encoder.encode(original)
            let decoded = try decoder.decode(
                BibTeXEntryType.self,
                from: encoded
            )

            #expect(decoded == original)
            #expect(decoded != standardType)
            #expect(decoded.rawValue == original.rawValue)
        }
    }

    @Test(
        "Given a mixed-case standard value, when decoded, then its standard case is recovered"
    )
    func decodingStandardTypeIsCaseInsensitive() throws {
        let decoded = try JSONDecoder().decode(
            BibTeXEntryType.self,
            from: Data(#""ArTiClE""#.utf8)
        )
        #expect(decoded == .article)
    }

    @Test(
        "Given an unknown encoded value, when decoded, then its spelling is preserved as a custom type"
    )
    func decodingUnknownValueProducesCustomType() throws {
        let decoded = try JSONDecoder().decode(
            BibTeXEntryType.self,
            from: Data(#""WhitePaper""#.utf8)
        )

        #expect(decoded == .custom("whitepaper"))
        #expect(decoded.rawValue == "WhitePaper")
    }

    @Test(
        "Given a malformed encoded type, when decoded, then a decoding error is reported",
        arguments: [
            "42",
            "null",
            "{}",
            #"{"custom":42}"#,
        ]
    )
    func decodingMalformedPayloadFails(_ payload: String) {
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                BibTeXEntryType.self,
                from: Data(payload.utf8)
            )
        }
    }

    @Test(
        "Given a BibTeX entry type, when checked at compile time, then it satisfies Sendable"
    )
    func sendableConformance() {
        func requireSendable<T: Sendable>(_: T.Type) {}
        requireSendable(BibTeXEntryType.self)
    }

    @Test(
        "Given immutable entry types, when many tasks read them concurrently, then every snapshot is identical"
    )
    func concurrentReadsProduceIdenticalSnapshots() async {
        let types =
            BibTeXEntryType.allStandardTypes + [
                .custom("WhitePaper")
            ]
        let expected = types.map { Self.snapshot(of: $0) }

        let snapshots = await withTaskGroup(
            of: [String].self,
            returning: [[String]].self
        ) { group in
            for _ in 0..<32 {
                group.addTask {
                    types.map { Self.snapshot(of: $0) }
                }
            }

            var snapshots: [[String]] = []
            snapshots.reserveCapacity(32)
            for await snapshot in group {
                snapshots.append(snapshot)
            }
            return snapshots
        }

        #expect(snapshots.count == 32)
        #expect(snapshots.allSatisfy { $0 == expected })
    }

    private static func snapshot(of type: BibTeXEntryType) -> String {
        [
            type.rawValue,
            type.localizedDescription,
            type.symbolName,
            type.requiredFields.sorted().joined(separator: ","),
            type.optionalFields.sorted().joined(separator: ","),
        ].joined(separator: "|")
    }
}
