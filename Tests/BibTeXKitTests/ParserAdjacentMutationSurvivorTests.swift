//
//  ParserAdjacentMutationSurvivorTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI
import Testing
@testable import BibTeXKit

@Suite("Given mutation-sensitive parser boundary contracts")
struct ParserAdjacentMutationSurvivorTests {

    @Test(
        "Given a one-digit candidate, when DOI operations scan its terminal boundary, then every operation rejects it safely"
    )
    func oneDigitDOICandidateIsRejectedSafely() {
        let source = "1"

        #expect(!DOIDetector.containsDOI(source))
        #expect(DOIDetector.extractDOI(from: source) == nil)
        #expect(!DOIDetector.isValidDOI(source))
    }

    @Test(
        "Given a DOI with two closing quotes, when its enclosing quote is removed, then the suffix quote is preserved"
    )
    func onlyOneEnclosingQuoteIsRemoved() {
        let source = "\"10.1/foo\"\""

        #expect(DOIDetector.extractDOI(from: source) == "10.1/foo\"")
    }

    @Test(
        "Given whitespace after a DOI URI prefix, when the DOI is extracted, then strict decoding and query termination still apply"
    )
    func spacedURIPrefixRetainsPresentationSemantics() {
        let source = "doi: 10.1/a%20b?tail"

        #expect(DOIDetector.extractDOI(from: source) == "10.1/a b")
    }

    @Test(
        "Given a letter before a DOI-like prefix, when the DOI is extracted, then the embedded prefix is not treated as a presentation"
    )
    func letterBeforePresentationPrefixKeepsRawSuffix() {
        let source = "xdoi:10.1/a%20b?tail"

        #expect(DOIDetector.extractDOI(from: source) == "10.1/a%20b?tail")
    }

    @Test(
        "Given a digit before a DOI-like prefix, when the DOI is extracted, then the embedded prefix is not treated as a presentation"
    )
    func digitBeforePresentationPrefixKeepsRawSuffix() {
        let source = "1doi:10.1/a%20b?tail"

        #expect(DOIDetector.extractDOI(from: source) == "10.1/a%20b?tail")
    }

    @Test(
        "Given an underscore before a DOI-like prefix, when the DOI is extracted, then the embedded prefix is not treated as a presentation"
    )
    func underscoreBeforePresentationPrefixKeepsRawSuffix() {
        let source = "_doi:10.1/a%20b?tail"

        #expect(DOIDetector.extractDOI(from: source) == "10.1/a%20b?tail")
    }

    @Test(
        "Given a terminal percent escape in a URI presentation, when DOI operations decode it, then every operation rejects it safely"
    )
    func terminalPercentEscapeIsRejectedSafely() {
        let source = "doi:10.1/a%"

        #expect(!DOIDetector.containsDOI(source))
        #expect(DOIDetector.extractDOI(from: source) == nil)
        #expect(DOIDetector.normalize(source) == nil)
        #expect(DOIDetector.doiURL(for: source) == nil)
    }

    @Test(
        "Given a dotless accent target followed by non-ASCII text, when converted, then the control-word boundary remains valid"
    )
    func nonASCIITextTerminatesDotlessControlWord() {
        let source = #"\'\ié"#

        #expect(LaTeXConverter.toUnicode(source) == "íé")
    }

    @Test(
        "Given an escaped control symbol before a letter, when converted to LaTeX, then no control-word delimiter is inserted"
    )
    func escapedControlSymbolUsesCanonicalSpelling() {
        #expect(LaTeXConverter.toLaTeX("&a") == #"\&a"#)
    }

    @Test(
        "Given a zero minimum height, when sanitized for rendering, then zero remains an explicit valid boundary"
    )
    func zeroMinimumHeightRemainsExplicit() {
        let configuration = BibTeXViewConfiguration(minHeight: 0)

        #expect(configuration.renderedMinimumHeight == .some(0))
    }

    @Test(
        "Given a zero maximum height, when sanitized for rendering, then zero remains an explicit valid boundary"
    )
    func zeroMaximumHeightRemainsExplicit() {
        let configuration = BibTeXViewConfiguration(maxHeight: 0)

        #expect(configuration.renderedMaximumHeight == .some(0))
    }
}
