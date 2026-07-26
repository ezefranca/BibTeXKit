//
//  DOIDetector.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// A utility for detecting and extracting DOIs (Digital Object Identifiers).
///
/// Detection accepts plain DOI names as well as `doi:`, `urn:doi:`, and DOI
/// resolver URL presentations.
///
/// ## Usage
///
/// ```swift
/// DOIDetector.containsDOI("See https://doi.org/10.1000/xyz123")
/// DOIDetector.extractDOI(from: "Paper at doi:10.1000/xyz123")
/// DOIDetector.extractAllDOIs(from: text)
/// DOIDetector.isValidDOI("10.1000/xyz123")
/// DOIDetector.doiURL(for: "10.1000/xyz123")
/// ```
///
/// The detector performs a bounded, linear scan and keeps no mutable shared
/// state.
public struct DOIDetector: Sendable {

    private static let resolverPresentationPrefixes = [
        "https://dx.doi.org/",
        "http://dx.doi.org/",
        "https://doi.org/",
        "http://doi.org/",
        "//dx.doi.org/",
        "//doi.org/",
        "dx.doi.org/",
        "doi.org/",
    ]

    private static let uriPresentationPrefixes = ["urn:doi:", "doi:"]

    // MARK: - Public Methods

    /// Checks whether the given string contains a DOI.
    public static func containsDOI(_ text: String) -> Bool {
        firstMatch(in: text, from: text.startIndex) != nil
    }

    /// Extracts the first DOI name without a presentation prefix.
    ///
    /// Sentence punctuation and unmatched enclosing delimiters are omitted.
    /// Percent escapes in URI and resolver URL presentations are decoded
    /// strictly. A malformed escape or invalid UTF-8 sequence is rejected.
    public static func extractDOI(from text: String) -> String? {
        guard let match = firstMatch(in: text, from: text.startIndex) else {
            return nil
        }
        return match.canonicalDOI
    }

    /// Extracts all DOI names, in source order, without presentation prefixes.
    public static func extractAllDOIs(from text: String) -> [String] {
        var result: [String] = []
        var searchStart = text.startIndex

        while let match = firstMatch(in: text, from: searchStart) {
            result.append(match.canonicalDOI)
            searchStart = match.resumeIndex
        }

        return result
    }

    /// Validates the format of a canonical DOI name.
    ///
    /// This is a syntax check only; it does not query a registration agency.
    /// A DOI prefix contains an ASCII-numeric directory indicator followed by
    /// an optional, dot-separated ASCII-numeric registrant code. The registrant
    /// code is required for directory indicator `10`.
    public static func isValidDOI(_ doi: String) -> Bool {
        validatedCanonicalDOI(doi) != nil
    }

    /// Creates an HTTPS DOI resolver URL.
    ///
    /// DOI prefix and suffix components are UTF-8 percent-encoded according to
    /// the DOI Handbook. A slash inside the suffix is therefore encoded as
    /// `%2F`, while the prefix/suffix separator remains `/`.
    public static func doiURL(for doi: String) -> URL? {
        let validated: ValidatedDOI
        if let canonical = validatedCanonicalDOI(doi) {
            validated = canonical
        } else if let extracted = extractDOI(from: doi),
                  let canonical = validatedCanonicalDOI(extracted) {
            validated = canonical
        } else {
            return nil
        }

        let encoded = percentEncode(validated.prefix)
            + "/"
            + percentEncode(validated.suffix)
        return URL(string: "https://doi.org/\(encoded)")
    }

    /// Normalizes a DOI presentation to a DOI name without its presentation
    /// prefix.
    public static func normalize(_ doi: String) -> String? {
        if let validated = validatedCanonicalDOI(doi) {
            return validated.canonical
        }

        guard let extracted = extractDOI(from: doi),
              let validated = validatedCanonicalDOI(extracted) else {
            return nil
        }
        return validated.canonical
    }

    // MARK: - Linear Scanner

    private struct Match {
        let canonicalDOI: String
        /// The untrimmed candidate end. Advancing here guarantees progress even
        /// when all captured suffix punctuation is discarded.
        let resumeIndex: String.Index
    }

    private enum PrefixParse {
        case match(separator: String.Index, suffixStart: String.Index)
        case noMatch(resumeAt: String.Index)
    }

