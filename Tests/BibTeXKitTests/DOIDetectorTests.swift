//
//  DOIDetectorTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Testing

@testable import BibTeXKit

@Suite("Given text that may contain DOI identifiers")
struct DOIDetectorTests {

    // MARK: - Contains DOI Tests

    @Test("When checking bare DOI forms, then each supported identifier is detected")
    func containsDOIStandardFormat() {
        #expect(DOIDetector.containsDOI("10.1000/xyz123"))
        #expect(DOIDetector.containsDOI("10.1002/andp.19053221004"))
        #expect(DOIDetector.containsDOI("10.1038/nature12373"))
        #expect(DOIDetector.containsDOI("10.1/minimal-registrant"))
        #expect(DOIDetector.containsDOI("11/future-directory"))
        #expect(DOIDetector.containsDOI("11.123/future-registrant"))
    }

    @Test("When checking DOI and URN prefixes, then each identifier is detected")
    func containsDOIWithPrefix() {
        #expect(DOIDetector.containsDOI("doi:10.1000/xyz123"))
        #expect(DOIDetector.containsDOI("DOI:10.1000/xyz123"))
        #expect(DOIDetector.containsDOI("doi: 10.1000/xyz123"))
        #expect(DOIDetector.containsDOI("urn:doi:10.1/xyz123"))
        #expect(DOIDetector.containsDOI("URN:DOI: 11/xyz123"))
    }

    @Test("When checking DOI resolver URLs, then each identifier is detected")
    func containsDOIWithURL() {
        #expect(DOIDetector.containsDOI("https://doi.org/10.1000/xyz123"))
        #expect(DOIDetector.containsDOI("http://doi.org/10.1000/xyz123"))
        #expect(DOIDetector.containsDOI("https://dx.doi.org/10.1000/xyz123"))
        #expect(DOIDetector.containsDOI("doi.org/10.1000/xyz123"))
    }

