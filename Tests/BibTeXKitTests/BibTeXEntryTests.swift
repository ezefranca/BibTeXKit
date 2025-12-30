//
//  BibTeXEntryTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
@testable import BibTeXKit

final class BibTeXEntryTests: XCTestCase {
    
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
                "doi": "10.1002/andp.19053221004"
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
                "edition": "3rd"
            ]
        )
    }
    
    // MARK: - Initialization Tests
    
    func testBasicInitialization() {
        let entry = sampleEntry
        
        XCTAssertEqual(entry.type, .article)
        XCTAssertEqual(entry.citationKey, "einstein1905")
        XCTAssertEqual(entry.fields.count, 7)
    }
    
    func testInitializationWithRawBibTeX() {
        let raw = "@article{test, author = {Test}}"
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["author": "Test"],
            rawBibTeX: raw
        )
        
        XCTAssertEqual(entry.rawBibTeX, raw)
    }
    
    // MARK: - Subscript Access Tests
    
    func testSubscriptAccess() {
        let entry = sampleEntry
        
        XCTAssertEqual(entry["author"], "Albert Einstein")
        XCTAssertEqual(entry["title"], "Zur Elektrodynamik bewegter Körper")
        XCTAssertEqual(entry["year"], "1905")
        XCTAssertNil(entry["nonexistent"])
    }
    
    func testSubscriptCaseInsensitive() {
        let entry = sampleEntry
        
        XCTAssertEqual(entry["AUTHOR"], "Albert Einstein")
        XCTAssertEqual(entry["Author"], "Albert Einstein")
        XCTAssertEqual(entry["TITLE"], "Zur Elektrodynamik bewegter Körper")
    }
    
    // MARK: - Common Properties Tests
    
    func testAuthorProperty() {
        XCTAssertEqual(sampleEntry.authors.first, "Albert Einstein")
    }
    
    func testTitleProperty() {
        XCTAssertEqual(sampleEntry.title, "Zur Elektrodynamik bewegter Körper")
    }
    
    func testYearProperty() {
        XCTAssertEqual(sampleEntry.year, 1905)
    }
    
    func testDOIProperty() {
        XCTAssertEqual(sampleEntry.doi, "10.1002/andp.19053221004")
    }
    
    func testPublisherProperty() {
        XCTAssertEqual(bookEntry.publisher, "Addison-Wesley")
    }
    
    func testJournalProperty() {
        XCTAssertEqual(sampleEntry.journal, "Annalen der Physik")
    }
    
    func testAbstractPropertyMissing() {
        XCTAssertNil(sampleEntry.abstract)
    }
    
    // MARK: - Formatting Tests
    
    func testFormattingStandard() {
        let formatted = sampleEntry.formatted(style: .standard)
        
        XCTAssertTrue(formatted.hasPrefix("@article{einstein1905"))
        XCTAssertTrue(formatted.contains("author = {Albert Einstein}"))
        XCTAssertTrue(formatted.contains("title = {"))
        XCTAssertTrue(formatted.hasSuffix("}"))
    }
    
    func testFormattingCompact() {
        let formatted = sampleEntry.formatted(style: .compact)
        
        XCTAssertTrue(formatted.hasPrefix("@article{einstein1905"))
        // Compact should have less whitespace
        XCTAssertTrue(formatted.contains("author={") || formatted.contains("author = {"))
    }
    
    func testFormattingMinimal() {
        let formatted = sampleEntry.formatted(style: .minimal)
        
        // Minimal should be on fewer lines
        let lineCount = formatted.components(separatedBy: "\n").count
        XCTAssertLessThan(lineCount, 10)
    }
    
    func testFormattingAligned() {
        let formatted = sampleEntry.formatted(style: .aligned)
        
        // Aligned style should have proper indentation
        XCTAssertTrue(formatted.contains("    "))
    }
    
    // MARK: - Citation Style Tests
    
    func testCitationAPA() {
        let citation = sampleEntry.citation(style: .apa)
        
        XCTAssertTrue(citation.contains("Einstein"))
        XCTAssertTrue(citation.contains("1905"))
    }
    
    func testCitationMLA() {
        let citation = sampleEntry.citation(style: .mla)
        
        XCTAssertTrue(citation.contains("Einstein"))
        XCTAssertTrue(citation.contains("1905"))
    }
    
    func testCitationChicago() {
        let citation = sampleEntry.citation(style: .chicago)
        
        XCTAssertTrue(citation.contains("Einstein"))
    }
    
    func testCitationIEEE() {
        let citation = sampleEntry.citation(style: .ieee)
        
        XCTAssertTrue(citation.contains("Einstein"))
    }
    
    func testCitationHarvard() {
        let citation = sampleEntry.citation(style: .harvard)
        
        XCTAssertTrue(citation.contains("Einstein"))
        XCTAssertTrue(citation.contains("1905"))
    }
    
    // MARK: - Validation Tests
    
    func testValidationComplete() {
        let result = sampleEntry.isValid
        XCTAssertTrue(result)
    }
    
    func testValidationMissingFields() {
        let incomplete = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )
        
        let result = incomplete.isValid
        XCTAssertFalse(result)
    }
    
    // MARK: - Author Parsing Tests
    
    func testAuthorListSingleAuthor() {
        let authors = sampleEntry.authors
        XCTAssertEqual(authors.count, 1)
        XCTAssertEqual(authors.first, "Albert Einstein")
    }
    
    func testAuthorListMultipleAuthors() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["author": "John Doe and Jane Smith and Bob Johnson"]
        )
        
        let authors = entry.authors
        XCTAssertEqual(authors.count, 3)
        XCTAssertEqual(authors[0], "John Doe")
        XCTAssertEqual(authors[1], "Jane Smith")
        XCTAssertEqual(authors[2], "Bob Johnson")
    }
    
    func testAuthorListEmpty() {
        let entry = BibTeXEntry(type: .misc, citationKey: "test", fields: [:])
        XCTAssertTrue(entry.authors.isEmpty)
    }
    
    // MARK: - Identifiable Tests
    
    func testIdentifiable() {
        let entry1 = sampleEntry
        let entry2 = bookEntry
        
        XCTAssertNotEqual(entry1.id, entry2.id)
        XCTAssertEqual(entry1.citationKey, "einstein1905")
    }
    
    // MARK: - Equatable Tests
    
    func testEquatable() {
        let entry1 = BibTeXEntry(type: .article, citationKey: "test", fields: ["author": "Test"])
        let entry2 = BibTeXEntry(type: .article, citationKey: "test", fields: ["author": "Test"])
        let entry3 = BibTeXEntry(type: .article, citationKey: "test2", fields: ["author": "Test"])
        
        XCTAssertEqual(entry1.citationKey, entry2.citationKey)
        XCTAssertNotEqual(entry1, entry3)
    }
    
    // MARK: - Hashable Tests
    
    func testHashable() {
        var set = Set<BibTeXEntry>()
        set.insert(sampleEntry)
        set.insert(bookEntry)
        
        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(bookEntry))
    }
}