    private struct ValidatedDOI {
        let canonical: String
        let prefix: Substring
        let suffix: Substring
    }

    private enum PresentationKind {
        case plain
        case uri
        case resolverURL

        var requiresStrictPercentDecoding: Bool {
            self != .plain
        }

        var terminatesAtQueryOrFragment: Bool {
            self != .plain
        }
    }

    private struct Presentation {
        let kind: PresentationKind
        let start: String.Index
    }

    private enum CandidateCleanupMode {
        case passthrough
        case full
    }

    private static func firstMatch(
        in text: String,
        from searchStart: String.Index
    ) -> Match? {
        var candidateStart = searchStart

        while candidateStart != text.endIndex {
            let nextCandidateStart = text.index(after: candidateStart)

            guard isASCIIDigit(text[candidateStart]) else {
                candidateStart = nextCandidateStart
                continue
            }

            let boundary = leadingBoundary(in: text, at: candidateStart)
            guard boundary.isValid else {
                candidateStart = nextCandidateStart
                continue
            }

            switch parsePrefix(in: text, at: candidateStart) {
            case .match(_, let suffixStart):
                let presentation =
                    boundary.presentation
                    ?? presentation(in: text, endingAt: candidateStart)
                var rawEnd = suffixStart

                while rawEnd != text.endIndex {
                    if isExtractionTerminator(
                        text[rawEnd],
                        presentation: presentation.kind
                    ) || adjacentDOIStart(in: text, at: rawEnd) != nil {
                        break
                    }
                    text.formIndex(after: &rawEnd)
                }

                let cleanedEnd = cleanedCandidateEnd(
                    in: text,
                    presentationStart: presentation.start,
                    suffixStart: suffixStart,
                    rawEnd: rawEnd
                )

                if cleanedEnd != suffixStart {
                    let captured = String(text[candidateStart..<cleanedEnd])

                    if presentation.kind.requiresStrictPercentDecoding,
                       captured.utf8.contains(37) {
                        if let canonical = percentDecodeStrictly(captured),
                           isValidDOI(canonical) {
                            return Match(
                                canonicalDOI: canonical,
                                resumeIndex: rawEnd
                            )
                        }
                    } else {
                        return Match(
                            canonicalDOI: captured,
                            resumeIndex: rawEnd
                        )
                    }
                }

                // Do not reinterpret the middle of a rejected presentation.
                // The explicit floor also guarantees progress if a future
                // parser change returns the current position.
                candidateStart = max(rawEnd, nextCandidateStart)

            case .noMatch(let resumeAt):
                candidateStart = max(resumeAt, nextCandidateStart)
            }
        }

        return nil
    }

    /// Parses `<directory>[.<registrant>[.<registrant>...]]/` without
    /// allocating substrings. Failure includes the furthest safe resumption
    /// point so hostile numeric input is scanned in linear time.
    private static func parsePrefix(
        in text: String,
        at start: String.Index
    ) -> PrefixParse {
        var index = start

        guard index != text.endIndex, isASCIIDigit(text[index]) else {
            return .noMatch(resumeAt: index)
        }

        let directoryStart = index
        while index != text.endIndex, isASCIIDigit(text[index]) {
            text.formIndex(after: &index)
        }
        let directoryEnd = index
        var hasRegistrantCode = false

        if index != text.endIndex, text[index] == "." {
            repeat {
                text.formIndex(after: &index)
                let segmentStart = index

                while index != text.endIndex, isASCIIDigit(text[index]) {
                    text.formIndex(after: &index)
                }

                guard index != segmentStart else {
                    return .noMatch(resumeAt: index)
                }
                hasRegistrantCode = true
            } while index != text.endIndex && text[index] == "."
        }

        if isDirectoryTen(
            in: text,
            from: directoryStart,
            to: directoryEnd
        ), !hasRegistrantCode {
            return .noMatch(resumeAt: index)
        }

        guard index != text.endIndex, text[index] == "/" else {
            return .noMatch(resumeAt: index)
        }

        let separator = index
        text.formIndex(after: &index)
        return .match(separator: separator, suffixStart: index)
    }

