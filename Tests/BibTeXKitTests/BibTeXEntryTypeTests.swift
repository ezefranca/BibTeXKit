//
//  BibTeXEntryTypeTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
@testable import BibTeXKit

final class BibTeXEntryTypeTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testAllStandardTypes() {
        let standardTypes: [BibTeXEntryType] = [
            .article, .book, .booklet, .conference, .inbook,
            .incollection, .inproceedings, .manual, .mastersthesis,
            .misc, .phdthesis, .proceedings, .techreport, .unpublished
        ]
        
        XCTAssertEqual(standardTypes.count, 14)
        
        for type in standardTypes {
            XCTAssertFalse(type.rawValue.isEmpty)
            XCTAssertFalse(type.localizedDescription.isEmpty)
            XCTAssertFalse(type.symbolName.isEmpty)
        }
    }
    
    func testCustomType() {
        let custom = BibTeXEntryType.custom("Custom entry type")
        XCTAssertEqual(custom.rawValue, "Custom entry type")
        XCTAssertEqual(custom.localizedDescription.lowercased(), "Custom entry type".lowercased())
        XCTAssertEqual(custom.symbolName, "doc")
    }
    
    // MARK: - Initialization from Raw Value
    
    func testInitFromRawValueArticle() {
        let type = BibTeXEntryType(rawValue: "article")
        XCTAssertEqual(type, .article)
    }
    
    func testInitFromRawValueCaseInsensitive() {
        let upper = BibTeXEntryType(rawValue: "ARTICLE")
        let mixed = BibTeXEntryType(rawValue: "ArTiClE")
        
        XCTAssertEqual(upper, .article)
        XCTAssertEqual(mixed, .article)
    }
    
    func testInitFromRawValueBook() {
        XCTAssertEqual(BibTeXEntryType(rawValue: "book"), .book)
    }
    
    func testInitFromRawValueCustom() {
        let type = BibTeXEntryType(rawValue: "dataset")
        XCTAssertEqual(type, .dataset)
    }
    
    func testInitFromRawValueAllStandard() {
        XCTAssertEqual(BibTeXEntryType(rawValue: "booklet"), .booklet)
        XCTAssertEqual(BibTeXEntryType(rawValue: "conference"), .conference)
        XCTAssertEqual(BibTeXEntryType(rawValue: "inbook"), .inbook)
        XCTAssertEqual(BibTeXEntryType(rawValue: "incollection"), .incollection)
        XCTAssertEqual(BibTeXEntryType(rawValue: "inproceedings"), .inproceedings)
        XCTAssertEqual(BibTeXEntryType(rawValue: "manual"), .manual)
        XCTAssertEqual(BibTeXEntryType(rawValue: "mastersthesis"), .mastersthesis)
        XCTAssertEqual(BibTeXEntryType(rawValue: "misc"), .misc)
        XCTAssertEqual(BibTeXEntryType(rawValue: "phdthesis"), .phdthesis)
        XCTAssertEqual(BibTeXEntryType(rawValue: "proceedings"), .proceedings)
        XCTAssertEqual(BibTeXEntryType(rawValue: "techreport"), .techreport)
        XCTAssertEqual(BibTeXEntryType(rawValue: "unpublished"), .unpublished)
    }
    
    // MARK: - Required Fields Tests
    
    func testArticleRequiredFields() {
        let required = BibTeXEntryType.article.requiredFields
        XCTAssertTrue(required.contains("author"))
        XCTAssertTrue(required.contains("title"))
        XCTAssertTrue(required.contains("journal"))
        XCTAssertTrue(required.contains("year"))
    }
    
    func testBookRequiredFields() {
        let required = BibTeXEntryType.book.requiredFields
        XCTAssertTrue(required.contains("author") || required.contains("editor"))
        XCTAssertTrue(required.contains("title"))
        XCTAssertTrue(required.contains("publisher"))
        XCTAssertTrue(required.contains("year"))
    }
    
    func testPhdThesisRequiredFields() {
        let required = BibTeXEntryType.phdthesis.requiredFields
        XCTAssertTrue(required.contains("author"))
        XCTAssertTrue(required.contains("title"))
        XCTAssertTrue(required.contains("school"))
        XCTAssertTrue(required.contains("year"))
    }
    
    func testCustomTypeRequiredFields() {
        let custom = BibTeXEntryType.custom("dataset")
        XCTAssertTrue(custom.requiredFields.isEmpty)
    }
    
    func testOptionalFields() {
        let optional = BibTeXEntryType.article.requiredFields
        XCTAssertTrue(optional.contains("volume"))
        XCTAssertTrue(optional.contains("number"))
        XCTAssertTrue(optional.contains("pages"))
        XCTAssertTrue(optional.contains("doi"))
    }
    
    // MARK: - Symbol Name Tests
    
    func testSymbolNames() {
        XCTAssertEqual(BibTeXEntryType.article.symbolName, "doc.text")
        XCTAssertEqual(BibTeXEntryType.book.symbolName, "book")
        XCTAssertEqual(BibTeXEntryType.phdthesis.symbolName, "graduationcap")
        XCTAssertEqual(BibTeXEntryType.mastersthesis.symbolName, "graduationcap")
        XCTAssertEqual(BibTeXEntryType.proceedings.symbolName, "person.3")
        XCTAssertEqual(BibTeXEntryType.techreport.symbolName, "doc.badge.gearshape")
        XCTAssertEqual(BibTeXEntryType.misc.symbolName, "doc.questionmark")
    }
    
    // MARK: - Localized Description Tests
    
    func testLocalizedDescriptions() {
        XCTAssertEqual(BibTeXEntryType.article.localizedDescription, "Journal article")
        XCTAssertEqual(BibTeXEntryType.book.localizedDescription, "Book")
        XCTAssertEqual(BibTeXEntryType.phdthesis.localizedDescription, "PhD thesis")
        XCTAssertEqual(BibTeXEntryType.inproceedings.localizedDescription, "Conference paper")
    }
    
    // MARK: - Equatable Tests
    
    func testEquatable() {
        XCTAssertEqual(BibTeXEntryType.article, BibTeXEntryType.article)
        XCTAssertNotEqual(BibTeXEntryType.article, BibTeXEntryType.book)
        XCTAssertEqual(BibTeXEntryType.custom("dataset"), BibTeXEntryType.custom("dataset"))
        XCTAssertNotEqual(BibTeXEntryType.custom("dataset"), BibTeXEntryType.custom("software"))
    }
    
    // MARK: - Hashable Tests
    
    func testHashable() {
        var set = Set<BibTeXEntryType>()
        set.insert(.article)
        set.insert(.book)
        set.insert(.custom("dataset"))
        
        XCTAssertEqual(set.count, 3)
        XCTAssertTrue(set.contains(.article))
        XCTAssertTrue(set.contains(.custom("dataset")))
    }
    
    // MARK: - All Standard Cases
    
    func testAllStandardCases() {
        let all = BibTeXEntryType.allStandardTypes
        XCTAssertEqual(all.count, 17)
        XCTAssertTrue(all.contains(.article))
        XCTAssertTrue(all.contains(.book))
    }
}
