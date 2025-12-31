//
//  DOIDetectorTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
@testable import BibTeXKit

final class DOIDetectorTests: XCTestCase {
    
    // MARK: - Contains DOI Tests
    
    func testContainsDOI_StandardFormat() {
        XCTAssertTrue(DOIDetector.containsDOI("10.1000/xyz123"))
        XCTAssertTrue(DOIDetector.containsDOI("10.1002/andp.19053221004"))
        XCTAssertTrue(DOIDetector.containsDOI("10.1038/nature12373"))
    }
    
    func testContainsDOI_WithPrefix() {
        XCTAssertTrue(DOIDetector.containsDOI("doi:10.1000/xyz123"))
        XCTAssertTrue(DOIDetector.containsDOI("DOI:10.1000/xyz123"))
        XCTAssertTrue(DOIDetector.containsDOI("doi: 10.1000/xyz123"))
    }
    
    func testContainsDOI_WithURL() {
        XCTAssertTrue(DOIDetector.containsDOI("https://doi.org/10.1000/xyz123"))
        XCTAssertTrue(DOIDetector.containsDOI("http://doi.org/10.1000/xyz123"))
        XCTAssertTrue(DOIDetector.containsDOI("https://dx.doi.org/10.1000/xyz123"))
        XCTAssertTrue(DOIDetector.containsDOI("doi.org/10.1000/xyz123"))
    }
    
    func testContainsDOI_InSentence() {
        XCTAssertTrue(DOIDetector.containsDOI("See the paper at https://doi.org/10.1000/xyz123 for details."))
        XCTAssertTrue(DOIDetector.containsDOI("The DOI is 10.1002/andp.19053221004."))
    }
    
    func testContainsDOI_NoDOI() {
        XCTAssertFalse(DOIDetector.containsDOI("No DOI here"))
        XCTAssertFalse(DOIDetector.containsDOI("10/1000/xyz"))
        XCTAssertFalse(DOIDetector.containsDOI("doi.org"))
        XCTAssertFalse(DOIDetector.containsDOI(""))
    }
    
    // MARK: - Extract DOI Tests
    
    func testExtractDOI_Standard() {
        XCTAssertEqual(DOIDetector.extractDOI(from: "10.1000/xyz123"), "10.1000/xyz123")
        XCTAssertEqual(DOIDetector.extractDOI(from: "10.1002/andp.19053221004"), "10.1002/andp.19053221004")
    }
    
    func testExtractDOI_WithPrefix() {
        XCTAssertEqual(DOIDetector.extractDOI(from: "doi:10.1000/xyz123"), "10.1000/xyz123")
        XCTAssertEqual(DOIDetector.extractDOI(from: "DOI: 10.1000/xyz123"), "10.1000/xyz123")
    }
    
    func testExtractDOI_WithURL() {
        XCTAssertEqual(DOIDetector.extractDOI(from: "https://doi.org/10.1000/xyz123"), "10.1000/xyz123")
        XCTAssertEqual(DOIDetector.extractDOI(from: "https://dx.doi.org/10.1000/xyz123"), "10.1000/xyz123")
    }
    
    func testExtractDOI_FromSentence() {
        XCTAssertEqual(
            DOIDetector.extractDOI(from: "The paper is available at doi:10.1000/xyz123."),
            "10.1000/xyz123"
        )
    }
    
    func testExtractDOI_NoDOI() {
        XCTAssertNil(DOIDetector.extractDOI(from: "No DOI here"))
        XCTAssertNil(DOIDetector.extractDOI(from: ""))
    }
    
    // MARK: - Extract All DOIs Tests
    
    func testExtractAllDOIs_Multiple() {
        let text = """
        Reference 1: 10.1000/abc123
        Reference 2: https://doi.org/10.2000/def456
        Reference 3: doi:10.3000/ghi789
        """
        
        let dois = DOIDetector.extractAllDOIs(from: text)
        XCTAssertEqual(dois.count, 3)
        XCTAssertTrue(dois.contains("10.1000/abc123"))
        XCTAssertTrue(dois.contains("10.2000/def456"))
        XCTAssertTrue(dois.contains("10.3000/ghi789"))
    }
    
    func testExtractAllDOIs_NoDOIs() {
        let dois = DOIDetector.extractAllDOIs(from: "No DOIs here")
        XCTAssertTrue(dois.isEmpty)
    }
    
    // MARK: - Validate DOI Tests
    
    func testIsValidDOI_Valid() {
        XCTAssertTrue(DOIDetector.isValidDOI("10.1000/xyz123"))
        XCTAssertTrue(DOIDetector.isValidDOI("10.1002/andp.19053221004"))
        XCTAssertTrue(DOIDetector.isValidDOI("10.1038/nature12373"))
        XCTAssertTrue(DOIDetector.isValidDOI("10.1234/5678"))
    }
    
