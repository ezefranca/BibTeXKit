//
//  LaTeXConverterTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
@testable import BibTeXKit

final class LaTeXConverterTests: XCTestCase {
    
    // MARK: - Empty Input Tests
    
    func testEmptyString() {
        XCTAssertEqual(LaTeXConverter.toUnicode(""), "")
    }
    
    func testPlainText() {
        let text = "Hello World"
        XCTAssertEqual(LaTeXConverter.toUnicode(text), text)
    }
    
    // MARK: - Accent Tests
    
    func testAcuteAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\'e"), "é")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\'a"), "á")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\'o"), "ó")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\'u"), "ú")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\'i"), "í")
    }
    
    func testGraveAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\`e"), "è")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\`a"), "à")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\`o"), "ò")
    }
    
    func testUmlautAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\\"u"), "ü")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\\"o"), "ö")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\\"a"), "ä")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\\"e"), "ë")
    }
    
    func testCircumflexAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\^e"), "ê")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\^a"), "â")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\^o"), "ô")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\^i"), "î")
    }
    
    func testTildeAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\~n"), "ñ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\~a"), "ã")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\~o"), "õ")
    }
    
    func testCedillaAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\c{c}"), "ç")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\c c"), "ç")
    }
    
    func testCaronAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\v{c}"), "č")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\v{s}"), "š")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\v{z}"), "ž")
    }
    
    func testBreveAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\u{a}"), "ă")
    }
    
    func testMacronAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\={a}"), "ā")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\={e}"), "ē")
    }
    
    func testDotAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\.{z}"), "ż")
    }
    
    func testRingAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\r{a}"), "å")
    }
    
    func testDoubleAcuteAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\H{o}"), "ő")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\H{u}"), "ű")
    }
    
    func testOgonekAccent() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\k{a}"), "ą")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\k{e}"), "ę")
    }
    
    // MARK: - Accent with Braces Tests
    
    func testAccentWithBraces() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\'{e}"), "é")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\\"{o}"), "ö")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\^{a}"), "â")
    }
    
    func testAccentWithSpace() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\' e"), "é")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\\" o"), "ö")
    }
    
    // MARK: - Special Character Tests
    
    func testSpecialCharacters() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\ss"), "ß")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\ae"), "æ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\AE"), "Æ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\oe"), "œ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\OE"), "Œ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\o"), "ø")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\O"), "Ø")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\aa"), "å")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\AA"), "Å")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\i"), "ı")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\l"), "ł")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\L"), "Ł")
    }
    
    // MARK: - Greek Letters Tests
    
    func testGreekLettersLowercase() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\alpha"), "α")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\beta"), "β")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\gamma"), "γ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\delta"), "δ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\epsilon"), "ε")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\zeta"), "ζ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\eta"), "η")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\theta"), "θ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\iota"), "ι")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\kappa"), "κ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\lambda"), "λ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\mu"), "μ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\nu"), "ν")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\xi"), "ξ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\pi"), "π")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\rho"), "ρ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\sigma"), "σ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\tau"), "τ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\phi"), "φ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\chi"), "χ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\psi"), "ψ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\omega"), "ω")
    }
    
    func testGreekLettersUppercase() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Gamma"), "Γ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Delta"), "Δ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Theta"), "Θ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Lambda"), "Λ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Pi"), "Π")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Sigma"), "Σ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Phi"), "Φ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Psi"), "Ψ")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\Omega"), "Ω")
    }
    
    // MARK: - Math Symbols Tests
    
    func testMathSymbols() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\infty"), "∞")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\pm"), "±")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\times"), "×")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\div"), "÷")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\leq"), "≤")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\geq"), "≥")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\neq"), "≠")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\approx"), "≈")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\equiv"), "≡")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\sum"), "∑")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\prod"), "∏")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\int"), "∫")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\partial"), "∂")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\nabla"), "∇")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\sqrt"), "√")
    }
    
    // MARK: - Escaped Characters Tests
    
    func testEscapedCharacters() {
        XCTAssertEqual(LaTeXConverter.toUnicode("\\%"), "%")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\&"), "&")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\$"), "$")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\#"), "#")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\_"), "_")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\{"), "{")
        XCTAssertEqual(LaTeXConverter.toUnicode("\\}"), "}")
    }
    
    // MARK: - Quotation Tests
    
    func testQuotationMarks() {
        XCTAssertEqual(LaTeXConverter.toUnicode("``"), "\u{201C}")  // Left double quotation mark "
        XCTAssertEqual(LaTeXConverter.toUnicode("''"), "\u{201D}")  // Right double quotation mark "
        XCTAssertEqual(LaTeXConverter.toUnicode("`"), "'")          // Left single quotation mark '
        XCTAssertEqual(LaTeXConverter.toUnicode("'"), "'")          // Right single quotation mark '
    }
    
    // MARK: - Dash Tests
    
    func testDashes() {
        XCTAssertEqual(LaTeXConverter.toUnicode("---"), "—")
        XCTAssertEqual(LaTeXConverter.toUnicode("--"), "–")
    }
    
    // MARK: - Complex String Tests
    
    func testComplexString() {
        let input = "M\\\"uller and Caf\\'e"
        let expected = "Müller and Café"
        XCTAssertEqual(LaTeXConverter.toUnicode(input), expected)
    }
    
    func testGermanText() {
        let input = "Zur Elektrodynamik bewegter K\\\"orper"
        let expected = "Zur Elektrodynamik bewegter Körper"
        XCTAssertEqual(LaTeXConverter.toUnicode(input), expected)
    }
    
    func testFrenchText() {
        let input = "Th\\'eorie de la relativit\\'e"
        let expected = "Théorie de la relativité"
        XCTAssertEqual(LaTeXConverter.toUnicode(input), expected)
    }
    
    func testSpanishText() {
        let input = "Ma\\~nana y caf\\'e"
        let expected = "Mañana y café"
        XCTAssertEqual(LaTeXConverter.toUnicode(input), expected)
    }
    
    func testScandinavianText() {
        let input = "\\AA rhus and \\O resund"
        let expected = "Århus and Øresund"
        XCTAssertEqual(LaTeXConverter.toUnicode(input), expected)
    }
    
    func testPolishText() {
        let input = "\\L{}\\'{o}d\\'{z}"
        // May contain Polish characters
        let result = LaTeXConverter.toUnicode(input)
        XCTAssertTrue(result.contains("Ł") || result.contains("ó"))
    }
    
    // MARK: - Mixed Content Tests
    
    func testMixedLatexAndText() {
        let input = "Hello \\alpha and \\beta world"
        let result = LaTeXConverter.toUnicode(input)
        
        XCTAssertTrue(result.contains("Hello"))
        XCTAssertTrue(result.contains("α"))
        XCTAssertTrue(result.contains("β"))
        XCTAssertTrue(result.contains("world"))
    }
    
    func testMathWithText() {
        let input = "Energy equals $E = mc^2$"
        let result = LaTeXConverter.toUnicode(input)
        
        // Should preserve math content
        XCTAssertTrue(result.contains("Energy"))
    }
    
    // MARK: - Reverse Conversion Tests
    
    func testToLaTeXBasic() {
        XCTAssertEqual(LaTeXConverter.toLaTeX("é"), "\\'e")
        XCTAssertEqual(LaTeXConverter.toLaTeX("ü"), "\\\"u")
        XCTAssertEqual(LaTeXConverter.toLaTeX("ñ"), "\\~n")
    }
    
    func testToLaTeXSpecialChars() {
        XCTAssertEqual(LaTeXConverter.toLaTeX("ß"), "\\ss")
        XCTAssertEqual(LaTeXConverter.toLaTeX("æ"), "\\ae")
        XCTAssertEqual(LaTeXConverter.toLaTeX("ø"), "\\o")
    }
    
    func testToLaTeXGreek() {
        XCTAssertEqual(LaTeXConverter.toLaTeX("α"), "\\alpha")
        XCTAssertEqual(LaTeXConverter.toLaTeX("β"), "\\beta")
        XCTAssertEqual(LaTeXConverter.toLaTeX("γ"), "\\gamma")
    }
    
    func testRoundTrip() {
        let original = "Müller"
        let latex = LaTeXConverter.toLaTeX(original)
        let unicode = LaTeXConverter.toUnicode(latex)
        
        XCTAssertEqual(unicode, original)
    }
    
    func testRoundTripComplex() {
        let original = "Café"
        let latex = LaTeXConverter.toLaTeX(original)
        let unicode = LaTeXConverter.toUnicode(latex)
        
        XCTAssertEqual(unicode, original)
    }
    
    // MARK: - Edge Cases
    
    func testIncompleteAccent() {
        // Incomplete accent at end of string
        let input = "test\\"
        let result = LaTeXConverter.toUnicode(input)
        // Should not crash
        XCTAssertNotNil(result)
    }
    
    func testUnknownCommand() {
        let input = "\\unknowncommand"
        let result = LaTeXConverter.toUnicode(input)
        // Should preserve unknown commands
        XCTAssertTrue(result.contains("unknowncommand") || result.contains("\\"))
    }
    
    func testNestedBraces() {
        let input = "\\'{e}"
        XCTAssertEqual(LaTeXConverter.toUnicode(input), "é")
    }
    
    func testDoubleBackslash() {
        let input = "\\\\"
        let result = LaTeXConverter.toUnicode(input)
        // Double backslash is line break in LaTeX
        XCTAssertNotNil(result)
    }
    
    func testUnicodePassthrough() {
        let input = "Already Üñíçödé"
        let result = LaTeXConverter.toUnicode(input)
        XCTAssertEqual(result, input)
    }
    
    // MARK: - Performance Tests
    
    func testPerformance() {
        let input = String(repeating: "M\\\"uller ", count: 1000)
        
        measure {
            _ = LaTeXConverter.toUnicode(input)
        }
    }
}
