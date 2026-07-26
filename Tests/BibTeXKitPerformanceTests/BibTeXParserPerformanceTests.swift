//
//  BibTeXParserPerformanceTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import XCTest

@testable import BibTeXKit

final class BibTeXParserPerformanceTests: XCTestCase {
    func testGivenLargeBibTeXInputWhenParsingThenPerformanceIsMeasured() throws {
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

        XCTAssertEqual(try BibTeXParser.parse(largeBibtex).count, 100)

        var measuredCount = 0
        measure {
            do {
                measuredCount = try BibTeXParser.parse(largeBibtex).count
            } catch {
                XCTFail("Parsing failed during measurement: \(error)")
            }
        }
        XCTAssertEqual(measuredCount, 100)
    }

    func testGivenPlainEntriesWhenParsingWithoutLaTeXConversionThenPerformanceIsMeasured() throws {
        let largeBibtex = (0..<400).map { index in
            """
            @article{plain\(index),
                author = {Author \(index)},
                title = {Title \(index)},
                journal = {Journal \(index)},
                year = {\(2000 + index)}
            }
            """
        }.joined(separator: "\n")
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        XCTAssertEqual(
            try BibTeXParser.parse(largeBibtex, options: options).count,
            400
        )
        var measuredCount = 0
        measure {
            do {
                measuredCount = try BibTeXParser.parse(
                    largeBibtex,
                    options: options
                ).count
            } catch {
                XCTFail("Parsing failed during measurement: \(error)")
            }
        }
        XCTAssertEqual(measuredCount, 400)
    }
}
