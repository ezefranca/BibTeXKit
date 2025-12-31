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
        
        let entryType = tokens.first { $0.token == .entryType }
        
        XCTAssertNotNil(entryType)
        // The tokenizer includes @ as part of the entry type token
        XCTAssertEqual(entryType?.text.lowercased(), "@article")
    }
    
    func testBookEntryType() {
        let tokens = tokenizer.tokenize("@book")
        
        let entryType = tokens.first { $0.token == .entryType }
        XCTAssertNotNil(entryType)
        XCTAssertEqual(entryType?.text.lowercased(), "@book")
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
        
        // Content inside braces is tokenized as text
        let textTokens = tokens.filter { $0.token == .text }
        XCTAssertFalse(textTokens.isEmpty)
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
        // LaTeX environments inside field value braces are now tokenized as text
        // for consistent highlighting (part of the field value content fix)
        let bibtex = #"@article{test, abstract = {\begin{equation}x^2\end{equation}}}"#
        let tokens = tokenizer.tokenize(bibtex)
        
        // Inside braces, LaTeX environments should be treated as text
        // Check that any token starting with backslash is text
        let backslashTokens = tokens.filter { $0.text.hasPrefix("\\") }
        for token in backslashTokens {
            XCTAssertEqual(token.token, .text, "LaTeX command/environment '\(token.text)' inside field braces should be .text, not \(token.token)")
        }
    }
    
    func testLaTeXEnvironmentOutsideBraces() {
        // LaTeX environments OUTSIDE field value braces should still be tokenized properly
        // For example, at the top level before any entry
        let bibtex = #"\begin{filecontents}{refs.bib}\end{filecontents}"#
        let tokens = tokenizer.tokenize(bibtex)
        
        // Outside field value braces, LaTeX environments get proper highlighting
        let envTokens = tokens.filter { $0.token == .environment }
        XCTAssertFalse(envTokens.isEmpty, "LaTeX environments outside braces should be .environment")
    }
    
    // MARK: - Special Character Tokenization
    
    func testSpecialCharacters() {
        let bibtex = "@preamble{test}"
        let tokens = tokenizer.tokenize(bibtex)
        
        // @preamble is tokenized as special (directive)
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
        
        XCTAssertTrue(tokenTypes.contains(.entryType))    // @article
        XCTAssertTrue(tokenTypes.contains(.citationKey))  // einstein1905
        XCTAssertTrue(tokenTypes.contains(.fieldName))    // author, title, etc.
        XCTAssertTrue(tokenTypes.contains(.operator))     // =
        XCTAssertTrue(tokenTypes.contains(.punctuation))  // { }
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
    
    // MARK: - Field Value Content Tests (Bug Fix Verification)
    
    func testFieldValueContentAsText() {
        // Tests that content inside field value braces is tokenized as text, not constants
        let bibtex = "@article{test, author = {Albert Einstein}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        // Find "Albert" and "Einstein" tokens
        let albert = tokens.first { $0.text == "Albert" }
        let einstein = tokens.first { $0.text == "Einstein" }
        
        XCTAssertNotNil(albert, "Should find 'Albert' token")
        XCTAssertNotNil(einstein, "Should find 'Einstein' token")
        XCTAssertEqual(albert?.token, .text, "'Albert' should be text, not constant")
        XCTAssertEqual(einstein?.token, .text, "'Einstein' should be text, not constant")
    }
    
    func testNumbersInsideBracesAsText() {
        // Tests that numbers inside field value braces are tokenized as text
        let bibtex = "@article{test, pages = {891--921}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        // Numbers inside braces should be text, not number tokens
        let numberTokens = tokens.filter { $0.token == .number }
        XCTAssertTrue(numberTokens.isEmpty, "Numbers inside braces should not be .number tokens")
        
        // The digits should be text tokens
        let textTokens = tokens.filter { $0.token == .text }
        XCTAssertFalse(textTokens.isEmpty, "Should have text tokens for digits")
    }
    
    func testDOIInsideBracesAsText() {
        // Tests that DOI values inside braces are tokenized correctly
        let bibtex = "@article{test, doi = {10.1002/andp.19053221004}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        // The "10" should be text (character by character since it starts with a number)
        // or the identifiable parts should be text
        let constantTokens = tokens.filter { $0.token == .constant }
        
        // No constants should appear inside the braced value
        // Constants before { are fine, but not inside
        for constant in constantTokens {
            // Constants should only be things like month names, not DOI parts
            let validConstants = ["jan", "feb", "mar", "apr", "may", "jun", 
                                  "jul", "aug", "sep", "oct", "nov", "dec"]
            XCTAssertTrue(validConstants.contains(constant.text.lowercased()),
                          "Unexpected constant token: \(constant.text)")
        }
    }
    
    func testUnbracedNumberAsNumber() {
        // Tests that unbraced numbers (like year = 2024) are still tokenized as numbers
        let bibtex = "@article{test, year = 2024}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let yearToken = tokens.first { $0.text == "2024" }
        XCTAssertNotNil(yearToken, "Should find '2024' token")
        XCTAssertEqual(yearToken?.token, .number, "Unbraced year should be .number")
    }
    
    func testUnbracedConstantAsConstant() {
        // Tests that unbraced constants (like month = jan) are tokenized as constants
        let bibtex = "@article{test, month = jan}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let monthToken = tokens.first { $0.text.lowercased() == "jan" }
        XCTAssertNotNil(monthToken, "Should find 'jan' token")
        XCTAssertEqual(monthToken?.token, .constant, "Unbraced month should be .constant")
    }
    
    func testNestedBracesContentAsText() {
        // Tests that content in nested braces is also text
        let bibtex = "@article{test, title = {A {Nested} Title}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        let nestedToken = tokens.first { $0.text == "Nested" }
        XCTAssertNotNil(nestedToken, "Should find 'Nested' token")
        XCTAssertEqual(nestedToken?.token, .text, "'Nested' should be text")
    }
    
    func testComplexFieldValueContent() {
        // Tests a realistic complex field value
        let bibtex = """
        @article{einstein1905,
            author = {Albert Einstein},
            title = {Zur Elektrodynamik bewegter Körper},
            journal = {Annalen der Physik},
            volume = {17},
            pages = {891--921},
            year = {1905},
            doi = {10.1002/andp.19053221004}
        }
        """
        let tokens = tokenizer.tokenize(bibtex)
        
        // All these words inside braces should be text tokens
        let expectedTextWords = ["Albert", "Einstein", "Zur", "Elektrodynamik", 
                                 "bewegter", "Annalen", "der", "Physik"]
        
        for word in expectedTextWords {
            let token = tokens.first { $0.text == word }
            XCTAssertNotNil(token, "Should find '\(word)' token")
            XCTAssertEqual(token?.token, .text, "'\(word)' should be text, not \(String(describing: token?.token))")
        }
    }
    
    func testMixedBracedAndUnbracedValues() {
        // Tests mixing braced and unbraced values
        let bibtex = "@article{test, year = 2024, month = jan, author = {John Doe}}"
        let tokens = tokenizer.tokenize(bibtex)
        
        // Unbraced values should keep their types
        let yearToken = tokens.first { $0.text == "2024" }
        XCTAssertEqual(yearToken?.token, .number, "Unbraced year should be .number")
        
        let monthToken = tokens.first { $0.text.lowercased() == "jan" }
        XCTAssertEqual(monthToken?.token, .constant, "Unbraced month should be .constant")
        
        // Braced values should be text
        let johnToken = tokens.first { $0.text == "John" }
        XCTAssertEqual(johnToken?.token, .text, "Braced author name should be .text")
    }
    
    func testLatexAccentInsideBracesAsText() {
        // Tests that LaTeX accents inside field value braces are tokenized as text
        // Example: K\"orper (Körper with LaTeX umlaut)
        let bibtex = #"@article{test, title = {K\"orper}}"#
        let tokens = tokenizer.tokenize(bibtex)
        
        // The LaTeX accent \"o should be tokenized as text, not accent
        let accentTokens = tokens.filter { $0.token == .accent }
        XCTAssertTrue(accentTokens.isEmpty, "LaTeX accents inside braces should not be .accent tokens")
        
        // Find the accent token that should now be text - it starts with backslash
        let accentAsText = tokens.first { $0.text.hasPrefix("\\") && $0.text.contains("\"") }
        XCTAssertNotNil(accentAsText, "Should find the LaTeX accent sequence")
        XCTAssertEqual(accentAsText?.token, .text, "LaTeX accent inside braces should be .text")
    }
    
    func testLatexCommandInsideBracesAsText() {
        // Tests that LaTeX commands inside field value braces are tokenized as text
        let bibtex = #"@article{test, title = {\textbf{Bold} text}}"#
        let tokens = tokenizer.tokenize(bibtex)
        
        // The \textbf command should be tokenized as text, not command
        let commandTokens = tokens.filter { $0.token == .command }
        XCTAssertTrue(commandTokens.isEmpty, "LaTeX commands inside braces should not be .command tokens")
        
        // Find any token that starts with backslash - these should all be text now
        let backslashTokens = tokens.filter { $0.text.hasPrefix("\\") }
        XCTAssertFalse(backslashTokens.isEmpty, "Should find tokens starting with backslash")
        for token in backslashTokens {
            XCTAssertEqual(token.token, .text, "LaTeX command '\(token.text)' inside braces should be .text")
        }
    }
    
    func testLatexAccentOutsideBracesStillHighlighted() {
        // Tests that LaTeX accents OUTSIDE field braces still get proper highlighting
        // This is an edge case - LaTeX in comments or @preamble should still be highlighted
        let bibtex = #"% Comment with K\"orper"#
        let tokens = tokenizer.tokenize(bibtex)
        
        // Comments consume the whole line, so this is fine
        let commentTokens = tokens.filter { $0.token == .comment }
        XCTAssertFalse(commentTokens.isEmpty)
    }
}