    func testIsValidDOI_Invalid() {
        XCTAssertFalse(DOIDetector.isValidDOI("doi:10.1000/xyz123"))  // Has prefix
        XCTAssertFalse(DOIDetector.isValidDOI("https://doi.org/10.1000/xyz123"))  // Is URL
        XCTAssertFalse(DOIDetector.isValidDOI("10.100/xyz"))  // Prefix too short
        XCTAssertFalse(DOIDetector.isValidDOI("11.1000/xyz"))  // Doesn't start with 10.
        XCTAssertFalse(DOIDetector.isValidDOI("10.1000"))  // Missing suffix
        XCTAssertFalse(DOIDetector.isValidDOI(""))
    }
    
    // MARK: - DOI URL Tests
    
    func testDoiURL_Valid() {
        let url = DOIDetector.doiURL(for: "10.1000/xyz123")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://doi.org/10.1000/xyz123")
    }
    
    func testDoiURL_FromFullURL() {
        let url = DOIDetector.doiURL(for: "https://doi.org/10.1000/xyz123")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://doi.org/10.1000/xyz123")
    }
    
    func testDoiURL_Invalid() {
        XCTAssertNil(DOIDetector.doiURL(for: "invalid"))
        XCTAssertNil(DOIDetector.doiURL(for: ""))
    }
    
    // MARK: - Normalize Tests
    
    func testNormalize_Standard() {
        XCTAssertEqual(DOIDetector.normalize("10.1000/xyz123"), "10.1000/xyz123")
    }
    
    func testNormalize_WithPrefix() {
        XCTAssertEqual(DOIDetector.normalize("doi:10.1000/xyz123"), "10.1000/xyz123")
        XCTAssertEqual(DOIDetector.normalize("DOI: 10.1000/xyz123"), "10.1000/xyz123")
    }
    
    func testNormalize_WithURL() {
        XCTAssertEqual(DOIDetector.normalize("https://doi.org/10.1000/xyz123"), "10.1000/xyz123")
        XCTAssertEqual(DOIDetector.normalize("https://dx.doi.org/10.1000/xyz123"), "10.1000/xyz123")
    }
    
    func testNormalize_Invalid() {
        XCTAssertNil(DOIDetector.normalize("invalid"))
        XCTAssertNil(DOIDetector.normalize(""))
    }
    
    // MARK: - Complex DOI Formats
    
    func testComplexDOIs() {
        // DOI with multiple segments
        XCTAssertTrue(DOIDetector.isValidDOI("10.1000.10/xyz123"))
        
        // DOI with special characters in suffix
        XCTAssertEqual(DOIDetector.extractDOI(from: "10.1000/test-value_123"), "10.1000/test-value_123")
        
        // DOI with parentheses (common in some publishers)
        XCTAssertEqual(DOIDetector.extractDOI(from: "10.1000/test(2024)123"), "10.1000/test(2024)123")
    }
    
    func testTrailingPunctuationRemoval() {
        // DOI at end of sentence should not include the period
        XCTAssertEqual(DOIDetector.extractDOI(from: "See 10.1000/xyz123."), "10.1000/xyz123")
        XCTAssertEqual(DOIDetector.extractDOI(from: "DOI: 10.1000/xyz123,"), "10.1000/xyz123")
        XCTAssertEqual(DOIDetector.extractDOI(from: "(10.1000/xyz123)"), "10.1000/xyz123")
    }
    
    // MARK: - BibTeXEntry Extension Tests
    
    func testBibTeXEntry_DoiURL() throws {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["doi": "10.1000/xyz123"]
        )
        
        XCTAssertNotNil(entry.doiURL)
        XCTAssertEqual(entry.doiURL?.absoluteString, "https://doi.org/10.1000/xyz123")
    }
    
    func testBibTeXEntry_HasValidDOI() {
        let validEntry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["doi": "10.1000/xyz123"]
        )
        XCTAssertTrue(validEntry.hasValidDOI)
        
        let invalidEntry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["doi": "invalid"]
        )
        XCTAssertFalse(invalidEntry.hasValidDOI)
        
        let noDOIEntry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: [:]
        )
        XCTAssertFalse(noDOIEntry.hasValidDOI)
    }
    
    func testBibTeXEntry_NormalizedDOI() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["doi": "https://doi.org/10.1000/xyz123"]
        )
        
        XCTAssertEqual(entry.normalizedDOI, "10.1000/xyz123")
    }
    
    // MARK: - Real-World DOI Examples
    
    func testRealWorldDOIs() {
        // Nature
        XCTAssertTrue(DOIDetector.isValidDOI("10.1038/nature12373"))
        
        // IEEE
        XCTAssertTrue(DOIDetector.isValidDOI("10.1109/5.771073"))
        
        // Springer
        XCTAssertTrue(DOIDetector.isValidDOI("10.1007/s00422-012-0512-2"))
        
        // Elsevier
        XCTAssertTrue(DOIDetector.isValidDOI("10.1016/j.artint.2010.04.024"))
        
        // ACM
        XCTAssertTrue(DOIDetector.isValidDOI("10.1145/3287324.3287489"))
        
        // Wiley (Einstein's paper)
        XCTAssertTrue(DOIDetector.isValidDOI("10.1002/andp.19053221004"))
    }
}