    private static func validatedCanonicalDOI(_ doi: String) -> ValidatedDOI? {
        guard case .match(let separator, let suffixStart) = parsePrefix(
            in: doi,
            at: doi.startIndex
        ), suffixStart != doi.endIndex else {
            return nil
        }

        for character in doi[suffixStart...] where !isDOIGraphic(character) {
            return nil
        }

        return ValidatedDOI(
            canonical: doi,
            prefix: doi[..<separator],
            suffix: doi[suffixStart...]
        )
    }

    private static func isDirectoryTen(
        in text: String,
        from start: String.Index,
        to end: String.Index
    ) -> Bool {
        text[start..<end] == "10"
    }

    private static func leadingBoundary(
        in text: String,
        at start: String.Index
    ) -> (isValid: Bool, presentation: Presentation?) {
        guard start != text.startIndex else {
            return (isValid: true, presentation: nil)
        }
        let previous = text[text.index(before: start)]

        if previous == "/" {
            let presentation = presentation(in: text, endingAt: start)
            return (
                isValid: presentation.kind == .resolverURL,
                presentation: presentation
            )
        }

        return (
            isValid: !previous.isLetter
                && !previous.isNumber
                && previous != ".",
            presentation: nil
        )
    }

    private static func isExtractionTerminator(
        _ character: Character,
        presentation: PresentationKind
    ) -> Bool {
        if character.isWhitespace || !isDOIGraphic(character) {
            return true
        }

        return presentation.terminatesAtQueryOrFragment
            && (character == "?" || character == "#")
    }

    /// A comma or semicolon is part of a valid DOI suffix in isolation. During
    /// prose extraction it is treated as a separator only when another DOI
    /// name or recognized presentation begins immediately after it.
    private static func adjacentDOIStart(
        in text: String,
        at separator: String.Index
    ) -> String.Index? {
        guard text[separator] == "," || text[separator] == ";" else {
            return nil
        }

        let next = text.index(after: separator)
        guard next != text.endIndex else { return nil }

        if isASCIIDigit(text[next]),
           case .match = parsePrefix(in: text, at: next) {
            return next
        }

        if beginsPresentedDOI(
            in: text,
            at: next,
            prefixes: uriPresentationPrefixes
        ) || beginsPresentedDOI(
            in: text,
            at: next,
            prefixes: resolverPresentationPrefixes
        ) {
            return next
        }

        return nil
    }

    private static func beginsPresentedDOI(
        in text: String,
        at presentationStart: String.Index,
        prefixes: [String]
    ) -> Bool {
        for prefix in prefixes {
            if let doiStart = endOfASCIIPrefix(
                prefix,
                in: text,
                startingAt: presentationStart
            ), case .match = parsePrefix(in: text, at: doiStart) {
                return true
            }
        }

        return false
    }

    /// Removes likely prose punctuation and unmatched trailing wrappers using
    /// one delimiter pass. Balanced punctuation inside the DOI is preserved.
    private static func cleanedCandidateEnd(
        in text: String,
        presentationStart: String.Index,
        suffixStart: String.Index,
        rawEnd: String.Index
    ) -> String.Index {
        switch candidateCleanupMode(
            in: text,
            suffixStart: suffixStart,
            rawEnd: rawEnd
        ) {
        case .passthrough:
            return rawEnd
        case .full:
            break
        }

        var expectedClosers: [Character] = []
        var unmatchedClosings: [String.Index] = []
        var index = suffixStart

        while index != rawEnd {
            let character = text[index]

            if expectedClosers.last == character {
                expectedClosers.removeLast()
            } else if let closer = expectedClosingWrapper(for: character) {
                expectedClosers.append(closer)
            } else if isClosingWrapper(character) {
                unmatchedClosings.append(index)
            }

            text.formIndex(after: &index)
        }

        let enclosingQuote = enclosingQuoteCloser(
            before: presentationStart,
            in: text
        )
        var removedEnclosingQuote = false
        var end = rawEnd

        while end != suffixStart {
            let previous = text.index(before: end)
            let character = text[previous]

            switch character {
            case ".", ",", ";", ":":
                end = previous

            case _ where unmatchedClosings.last == previous:
                unmatchedClosings.removeLast()
                end = previous

            case _ where !removedEnclosingQuote && character == enclosingQuote:
                removedEnclosingQuote = true
                end = previous

            default:
                return end
            }
        }

        return end
    }

