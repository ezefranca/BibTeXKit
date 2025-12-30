//
//  BibTeXTokenizerTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
@testable import BibTeXKit

final class BibTeXTokenizerTests: XCTestCase {
    
    private let tokenizer = BibTeXTokenizer()
    
    // MARK: - Basic Tokenization
    
    func testEmptyString() {
        let tokens = tokenizer.tokenize("")
        XCTAssertTrue(tokens.isEmpty)
    }
    
    func testWhitespaceOnly() {
        let tokens = tokenizer.tokenize("   \n\t  ")
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens.first?.token, .whitespace)
    }
    
    // MARK: - Entry Type Tokenization
    
    func testArticleEntryType() {
        let tokens = tokenizer.tokenize("@article")
        
        let atSymbol = tokens.first { $0.token == .special }
        let entryType = tokens.first { $0.token == .entryType }
        
        XCTAssertNotNil(atSymbol)
        XCTAssertNotNil(entryType)
        XCTAssertEqual(entryType?.text.lowercased(), "article")
    }
    
    func testBookEntryType() {
        let tokens = tokenizer.tokenize("@book")
        
        let entryType = tokens.first { $0.token == .entryType }
        XCTAssertNotNil(entryType)
        XCTAssertEqual(entryType?.text.lowercased(), "book")
    }
    
    func testAllStandardEntryTypes() {
        let types = ["article", "book", "inproceedings", "phdthesis", "misc", "techreport"]
        
        for type in types {
            let tokens = tokenizer.tokenize("@\(type)")
            let entryTypeToken = tokens.first { $0.token == .entryType }
            XCTAssertNotNil(entryTypeToken, "Failed for type: \(type)")
        }
    }
    
    // MARK: - Key Tokenization
    
    func testCitationKey() {
        let tokens = tokenizer.tokenize("@article{einstein1905,")
        
        let key = tokens.first { $0.token == .citationKey }
        XCTAssertNotNil(key)
        XCTAssertEqual(key?.text, "einstein1905")
    }
    
    func testKeyWithSpecialCharacters() {
        let tokens = tokenizer.tokenize("@article{author:2024-paper,")
        
        let key = tokens.first { $0.token == .citationKey }
        XCTAssertNotNil(key)
    }
    
    // MARK: - Field Name Tokenization
    
    func testFieldName() {
        let bibtex = """
        @article{test,
            author = {Test}
        }
        """
        let tokens = tokenizer.tokenize(bibtex)
        
        let fieldName = tokens.first { $0.token == .fieldName }
        XCTAssertNotNil(fieldName)
        XCTAssertEqual(fieldName?.text.trimmingCharacters(in: .whitespaces), "author")
    }
    
    func testMultipleFieldNames() {
        let bibtex = """
        @article{test,
            author = {Test},
            title = {Title},
            year = {2024}
        }
        """
        let tokens = tokenizer.tokenize(bibtex)
        
        let fieldNames = tokens.filter { $0.token == .fieldName }
        XCTAssertGreaterThanOrEqual(fieldNames.count, 3)
    }
    
    // MARK: - String Value Tokenization
    
    func testBracedStringValue() {
        let bibtex = "@article{test, title = {Hello World}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let stringTokens = tokens.filter { $0.token == .string }
        XCTAssertFalse(stringTokens.isEmpty)
    }
    
    func testNestedBraces() {
        let bibtex = "@article{test, title = {Hello {Nested} World}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        // Should handle nested braces without breaking
        XCTAssertFalse(tokens.isEmpty)
    }
    
    // MARK: - Number Tokenization
    
    func testYearAsNumber() {
        let bibtex = "@article{test, year = 2024}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let number = tokens.first { $0.token == .number }
        XCTAssertNotNil(number)
        XCTAssertEqual(number?.text, "2024")
    }
    
    func testVolumeAsNumber() {
        let bibtex = "@article{test, volume = 42}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let number = tokens.first { $0.token == .number }
        XCTAssertNotNil(number)
    }
    
    // MARK: - Comment Tokenization
    
    func testLineComment() {
        let bibtex = """
        % This is a comment
        @article{test, title = {Test}}
        """
        let tokens = tokenizer.tokenize(bibtex)
        
        let comment = tokens.first { $0.token == .comment }
        XCTAssertNotNil(comment)
        XCTAssertTrue(comment?.text.contains("This is a comment") ?? false)
    }
    
    func testMultipleComments() {
        let bibtex = """
        % Comment 1
        @article{test,
            % Comment 2
            title = {Test}
        }
        """
        let tokens = tokenizer.tokenize(bibtex)
        
        let comments = tokens.filter { $0.token == .comment }
        XCTAssertEqual(comments.count, 2)
    }
    
    // MARK: - LaTeX Command Tokenization
    
    func testLaTeXMathMode() {
        let bibtex = "@article{test, title = {Energy $E = mc^2$}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let mathTokens = tokens.filter { $0.token == .math }
        XCTAssertFalse(mathTokens.isEmpty)
    }
    
    func testLaTeXDisplayMath() {
        let bibtex = "@article{test, abstract = {Formula: $$\\sum_{i=0}^n$$}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        XCTAssertFalse(tokens.isEmpty)
    }
    
    func testLaTeXEnvironment() {
        let bibtex = "@article{test, abstract = {\\begin{equation}x^2\\end{equation}}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let envTokens = tokens.filter { $0.token == .environment }
        XCTAssertFalse(envTokens.isEmpty)
    }
    
    // MARK: - Special Character Tokenization
    
    func testSpecialCharacters() {
        let bibtex = "@article{test,}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let specials = tokens.filter { $0.token == .special }
        XCTAssertFalse(specials.isEmpty)
    }
    
    func testBraceTokenization() {
        let bibtex = "@article{test, title = {Hello}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let braces = tokens.filter { $0.token == .text }
        XCTAssertFalse(braces.isEmpty)
    }
    
    // MARK: - Operator Tokenization
    
    func testEqualsOperator() {
        let bibtex = "@article{test, title = {Test}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let operators = tokens.filter { $0.token == .operator }
        XCTAssertFalse(operators.isEmpty)
    }
    
    func testConcatenationOperator() {
        let bibtex = "@article{test, title = {Part 1} # { Part 2}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let hashOps = tokens.filter { $0.token == .operator && $0.text == "#" }
        XCTAssertFalse(hashOps.isEmpty)
    }
    
    // MARK: - Complex Entry Tokenization
    
    func testCompleteEntry() {
        let bibtex = """
        @article{einstein1905,
            author = {Albert Einstein},
            title = {Zur Elektrodynamik bewegter K\\"orper},
            journal = {Annalen der Physik},
            volume = {17},
            pages = {891--921},
            year = {1905},
            doi = {10.1002/andp.19053221004}
        }
        """
        let tokens = tokenizer.tokenize(bibtex)
        
        // Verify all token types present
        let tokenTypes = Set(tokens.map { $0.token })
        
        XCTAssertTrue(tokenTypes.contains(.special))      // @
        XCTAssertTrue(tokenTypes.contains(.entryType))    // article
        XCTAssertTrue(tokenTypes.contains(.citationKey))          // einstein1905
        XCTAssertTrue(tokenTypes.contains(.fieldName))    // author, title, etc.
        XCTAssertTrue(tokenTypes.contains(.operator))     // =
        XCTAssertTrue(tokenTypes.contains(.specialChar))        // { }
    }
    
    func testMultipleEntries() {
        let bibtex = """
        @article{entry1, title = {First}}
        @book{entry2, title = {Second}}
        """
        let tokens = tokenizer.tokenize(bibtex)
        
        let entryTypes = tokens.filter { $0.token == .entryType }
        XCTAssertEqual(entryTypes.count, 2)
        
        let keys = tokens.filter { $0.token == .citationKey }
        XCTAssertEqual(keys.count, 2)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyEntry() {
        let bibtex = "@misc{empty,}"
        let tokens = tokenizer.tokenize(bibtex)
        
        XCTAssertFalse(tokens.isEmpty)
    }
    
    func testEntryWithNoFields() {
        let bibtex = "@misc{test}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let key = tokens.first { $0.token == .citationKey }
        XCTAssertNotNil(key)
    }
    
    func testUnicodeInStrings() {
        let bibtex = "@article{test, author = {日本語 中文 한국어}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let stringToken = tokens.first { $0.text.contains("日本語") }
        XCTAssertNotNil(stringToken)
    }
    
    func testEmojiInStrings() {
        let bibtex = "@misc{test, note = {Hello 👋 World 🌍}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let hasEmoji = tokens.contains { $0.text.contains("👋") }
        XCTAssertTrue(hasEmoji)
    }
    
    // MARK: - Performance Tests
    
    func testLargeBibTeXPerformance() {
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
            _ = tokenizer.tokenize(largeBibtex)
        }
    }
    
    // MARK: - Token Range Tests
    
    func testTokenRanges() {
        let bibtex = "@article{test, title = {Hello}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        // All tokens should have valid ranges
        for tokenInfo in tokens {
            XCTAssertFalse(tokenInfo.text.isEmpty, "Token text should not be empty")
        }
    }
    
    func testTokensCoverFullText() {
        let bibtex = "@article{test}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let reconstructed = tokens.map { $0.text }.joined()
        XCTAssertEqual(reconstructed, bibtex)
    }
}