    @Test("When checking prose containing a DOI, then the embedded identifier is detected")
    func containsDOIInSentence() {
        #expect(
            DOIDetector.containsDOI("See the paper at https://doi.org/10.1000/xyz123 for details."))
        #expect(DOIDetector.containsDOI("The DOI is 10.1002/andp.19053221004."))
    }

    @Test("When checking text without a DOI, then no identifier is detected")
    func containsDOINoDOI() {
        #expect(!(DOIDetector.containsDOI("No DOI here")))
        #expect(!(DOIDetector.containsDOI("10/1000/xyz")))
        #expect(!(DOIDetector.containsDOI("doi.org")))
        #expect(!(DOIDetector.containsDOI("")))
    }

    @Test("When checking DOI-like numeric tokens, then only token-boundary matches are detected")
    func containsDOIRejectsEmbeddedNumericTokens() {
        #expect(!(DOIDetector.containsDOI("x10.1000/xyz")))
        #expect(!(DOIDetector.containsDOI("é10.1000/xyz")))
        #expect(DOIDetector.containsDOI("(10.1000/xyz)"))
    }

    // MARK: - Extract DOI Tests

    @Test("When extracting a bare DOI, then the identifier is returned unchanged")
    func extractDOIStandard() {
        #expect(DOIDetector.extractDOI(from: "10.1000/xyz123") == "10.1000/xyz123")
        #expect(
            DOIDetector.extractDOI(from: "10.1002/andp.19053221004") == "10.1002/andp.19053221004")
    }

    @Test("When extracting a prefixed DOI, then its presentation prefix is removed")
    func extractDOIWithPrefix() {
        #expect(DOIDetector.extractDOI(from: "doi:10.1000/xyz123") == "10.1000/xyz123")
        #expect(DOIDetector.extractDOI(from: "DOI: 10.1000/xyz123") == "10.1000/xyz123")
        #expect(DOIDetector.extractDOI(from: "urn:doi:10.1/xyz123") == "10.1/xyz123")
        #expect(DOIDetector.extractDOI(from: "URN:DOI: 11/xyz123") == "11/xyz123")
    }

    @Test("When extracting a DOI resolver URL, then its resolver prefix is removed")
    func extractDOIWithURL() {
        #expect(DOIDetector.extractDOI(from: "https://doi.org/10.1000/xyz123") == "10.1000/xyz123")
        #expect(
            DOIDetector.extractDOI(from: "https://dx.doi.org/10.1000/xyz123") == "10.1000/xyz123")
    }

    @Test("When extracting a DOI from prose, then surrounding text and punctuation are removed")
    func extractDOIFromSentence() {
        #expect(
            DOIDetector.extractDOI(from: "The paper is available at doi:10.1000/xyz123.")
                == "10.1000/xyz123")
    }

    @Test("When extracting URL suffixes, then query and fragment delimiters are trimmed")
    func extractDOIStopsBeforeResolverURLQueryAndFragment() {
        #expect(
            DOIDetector.extractDOI(
                from: "https://DOI.org/10.1000/xyz123?utm_source=test#section"
            ) == "10.1000/xyz123")
        #expect(DOIDetector.extractDOI(from: "doi:10.1/xyz123?query#fragment") == "10.1/xyz123")
        #expect(DOIDetector.extractDOI(from: "urn:doi:11/xyz123#fragment") == "11/xyz123")
        #expect(
            DOIDetector.extractDOI(from: "10.1/xyz123?query#fragment")
                == "10.1/xyz123?query#fragment")
    }

    @Test("When extracting an encoded resolver URL, then DOI decoding preserves the URL")
    func extractDOIDecodesResolverURLPercentEncoding() {
        let url = "https://doi.org/10.1000/a%20b%2Fc%23d"
        #expect(DOIDetector.extractDOI(from: url) == "10.1000/a b/c#d")
        #expect(DOIDetector.normalize(url) == "10.1000/a b/c#d")
        #expect(DOIDetector.doiURL(for: url)?.absoluteString == url)
    }

    @Test("When extracting encoded URI presentations, then valid percent escapes are decoded")
    func extractDOIStrictlyDecodesURIPresentations() {
        #expect(DOIDetector.extractDOI(from: "DOI:10.1/a%20b%2Fc%23d") == "10.1/a b/c#d")
        #expect(DOIDetector.extractDOI(from: "urn:doi:11/a%25b") == "11/a%b")
    }

    @Test("When extracting malformed URI presentations, then every DOI operation rejects them")
    func extractDOIRejectsMalformedPresentationEscapesAndUTF8() {
        let malformed = [
            "doi:10.1/a%",
            "doi:10.1/a%2",
            "doi:10.1/a%GG",
            "urn:doi:10.1/a%E2%28",
            "https://doi.org/10.1/a%FF",
        ]

        for value in malformed {
            #expect(!(DOIDetector.containsDOI(value)), "Input: \(value)")
            #expect(DOIDetector.extractDOI(from: value) == nil, "Input: \(value)")
            #expect(DOIDetector.normalize(value) == nil, "Input: \(value)")
            #expect(DOIDetector.doiURL(for: value) == nil, "Input: \(value)")
        }
    }

    @Test("When extracting plain percent text, then the DOI is preserved and its URL is encoded")
    func extractDOIPreservesPercentInPlainNames() {
        let doi = "10.1/a%GG"
        #expect(DOIDetector.isValidDOI(doi))
        #expect(DOIDetector.extractDOI(from: doi) == doi)
        #expect(DOIDetector.normalize(doi) == doi)
        #expect(DOIDetector.doiURL(for: doi)?.absoluteString == "https://doi.org/10.1/a%25GG")
    }

    @Test("When extracting from text without a DOI, then no identifier is returned")
    func extractDOINoDOI() {
        #expect(DOIDetector.extractDOI(from: "No DOI here") == nil)
        #expect(DOIDetector.extractDOI(from: "") == nil)
    }

    // MARK: - Extract All DOIs Tests

    @Test("When extracting multiple DOI presentations, then every identifier is returned")
    func extractAllDOIsMultiple() {
        let text = """
            Reference 1: 10.1000/abc123
            Reference 2: https://doi.org/10.2000/def456
            Reference 3: doi:10.3000/ghi789
            """

        let dois = DOIDetector.extractAllDOIs(from: text)
        #expect(dois.count == 3)
        #expect(dois.contains("10.1000/abc123"))
        #expect(dois.contains("10.2000/def456"))
        #expect(dois.contains("10.3000/ghi789"))
    }

    @Test("When extracting adjacent DOI presentations, then each identifier is split correctly")
    func extractAllDOIsAdjacentWithoutWhitespace() {
        #expect(
            DOIDetector.extractAllDOIs(
                from: "10.1/one,10.2/two;11/three"
            ) == ["10.1/one", "10.2/two", "11/three"])
        #expect(
            DOIDetector.extractAllDOIs(
                from: "doi:10.1/one;URN:DOI:11/two,https://doi.org/10.3/three"
            ) == ["10.1/one", "11/two", "10.3/three"])
    }

    @Test("When extracting all identifiers from DOI-free text, then the result is empty")
    func extractAllDOIsNoDOIs() {
        let dois = DOIDetector.extractAllDOIs(from: "No DOIs here")
        #expect(dois.isEmpty)
    }

    @Test("When extracting repeated DOI presentations, then duplicates retain source order")
    func extractAllDOIsPreservesDuplicateSourceOrder() {
        let text = """
            doi:10.1/repeated; 10.2/middle;
            https://doi.org/10.1/repeated
            """

        #expect(
            DOIDetector.extractAllDOIs(from: text) == [
                "10.1/repeated", "10.2/middle", "10.1/repeated",
            ])
    }

    @Test("Given one thousand resolver URLs, when extracting all, then source order is retained")
    func extractAllSimpleResolverURLsAtScale() {
        let expected = (0..<1_000).map { "10.1000/item\($0)" }
        let text = expected
            .map { "https://doi.org/\($0)" }
            .joined(separator: " ")

        #expect(DOIDetector.extractAllDOIs(from: text) == expected)
    }

    @Test("When extracting mixed adjacent candidates, then only valid DOIs are returned")
    func extractAllDOIsSkipsInvalidAdjacentCandidates() {
        let text = "10./broken;10/missing | 10.1/one,doi:10.2/two;11/three"

        #expect(DOIDetector.extractAllDOIs(from: text) == ["10.1/one", "10.2/two", "11/three"])
    }

    @Test(
        "When a candidate suffix is only removable punctuation, then it is rejected and scanning advances"
    )
    func punctuationOnlySuffixIsRejectedWithoutBlockingLaterCandidates() {
        let text = "11/.... 10.1/valid"

        #expect(DOIDetector.extractDOI(from: "11/....") == nil)
        #expect(DOIDetector.extractAllDOIs(from: text) == ["10.1/valid"])
    }

    @Test("When tasks extract shared DOI text concurrently, then results remain deterministic")
    func concurrentExtractionIsDeterministic() async {
        let text = "doi:10.1/one;https://doi.org/10.2/two;11/three"
        let expected = ["10.1/one", "10.2/two", "11/three"]

        let results = await withTaskGroup(
            of: [String].self,
            returning: [[String]].self
        ) { group in
            for _ in 0..<16 {
                group.addTask {
                    DOIDetector.extractAllDOIs(from: text)
                }
            }

            var extracted: [[String]] = []
            extracted.reserveCapacity(16)
            for await dois in group {
                extracted.append(dois)
            }
            return extracted
        }

        #expect(results.count == 16)
        for dois in results {
            #expect(dois == expected)
        }
    }

    // MARK: - Validate DOI Tests

    @Test("When validating supported DOI forms, then each identifier is accepted")
    func isValidDOIValid() {
        #expect(DOIDetector.isValidDOI("10.1000/xyz123"))
        #expect(DOIDetector.isValidDOI("10.1002/andp.19053221004"))
        #expect(DOIDetector.isValidDOI("10.1038/nature12373"))
        #expect(DOIDetector.isValidDOI("10.1234/5678"))
        #expect(DOIDetector.isValidDOI("10.1/short"))
        #expect(DOIDetector.isValidDOI("10.123/short"))
        #expect(DOIDetector.isValidDOI("10.1.2/delegated"))
        #expect(DOIDetector.isValidDOI("11/no-registrant"))
        #expect(DOIDetector.isValidDOI("11.123/registrant"))
        #expect(DOIDetector.isValidDOI("123456789/future"))
    }

    @Test("When validating presentations and malformed DOI forms, then each value is rejected")
    func isValidDOIInvalid() {
        #expect(!(DOIDetector.isValidDOI("doi:10.1000/xyz123")))  // Has prefix
        #expect(!(DOIDetector.isValidDOI("https://doi.org/10.1000/xyz123")))  // Is URL
        #expect(!(DOIDetector.isValidDOI("10/xyz")))  // Directory 10 requires a registrant
        #expect(!(DOIDetector.isValidDOI("１０.1000/xyz")))  // Non-ASCII directory digits
        #expect(!(DOIDetector.isValidDOI("10.1000")))  // Missing suffix
        #expect(!(DOIDetector.isValidDOI("")))
    }

    @Test("When validating malformed segments and non-graphic input, then each value is rejected")
    func isValidDOIRejectsMalformedSegmentsAndNonGraphicInput() {
        #expect(!(DOIDetector.isValidDOI("10.1000./xyz")))
        #expect(!(DOIDetector.isValidDOI("10.1000.2./xyz")))
        #expect(!(DOIDetector.isValidDOI("11./xyz")))
        #expect(!(DOIDetector.isValidDOI("11.2./xyz")))
        #expect(!(DOIDetector.isValidDOI("10.1000/")))
        #expect(!(DOIDetector.isValidDOI("11/")))
        #expect(!(DOIDetector.isValidDOI("10.1000/a\u{0000}b")))
    }

    @Test("When validating Unicode and graphic DOI suffixes, then each value is accepted")
    func isValidDOIAcceptsUnicodeAndGraphicSuffixes() {
        #expect(DOIDetector.isValidDOI("10.1000/日本語"))
        #expect(DOIDetector.isValidDOI("10.1000/a/b#c?d,e"))
        #expect(DOIDetector.isValidDOI("10.1000/O'Connor"))
        #expect(DOIDetector.isValidDOI("10.1000/a b"))

        let nestedPunctuation = "10.1000/α[(β,{γ})] <δ>"
        #expect(DOIDetector.isValidDOI(nestedPunctuation))
        #expect(DOIDetector.normalize(nestedPunctuation) == nestedPunctuation)
    }

    @Test("When validating a very long DOI, then it remains valid and normalizes unchanged")
    func doiSyntaxDoesNotImposeAnArtificialLengthLimit() {
        let doi = "10.1000/" + String(repeating: "a", count: 100_000)
        #expect(DOIDetector.isValidDOI(doi))
        #expect(DOIDetector.normalize(doi) == doi)
    }

    // MARK: - DOI URL Tests

    @Test("When creating a URL from a valid DOI, then a canonical resolver URL is returned")
    func doiURLValid() {
        let url = DOIDetector.doiURL(for: "10.1000/xyz123")
        #expect(url != nil)
        #expect(url?.absoluteString == "https://doi.org/10.1000/xyz123")
    }

    @Test("When creating a URL from a resolver URL, then the canonical URL is preserved")
    func doiURLFromFullURL() {
        let url = DOIDetector.doiURL(for: "https://doi.org/10.1000/xyz123")
        #expect(url != nil)
        #expect(url?.absoluteString == "https://doi.org/10.1000/xyz123")
    }

    @Test("When creating a URL from invalid DOI text, then no URL is returned")
    func doiURLInvalid() {
        #expect(DOIDetector.doiURL(for: "invalid") == nil)
        #expect(DOIDetector.doiURL(for: "") == nil)
    }

    @Test("When creating URLs for special suffixes, then each component is percent-encoded")
    func doiURLPercentEncodesEachDOIComponent() {
        #expect(
            DOIDetector.doiURL(for: "10.1000/a/b#c?d,e")?.absoluteString
                == "https://doi.org/10.1000/a%2Fb%23c%3Fd%2Ce")
        #expect(
            DOIDetector.doiURL(for: "10.1000/日本語")?.absoluteString
                == "https://doi.org/10.1000/%E6%97%A5%E6%9C%AC%E8%AA%9E")
        #expect(
            DOIDetector.doiURL(for: "10.1000/a b")?.absoluteString
                == "https://doi.org/10.1000/a%20b")
    }

    @Test("When creating a URL for a graphic suffix, then normalization and encoding preserve it")
    func doiURLDoesNotTruncateAValidGraphicSuffix() {
        let doi = "10.1000/O'Connor,2026"
        #expect(DOIDetector.normalize(doi) == doi)
        #expect(
            DOIDetector.doiURL(for: doi)?.absoluteString
                == "https://doi.org/10.1000/O'Connor%2C2026")
    }

    @Test("When creating a URL from an encoded presentation, then escapes are not double-encoded")
    func doiURLNormalizesEncodedPresentationWithoutDoubleEncoding() {
        #expect(
            DOIDetector.doiURL(
                for: "URN:DOI:10.1/a%25b%2Fc"
            )?.absoluteString == "https://doi.org/10.1/a%25b%2Fc")
    }

    // MARK: - Normalize Tests

    @Test("When normalizing a bare DOI, then the identifier is returned unchanged")
    func normalizeStandard() {
        #expect(DOIDetector.normalize("10.1000/xyz123") == "10.1000/xyz123")
    }

    @Test("When normalizing prefixed DOI forms, then presentation prefixes are removed")
    func normalizeWithPrefix() {
        #expect(DOIDetector.normalize("doi:10.1000/xyz123") == "10.1000/xyz123")
        #expect(DOIDetector.normalize("DOI: 10.1000/xyz123") == "10.1000/xyz123")
    }

    @Test("When normalizing resolver URLs, then resolver prefixes are removed")
    func normalizeWithURL() {
        #expect(DOIDetector.normalize("https://doi.org/10.1000/xyz123") == "10.1000/xyz123")
        #expect(DOIDetector.normalize("https://dx.doi.org/10.1000/xyz123") == "10.1000/xyz123")
    }

    @Test("When normalizing invalid DOI text, then no identifier is returned")
    func normalizeInvalid() {
        #expect(DOIDetector.normalize("invalid") == nil)
        #expect(DOIDetector.normalize("") == nil)
    }

    // MARK: - Complex DOI Formats

    @Test("When handling complex DOI suffixes, then segments and special characters are preserved")
    func complexDOIs() {
        // DOI with multiple segments
        #expect(DOIDetector.isValidDOI("10.1000.10/xyz123"))

        // DOI with special characters in suffix
        #expect(DOIDetector.extractDOI(from: "10.1000/test-value_123") == "10.1000/test-value_123")

        // DOI with parentheses (common in some publishers)
        #expect(DOIDetector.extractDOI(from: "10.1000/test(2024)123") == "10.1000/test(2024)123")
    }

    @Test("When extracting graphic punctuation, then internal DOI punctuation is preserved")
    func extractionPreservesInternalGraphicPunctuation() {
        let doi = "10.1/a[b],c{d}\"e'O"
        #expect(DOIDetector.extractDOI(from: doi) == doi)
        #expect(DOIDetector.extractDOI(from: "The DOI is \(doi).") == doi)
        #expect(DOIDetector.extractDOI(from: "10.1/(a)[b]{c}<d>") == "10.1/(a)[b]{c}<d>")
        #expect(DOIDetector.extractDOI(from: "10.1/\"quoted\"") == "10.1/\"quoted\"")
    }

    @Test("When extracting ASCII and Unicode wrapped presentations, then each wrapper is trimmed")
    func extractionTrimsASCIIAndUnicodePresentationWrappers() {
        let presentations = [
            "\"doi:10.1/value\"",
            "'urn:doi:10.1/value'",
            "(10.1/value)",
            "[10.1/value]",
            "{10.1/value}",
            "<https://doi.org/10.1/value>",
            "“DOI:10.1/value”",
            "‘10.1/value’",
            "„10.1/value“",
            "‚10.1/value‘",
            "«10.1/value»",
            "「10.1/value」",
            "【10.1/value】",
            "（10.1/value）",
            "＂10.1/value＂",
            "＇10.1/value＇",
        ]

        for presentation in presentations {
            #expect(
                DOIDetector.extractDOI(from: presentation) == "10.1/value",
                "Presentation: \(presentation)"
            )
        }
    }

    @Test("When extracting trailing wrappers, then unmatched closers alone are trimmed")
    func extractionTrimsOnlyUnmatchedTrailingWrappers() {
        #expect(DOIDetector.extractDOI(from: "10.1/value)]}") == "10.1/value")
        #expect(DOIDetector.extractDOI(from: "(10.1/value(a)[b]{c})") == "10.1/value(a)[b]{c}")
    }

    @Test("When extracting sentence-final DOI presentations, then trailing punctuation is removed")
    func trailingPunctuationRemoval() {
        for punctuation in [".", ",", ";", ":"] {
            #expect(
                DOIDetector.extractDOI(
                    from: "See 10.1000/xyz123\(punctuation)"
                ) == "10.1000/xyz123",
                "Punctuation: \(punctuation)"
            )
        }
        #expect(DOIDetector.extractDOI(from: "(10.1000/xyz123)") == "10.1000/xyz123")
    }

    @Test("When extracting parenthesized suffixes, then balanced DOI parentheses are preserved")
    func trailingPunctuationRemovalPreservesBalancedDOIParentheses() {
        #expect(DOIDetector.extractDOI(from: "(10.1000/test(2024)123).") == "10.1000/test(2024)123")
    }

    @Test("When extracting many trailing delimiters, then the DOI returns without crashing")
    func hostileTrailingDelimitersRemainLinearAndDoNotCrash() {
        let text = "10.1000/xyz" + String(repeating: ")", count: 20_000)
        #expect(DOIDetector.extractDOI(from: text) == "10.1000/xyz")
    }

    @Test("When checking a hostile numeric prefix, then no DOI is detected without crashing")
    func hostileNumericPrefixRemainsLinearAndDoesNotCrash() {
        let text = String(repeating: "1.", count: 50_000) + "x"
        #expect(!(DOIDetector.containsDOI(text)))
    }

    @Test("When decoding many strict percent escapes, then every escape is converted correctly")
    func hostileStrictPercentDecodingRemainsLinear() {
        let presentation = "doi:10.1/" + String(repeating: "%41", count: 50_000)
        let expected = "10.1/" + String(repeating: "A", count: 50_000)
        #expect(DOIDetector.extractDOI(from: presentation) == expected)
    }

    // MARK: - BibTeXEntry Extension Tests

    @Test("When a BibTeX entry contains a valid DOI, then its canonical resolver URL is available")
    func bibTeXEntryDOIURL() throws {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["doi": "10.1000/xyz123"]
        )

        #expect(entry.doiURL != nil)
        #expect(entry.doiURL?.absoluteString == "https://doi.org/10.1000/xyz123")
    }

    @Test("When BibTeX entries vary in DOI content, then validity reflects each stored value")
    func bibTeXEntryHasValidDOI() {
        let validEntry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["doi": "10.1000/xyz123"]
        )
        #expect(validEntry.hasValidDOI)

        let invalidEntry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["doi": "invalid"]
        )
        #expect(!(invalidEntry.hasValidDOI))

        let noDOIEntry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: [:]
        )
        #expect(!(noDOIEntry.hasValidDOI))
    }

    @Test("When a BibTeX entry stores a resolver URL, then its normalized DOI omits the prefix")
    func bibTeXEntryNormalizedDOI() {
        let entry = BibTeXEntry(
            type: .article,
            citationKey: "test",
            fields: ["doi": "https://doi.org/10.1000/xyz123"]
        )

        #expect(entry.normalizedDOI == "10.1000/xyz123")
    }

    // MARK: - Real-World DOI Examples

    @Test("When validating real-world publisher DOIs, then every identifier is accepted")
    func realWorldDOIs() {
        // Nature
        #expect(DOIDetector.isValidDOI("10.1038/nature12373"))

        // IEEE
        #expect(DOIDetector.isValidDOI("10.1109/5.771073"))

        // Springer
        #expect(DOIDetector.isValidDOI("10.1007/s00422-012-0512-2"))

        // Elsevier
        #expect(DOIDetector.isValidDOI("10.1016/j.artint.2010.04.024"))

        // ACM
        #expect(DOIDetector.isValidDOI("10.1145/3287324.3287489"))

        // Wiley (Einstein's paper)
        #expect(DOIDetector.isValidDOI("10.1002/andp.19053221004"))
    }
}