    /// ASCII candidates without punctuation that can be trimmed or balanced do
    /// not need the more expensive grapheme-aware wrapper pass. Any Unicode
    /// byte conservatively selects the full path.
    private static func candidateCleanupMode(
        in text: String,
        suffixStart: String.Index,
        rawEnd: String.Index
    ) -> CandidateCleanupMode {
        for byte in text[suffixStart..<rawEnd].utf8 {
            switch byte & 0x80 {
            case 0:
                break
            default:
                return .full
            }

            switch byte {
            case 34, 39, 40, 41, 44, 46, 58, 59,
                 60, 62, 91, 93, 123, 125:
                return .full
            default:
                continue
            }
        }

        return .passthrough
    }

    private static func expectedClosingWrapper(
        for character: Character
    ) -> Character? {
        switch character {
        case "(": ")"
        case "[": "]"
        case "{": "}"
        case "<": ">"
        case "“": "”"
        case "‘": "’"
        case "„": "“"
        case "‚": "‘"
        case "«": "»"
        case "‹": "›"
        case "「": "」"
        case "『": "』"
        case "【": "】"
        case "〈": "〉"
        case "《": "》"
        case "〔": "〕"
        case "〖": "〗"
        case "〘": "〙"
        case "〚": "〛"
        case "（": "）"
        case "［": "］"
        case "｛": "｝"
        case "＜": "＞"
        case "〝": "〞"
        default: nil
        }
    }

    private static func isClosingWrapper(_ character: Character) -> Bool {
        switch character {
        case ")", "]", "}", ">", "”", "’", "»", "›", "」", "』", "】",
             "〉", "》", "〕", "〗", "〙", "〛", "）", "］", "｝", "＞",
             "〞":
            true
        default:
            false
        }
    }

    private static func enclosingQuoteCloser(
        before start: String.Index,
        in text: String
    ) -> Character? {
        var index = start

        while index > text.startIndex {
            let previous = text.index(before: index)
            let character = text[previous]

            if character.isWhitespace {
                index = previous
                continue
            }

            return quoteCloser(for: character)
        }

        return nil
    }

    private static func quoteCloser(for character: Character) -> Character? {
        switch character {
        case "\"": "\""
        case "'": "'"
        case "＂": "＂"
        case "＇": "＇"
        case "“": "”"
        case "‘": "’"
        case "„": "“"
        case "‚": "‘"
        case "«": "»"
        case "‹": "›"
        case "〝": "〞"
        default: nil
        }
    }

    // MARK: - Presentation Prefixes

    private static func presentation(
        in text: String,
        endingAt doiStart: String.Index
    ) -> Presentation {
        for prefix in resolverPresentationPrefixes {
            if let start = startOfASCIIPrefix(
                prefix,
                in: text,
                endingAt: doiStart
            ), hasPresentationBoundary(in: text, before: start) {
                return Presentation(kind: .resolverURL, start: start)
            }
        }

        var prefixEnd = doiStart
        while prefixEnd != text.startIndex {
            let previous = text.index(before: prefixEnd)
            guard text[previous].isWhitespace else { break }
            prefixEnd = previous
        }

        for prefix in uriPresentationPrefixes {
            if let start = startOfASCIIPrefix(
                prefix,
                in: text,
                endingAt: prefixEnd
            ), hasPresentationBoundary(in: text, before: start) {
                return Presentation(kind: .uri, start: start)
            }
        }

        return Presentation(kind: .plain, start: doiStart)
    }

    private static func startOfASCIIPrefix(
        _ prefix: String,
        in text: String,
        endingAt end: String.Index
    ) -> String.Index? {
        var index = end

        for expected in prefix.reversed() {
            guard index > text.startIndex else { return nil }
            text.formIndex(before: &index)
            guard let actualByte = text[index].asciiValue,
                  let expectedByte = expected.asciiValue else {
                return nil
            }
            let lowercaseByte = (65...90).contains(actualByte)
                ? actualByte + 32
                : actualByte
            guard lowercaseByte == expectedByte else { return nil }
        }

        return index
    }

