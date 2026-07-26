//
//  TransformationPerformanceTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import XCTest

@testable import BibTeXKit

final class TransformationPerformanceTests: XCTestCase {
    func testGivenLargeBibTeXInputWhenTokenizingThenPerformanceIsMeasured() {
        let tokenizer = BibTeXTokenizer()
        var largeBibtex = ""
        for index in 0..<100 {
            largeBibtex += """
                @article{entry\(index),
                    author = {Author \(index)},
                    title = {Title \(index)},
                    journal = {Journal \(index)},
                    year = {\(2000 + index)}
                }

                """
        }

        let expectedText = largeBibtex
        XCTAssertEqual(
            tokenizer.tokenize(largeBibtex).map(\.text).joined(),
            expectedText
        )

        var measuredTokens: [BibTeXTokenInfo] = []
        measure {
            measuredTokens = tokenizer.tokenize(largeBibtex)
        }
        XCTAssertEqual(measuredTokens.map(\.text).joined(), expectedText)
    }

    func testGivenRepeatedLaTeXAccentsWhenConvertingToUnicodeThenPerformanceIsMeasured() {
        let input = String(repeating: "M\\\"uller ", count: 1_000)
        let expected = String(repeating: "Müller ", count: 1_000)

        XCTAssertEqual(LaTeXConverter.toUnicode(input), expected)

        var measuredOutput = ""
        measure {
            measuredOutput = LaTeXConverter.toUnicode(input)
        }
        XCTAssertEqual(measuredOutput, expected)
    }

    func testGivenLargeBibTeXInputWhenHighlightingThenPerformanceIsMeasured() {
        let highlighter = BibTeXHighlighter()
        var largeBibtex = ""
        for index in 0..<50 {
            largeBibtex += """
                @article{entry\(index),
                    author = {Author \(index)},
                    title = {Title \(index)},
                    journal = {Journal \(index)},
                    year = {\(2000 + index)}
                }

                """
        }

        let expectedText = largeBibtex
        XCTAssertEqual(
            String(highlighter.highlight(largeBibtex).characters),
            expectedText
        )

        var measuredOutput = AttributedString()
        measure {
            measuredOutput = highlighter.highlight(largeBibtex)
        }
        XCTAssertEqual(String(measuredOutput.characters), expectedText)
    }

    func testGivenManyPresentedDOIsWhenExtractingThenPerformanceIsMeasured() {
        let count = 1_000
        let input = (0..<count).map { index in
            "https://doi.org/10.1000/flight-\(index)"
        }.joined(separator: " ")
        let expected = (0..<count).map { "10.1000/flight-\($0)" }

        XCTAssertEqual(DOIDetector.extractAllDOIs(from: input), expected)

        var measuredDOIs: [String] = []
        measure {
            measuredDOIs = DOIDetector.extractAllDOIs(from: input)
        }
        XCTAssertEqual(measuredDOIs, expected)
    }
}
