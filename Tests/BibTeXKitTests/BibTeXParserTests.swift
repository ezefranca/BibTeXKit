//
//  BibTeXParserTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
@testable import BibTeXKit

final class BibTeXParserTests: XCTestCase {
    
    // MARK: - Basic Parsing Tests
    
    func testParseEmptyString() throws {
        let entries = try BibTeXParser.parse("")
        XCTAssertTrue(entries.isEmpty)
    }
    
    func testParseWhitespaceOnly() throws {
        let entries = try BibTeXParser.parse("   \n\t   ")
        XCTAssertTrue(entries.isEmpty)
    }
    
    func testParseSingleEntry() throws {
        let bibtex = """
        @article{test2024,
            author = {John Doe},
            title = {Test Article},
            year = {2024}
        }
        """
        
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.type, .article)
        XCTAssertEqual(entries.first?.citationKey, "test2024")
        XCTAssertEqual(entries.first?["author"], "John Doe")
        XCTAssertEqual(entries.first?["title"], "Test Article")
        XCTAssertEqual(entries.first?["year"], "2024")
    }
    
    func testParseMultipleEntries() throws {
        let bibtex = """
        @article{entry1, title = {First}}
        @book{entry2, title = {Second}}
        @inproceedings{entry3, title = {Third}}
        """
        
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries[0].type, .article)
        XCTAssertEqual(entries[1].type, .book)
        XCTAssertEqual(entries[2].type, .inproceedings)
    }
    
    // MARK: - Entry Type Tests
    
    func testParseAllStandardTypes() throws {
        let types = ["article", "book", "booklet", "conference", "inbook",
                     "incollection", "inproceedings", "manual", "mastersthesis",
                     "misc", "phdthesis", "proceedings", "techreport", "unpublished"]
        
        for type in types {
            let bibtex = "@\(type){test, title = {Test}}"
            let entries = try BibTeXParser.parse(bibtex)
            
            XCTAssertEqual(entries.count, 1, "Failed for type: \(type)")
            XCTAssertEqual(entries.first?.type.rawValue.lowercased(), type)
        }
    }
    
    func testParseCustomType() throws {
        let bibtex = "@dataset{mydata, title = {My Dataset}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.type, .custom("dataset"))
    }
    
    func testParseCaseInsensitiveType() throws {
        let bibtex = "@ARTICLE{test, title = {Test}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?.type, .article)
    }
    
    // MARK: - Field Parsing Tests
    
    func testParseFieldWithBraces() throws {
        let bibtex = "@article{test, title = {Hello World}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?["title"], "Hello World")
    }
    
    func testParseFieldWithQuotes() throws {
        let bibtex = "@article{test, title = \"Hello World\"}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?["title"], "Hello World")
    }
    
    func testParseFieldWithNumber() throws {
        let bibtex = "@article{test, year = 2024}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?["year"], "2024")
    }
    
    func testParseNestedBraces() throws {
        let bibtex = "@article{test, title = {Hello {Nested {Deep}} World}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        let title = entries.first?["title"]
        XCTAssertNotNil(title)
        XCTAssertTrue(title?.contains("Nested") ?? false)
    }
    
    func testParseFieldWithEquals() throws {
        let bibtex = "@article{test, title = {E = mc^2}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?["title"], "E = mc^2")
    }
    
    func testParseMultipleFields() throws {
        let bibtex = """
        @article{test,
            author = {John Doe},
            title = {Test Title},
            journal = {Test Journal},
            volume = {42},
            number = {7},
            pages = {100--200},
            year = {2024},
            doi = {10.1234/test}
        }
        """
        
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?.fields.count, 8)
        XCTAssertEqual(entries.first?["volume"], "42")
        XCTAssertEqual(entries.first?["pages"], "100--200")
    }
    
    // MARK: - Key Parsing Tests
    
    func testParseSimpleKey() throws {
        let bibtex = "@article{simplekey, title = {Test}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?.citationKey, "simplekey")
    }
    
    func testParseKeyWithNumbers() throws {
        let bibtex = "@article{author2024, title = {Test}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?.citationKey, "author2024")
    }
    
    func testParseKeyWithSpecialChars() throws {
        let bibtex = "@article{author:2024-paper_v1, title = {Test}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?.citationKey, "author:2024-paper_v1")
    }
    
    // MARK: - LaTeX Handling Tests
    
    func testParseLaTeXAccents() throws {
        let bibtex = "@article{test, author = {M\\\"uller}}"
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = true
        
        let entries = try BibTeXParser.parse(bibtex, options: options)
        
        XCTAssertEqual(entries.first?["author"], "Müller")
    }
    
    func testParseLaTeXWithoutConversion() throws {
        let bibtex = "@article{test, author = {M\\\"uller}}"
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false
        
        let entries = try BibTeXParser.parse(bibtex, options: options)
        
        XCTAssertEqual(entries.first?["author"], "M\\\"uller")
    }
    
    func testParseLaTeXSpecialChars() throws {
        let bibtex = "@article{test, title = {100\\% Complete}}"
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = true
        
        let entries = try BibTeXParser.parse(bibtex, options: options)
        
        let title = entries.first?["title"]
        XCTAssertTrue(title?.contains("100") ?? false)
    }
    
    // MARK: - Options Tests
    
    func testOptionsPreserveRawBibTeX() throws {
        let bibtex = "@article{test, title = {Test}}"
        var options = BibTeXParser.Options()
        options.preserveRawBibTeX = true
        
        let entries = try BibTeXParser.parse(bibtex, options: options)
        
        XCTAssertNotNil(entries.first?.rawBibTeX)
        XCTAssertTrue(entries.first?.rawBibTeX?.contains("@article") ?? false)
    }
    
    func testOptionsNormalizeFieldNames() throws {
        let bibtex = "@article{test, TITLE = {Test}, AUTHOR = {Author}}"
        var options = BibTeXParser.Options()
        options.normalizeFieldNames = true
        
        let entries = try BibTeXParser.parse(bibtex, options: options)
        
        XCTAssertNotNil(entries.first?["title"])
        XCTAssertNotNil(entries.first?["author"])
    }
    
    func testOptionsStripDelimiters() throws {
        let bibtex = "@article{test, title = {  Test  }}"
        var options = BibTeXParser.Options()
        options.stripDelimiters = true
        
        let entries = try BibTeXParser.parse(bibtex, options: options)
        
        XCTAssertEqual(entries.first?["title"], "Test")
    }
    
    func testDefaultOptions() {
        let options = BibTeXParser.Options()
        
        XCTAssertTrue(options.normalizeFieldNames)
        XCTAssertTrue(options.stripDelimiters)
        XCTAssertFalse(options.preserveRawBibTeX)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidEntryType() throws {
        let bibtex = "@{test, title = {Test}}"
        
        // Should not crash, might skip invalid entries
        let entries = try BibTeXParser.parse(bibtex)
        XCTAssertTrue(entries.isEmpty)
    }
    
    func testMissingClosingBrace() throws {
        let bibtex = "@article{test, title = {Unclosed"
        
        // Parser should handle gracefully
        let entries = try BibTeXParser.parse(bibtex)
        // May or may not parse, but shouldn't crash
        _ = entries
    }
    
    func testMissingKey() throws {
        let bibtex = "@article{, title = {Test}}"
        
        let entries = try BibTeXParser.parse(bibtex)
        // Should handle gracefully
        _ = entries
    }
    
    // MARK: - Comments and Whitespace Tests
    
    func testIgnoreComments() throws {
        let bibtex = """
        % This is a comment
        @article{test, title = {Test}}
        % Another comment
        """
        
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.count, 1)
    }
    
    func testWhitespaceHandling() throws {
        let bibtex = """
        
        
        @article{test,
            title    =    {  Test  }
        }
        
        
        """
        
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?["title"], "Test")
    }
    
    // MARK: - Special Content Tests
    
    func testUnicodeContent() throws {
        let bibtex = "@article{test, title = {日本語タイトル}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?["title"], "日本語タイトル")
    }
    
    func testURLInField() throws {
        let bibtex = "@misc{test, url = {https://example.com/path?query=1&other=2}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?["url"], "https://example.com/path?query=1&other=2")
    }
    
    func testDOIInField() throws {
        let bibtex = "@article{test, doi = {10.1000/xyz123}}"
        let entries = try BibTeXParser.parse(bibtex)
        
        XCTAssertEqual(entries.first?["doi"], "10.1000/xyz123")
    }
    
    // MARK: - Instance Parser Tests
    
    func testInstanceParser() throws {
        let parser = BibTeXParser()
        let bibtex = "@article{test, title = {Test}}"
        
        let entries = try parser.parse(bibtex)
        
        XCTAssertEqual(entries.count, 1)
    }
    
    func testInstanceParserWithOptions() throws {
        var options = BibTeXParser.Options()
        options.preserveRawBibTeX = true
        
        let parser = BibTeXParser(options: options)
        let bibtex = "@article{test, title = {Test}}"
        
        let entries = try parser.parse(bibtex)
        
        XCTAssertNotNil(entries.first?.rawBibTeX)
    }
    
    // MARK: - Complex Entry Tests
    
    func testRealWorldEntry() throws {
        let bibtex = """
        @article{einstein1905,
            author = {Albert Einstein},
            title = {Zur Elektrodynamik bewegter K\\"orper},
            journal = {Annalen der Physik},
            volume = {17},
            number = {10},
            pages = {891--921},
            year = {1905},
            doi = {10.1002/andp.19053221004},
            abstract = {This paper introduces the special theory of relativity.}
        }
        """
        
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = true
        
        let entries = try BibTeXParser.parse(bibtex, options: options)
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.citationKey, "einstein1905")
        XCTAssertEqual(entries.first?.type, .article)
        XCTAssertEqual(entries.first?["author"], "Albert Einstein")
        XCTAssertEqual(entries.first?["title"], "Zur Elektrodynamik bewegter Körper")
        XCTAssertEqual(entries.first?["year"], "1905")
    }
    
    // MARK: - Performance Tests
    
    func testParsingPerformance() throws {
        var largeBibtex = ""
        for i in 0..<100 {
            largeBibtex += """
            @article{entry\(i),
                author = {Author \(i)},
                title = {Title \(i)},
                journal = {Journal \(i)},
                year = {\(2000 + i)}
            }
            
            """
        }
        
        measure {
            _ = try? BibTeXParser.parse(largeBibtex)
        }
    }
}