    private static func endOfASCIIPrefix(
        _ prefix: String,
        in text: String,
        startingAt start: String.Index
    ) -> String.Index? {
        var index = start

        for expected in prefix {
            guard index != text.endIndex,
                  let actualByte = text[index].asciiValue,
                  let expectedByte = expected.asciiValue else {
                return nil
            }
            let lowercaseByte = (65...90).contains(actualByte)
                ? actualByte + 32
                : actualByte
            guard lowercaseByte == expectedByte else { return nil }
            text.formIndex(after: &index)
        }

        return index
    }

    private static func hasPresentationBoundary(
        in text: String,
        before start: String.Index
    ) -> Bool {
        guard start != text.startIndex else { return true }
        let previous = text[text.index(before: start)]
        return !previous.isLetter && !previous.isNumber && previous != "_"
    }

    // MARK: - DOI Syntax and Encoding

    private static func isASCIIDigit(_ character: Character) -> Bool {
        guard let byte = character.asciiValue else { return false }
        return (48...57).contains(byte)
    }

    private static func isASCIIAlphaNumeric(_ byte: UInt8) -> Bool {
        (48...57).contains(byte)
            || (65...90).contains(byte)
            || (97...122).contains(byte)
    }

    /// DOI names consist of Unicode Graphic code points. Space separators are
    /// valid in a canonical DOI even though the prose extractor necessarily
    /// treats whitespace as a candidate boundary.
    private static func isDOIGraphic(_ character: Character) -> Bool {
        for scalar in character.unicodeScalars {
            switch scalar.properties.generalCategory {
            case .control, .format, .surrogate, .privateUse, .unassigned,
                 .lineSeparator, .paragraphSeparator:
                return false
            default:
                continue
            }
        }

        return true
    }

    private static func percentEncode<S: StringProtocol>(_ component: S) -> String {
        let hex: [UInt8] = Array("0123456789ABCDEF".utf8)
        var result: [UInt8] = []
        result.reserveCapacity(component.utf8.count)

        for byte in component.utf8 {
            if isAllowedDOIURLByte(byte) {
                result.append(byte)
            } else {
                result.append(37) // %
                result.append(hex[Int(byte >> 4)])
                result.append(hex[Int(byte & 0x0F)])
            }
        }

        return String(decoding: result, as: UTF8.self)
    }

    private static func percentDecodeStrictly(_ value: String) -> String? {
        let source = value.utf8
        var result: [UInt8] = []
        result.reserveCapacity(source.count)
        var iterator = source.makeIterator()

        while let byte = iterator.next() {
            guard byte == 37 else {
                result.append(byte)
                continue
            }

            guard let highByte = iterator.next(),
                  let lowByte = iterator.next(),
                  let high = hexadecimalValue(highByte),
                  let low = hexadecimalValue(lowByte) else {
                return nil
            }

            result.append((high << 4) | low)
        }

        return String(bytes: result, encoding: .utf8)
    }

    private static func hexadecimalValue(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 48...57: byte - 48
        case 65...70: byte - 55
        case 97...102: byte - 87
        default: nil
        }
    }

    private static func isAllowedDOIURLByte(_ byte: UInt8) -> Bool {
        if isASCIIAlphaNumeric(byte) {
            return true
        }

        // RFC 3986 unreserved characters plus the additional DOI Handbook
        // path-component characters: !$&'()*+;=:@
        switch byte {
        case 33, 36, 38, 39, 40, 41, 42, 43, 45, 46,
             58, 59, 61, 64, 95, 126:
            return true
        default:
            return false
        }
    }
}

// MARK: - BibTeXEntry Extension

extension BibTeXEntry {

    /// The DOI as a resolvable HTTPS URL.
    public var doiURL: URL? {
        guard let doi else { return nil }
        return DOIDetector.doiURL(for: doi)
    }

    /// Whether this entry has a syntactically valid DOI.
    public var hasValidDOI: Bool {
        guard let doi else { return false }
        return DOIDetector.normalize(doi) != nil
    }

    /// The canonical DOI name without a presentation prefix.
    public var normalizedDOI: String? {
        guard let doi else { return nil }
        return DOIDetector.normalize(doi)
    }
}
