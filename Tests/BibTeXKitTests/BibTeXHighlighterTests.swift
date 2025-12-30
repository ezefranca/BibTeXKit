//
//  BibTeXHighlighterTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
import SwiftUI
@testable import BibTeXKit

final class BibTeXHighlighterTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitWithTheme() {
        let theme = MonokaiTheme()
        let highlighter = BibTeXHighlighter(theme: theme)
        
        XCTAssertEqual(highlighter.theme.name, "Monokai")
    }
    
    func testInitWithDefaultTheme() {
        let highlighter = BibTeXHighlighter()
        
        XCTAssertEqual(highlighter.theme.name, "Default Light")
    }
    
    func testInitWithColorSchemeLight() {
        let highlighter = BibTeXHighlighter(colorScheme: .light)
        
        XCTAssertEqual(highlighter.theme.name, "Default Light")
    }
    
    func testInitWithColorSchemeDark() {
        let highlighter = BibTeXHighlighter(colorScheme: .dark)
        
        XCTAssertEqual(highlighter.theme.name, "Default Dark")
    }
    
    // MARK: - Basic Highlighting Tests
    
    func testHighlightEmptyString() {
        let highlighter = BibTeXHighlighter()
        let result = highlighter.highlight("")
        
        XCTAssertTrue(result.characters.isEmpty)
    }
    
    func testHighlightSimpleEntry() {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, title = {Hello}}"
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertFalse(result.characters.isEmpty)
        XCTAssertEqual(String(result.characters), bibtex)
    }
    
    func testHighlightPreservesText() {
        let highlighter = BibTeXHighlighter()
        let bibtex = """
        @article{einstein1905,
            author = {Albert Einstein},
            title = {Relativity},
            year = {1905}
        }
        """
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertEqual(String(result.characters), bibtex)
    }
    
    // MARK: - Entry Highlighting Tests
    
    func testHighlightEntry() {
        let highlighter = BibTeXHighlighter()
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test", "year": "2024"]
        )
        
        let result = highlighter.highlight(entry: entry)
        
        XCTAssertFalse(result.characters.isEmpty)
        let text = String(result.characters)
        XCTAssertTrue(text.contains("@article"))
        XCTAssertTrue(text.contains("test"))
    }
    
    func testHighlightEntryWithStyle() {
        let highlighter = BibTeXHighlighter()
        let entry = BibTeXEntry(
            type: .book,
            citationKey: "knuth1997",
            fields: ["title": "TAOCP", "author": "Knuth"]
        )
        
        let compact = highlighter.highlight(entry: entry, style: .compact)
        let aligned = highlighter.highlight(entry: entry, style: .aligned)
        
        // Both should contain the same basic info
        XCTAssertTrue(String(compact.characters).contains("@book"))
        XCTAssertTrue(String(aligned.characters).contains("@book"))
    }
    
    // MARK: - Theme Application Tests
    
    func testDifferentThemesProduceDifferentResults() {
        let lightHighlighter = BibTeXHighlighter(theme: DefaultLightTheme())
        let darkHighlighter = BibTeXHighlighter(theme: DefaultDarkTheme())
        
        let bibtex = "@article{test, title = {Hello}}"
        
        let lightResult = lightHighlighter.highlight(bibtex)
        let darkResult = darkHighlighter.highlight(bibtex)
        
        // Both should produce the same text
        XCTAssertEqual(String(lightResult.characters), String(darkResult.characters))
    }
    
    func testMonokaiThemeHighlighting() {
        let highlighter = BibTeXHighlighter(theme: MonokaiTheme())
        let bibtex = "@article{test, title = {Hello}}"
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertFalse(result.characters.isEmpty)
    }
    
    func testSolarizedThemeHighlighting() {
        let highlighter = BibTeXHighlighter(theme: SolarizedLightTheme())
        let bibtex = "@article{test, title = {Hello}}"
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertFalse(result.characters.isEmpty)
    }
    
    func testXcodeThemeHighlighting() {
        let highlighter = BibTeXHighlighter(theme: XcodeDarkTheme())
        let bibtex = "@article{test, title = {Hello}}"
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertFalse(result.characters.isEmpty)
    }
    
    // MARK: - Complex Content Tests
    
    func testHighlightWithLaTeX() {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, author = {M\\\"uller}}"
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertFalse(result.characters.isEmpty)
    }
    
    func testHighlightWithComments() {
        let highlighter = BibTeXHighlighter()
        let bibtex = """
        % This is a comment
        @article{test, title = {Hello}}
        """
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertTrue(String(result.characters).contains("% This is a comment"))
    }
    
    func testHighlightWithMultipleEntries() {
        let highlighter = BibTeXHighlighter()
        let bibtex = """
        @article{entry1, title = {First}}
        @book{entry2, title = {Second}}
        """
        
        let result = highlighter.highlight(bibtex)
        let text = String(result.characters)
        
        XCTAssertTrue(text.contains("@article"))
        XCTAssertTrue(text.contains("@book"))
    }
    
    func testHighlightWithNestedBraces() {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, title = {Hello {Nested} World}}"
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertTrue(String(result.characters).contains("Nested"))
    }
    
    func testHighlightWithMath() {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, title = {Energy $E = mc^2$}}"
        
        let result = highlighter.highlight(bibtex)
        
        XCTAssertTrue(String(result.characters).contains("E = mc^2"))
    }
    
    // MARK: - BibTeXEntry Extension Tests
    
    func testEntryHighlightedMethod() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )
        
        let result = entry.highlighted()
        
        XCTAssertFalse(result.characters.isEmpty)
    }
    
    func testEntryHighlightedWithTheme() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )
        
        let result = entry.highlighted(theme: MonokaiTheme())
        
        XCTAssertFalse(result.characters.isEmpty)
    }
    
    func testEntryHighlightedWithStyle() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )
        
        let compact = entry.highlighted(style: .compact)
        let aligned = entry.highlighted(style: .aligned)
        
        XCTAssertFalse(compact.characters.isEmpty)
        XCTAssertFalse(aligned.characters.isEmpty)
    }
    
    func testEntryHighlightedWithColorScheme() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["title": "Test"]
        )
        
        let light = entry.highlighted(colorScheme: .light)
        let dark = entry.highlighted(colorScheme: .dark)
        
        XCTAssertFalse(light.characters.isEmpty)
        XCTAssertFalse(dark.characters.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testHighlightingPerformance() {
        let highlighter = BibTeXHighlighter()
        
        var largeBibtex = ""
        for i in 0..<50 {
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
            _ = highlighter.highlight(largeBibtex)
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testHighlighterIsSendable() {
        let highlighter = BibTeXHighlighter()
        
        Task {
            let result = highlighter.highlight("@article{test}")
            XCTAssertFalse(result.characters.isEmpty)
        }
    }
    
    func testConcurrentHighlighting() async {
        let highlighter = BibTeXHighlighter()
        let bibtex = "@article{test, title = {Hello}}"
        
        await withTaskGroup(of: AttributedString.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    highlighter.highlight(bibtex)
                }
            }
            
            var results: [AttributedString] = []
            for await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, 10)
            
            // All results should be the same
            let firstText = String(results[0].characters)
            for result in results {
                XCTAssertEqual(String(result.characters), firstText)
            }
        }
    }
}
