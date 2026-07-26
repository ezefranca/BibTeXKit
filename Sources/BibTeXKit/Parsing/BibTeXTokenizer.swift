//
//  BibTeXTokenizer.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

/// A tokenizer for BibTeX and embedded LaTeX content.
///
/// `BibTeXTokenizer` breaks down BibTeX strings into tokens suitable
/// for syntax highlighting. It handles:
///
/// - Standard and custom BibTeX entry types
/// - Deeply nested braces without recursive parsing
/// - Comments (%)
/// - LaTeX commands and accents
/// - Math mode
/// - Special characters
///
/// ## Usage
///
/// ```swift
/// let tokenizer = BibTeXTokenizer()
/// let tokens = tokenizer.tokenize(bibtexString)
///
/// for token in tokens {
///     print("\(token.token): \(token.text)")
/// }
/// ```
///
/// ## Thread Safety
///
/// `BibTeXTokenizer` is a stateless `Sendable` value and can be shared
/// across concurrency domains.
public struct BibTeXTokenizer: Sendable {

    // MARK: - Constants

    private static let accentCommands: Set<Character> = [
        "'", "`", "^", "\"", "~", "=", ".", "u", "v", "H", "t", "c", "d", "b", "r", "k"
    ]

    // MARK: - Initialization

    /// Creates a new tokenizer.
    public init() {}

    // MARK: - Public Methods

    /// Tokenizes a BibTeX string.
    ///
    /// - Parameter input: The BibTeX string to tokenize.
    /// - Returns: An array of tokens with their positions.
    public func tokenize(_ input: String) -> [BibTeXTokenInfo] {
        guard !input.isEmpty else { return [] }

        var tokens: [BibTeXTokenInfo] = []
        tokens.reserveCapacity(estimatedTokenCount(for: input))

        scanTokens(in: input) { token, range in
            tokens.append(
                BibTeXTokenInfo(
                    token: token,
                    text: String(input[range]),
                    range: range
                )
            )
        }

        return tokens
    }

    /// Tokenizes and returns just the token-text pairs (simplified output).
    ///
    /// - Parameter input: The BibTeX string to tokenize.
    /// - Returns: An array of (text, token) tuples.
    public func tokenizePairs(_ input: String) -> [(text: String, token: BibTeXToken)] {
        guard !input.isEmpty else { return [] }

        var pairs: [(text: String, token: BibTeXToken)] = []
        pairs.reserveCapacity(estimatedTokenCount(for: input))

        scanTokens(in: input) { token, range in
            pairs.append((String(input[range]), token))
        }

        return pairs
    }

    /// Visits positioned tokens without allocating public token-info values or
    /// per-token text copies. Used by the highlighter's allocation-sensitive
    /// path while the public APIs retain their existing return types.
    func scanTokens(
        in input: String,
        _ visit: (BibTeXToken, Range<String.Index>) -> Void
    ) {
        var index = input.startIndex
        var context = TokenContext()

        while index < input.endIndex {
            let startIndex = index
            let token = consumeToken(in: input, at: &index, context: &context)
            visit(token, startIndex..<index)
        }
    }

    // MARK: - Private Types

    private enum EntryKind {
        case regular
        case string
        case preamble
        case comment
    }

    private struct TokenContext {
        var pendingEntry: EntryKind?
        var entryKind: EntryKind?
        var entryOpeningDelimiter: Character?
        var entryClosingDelimiter: Character?
        var entryDepth = 0
        var expectingCitationKey = false
        var expectingFieldValue = false
        var fieldValueBraceDepth = 0
        var quotedValueBraceDepth: Int?

        mutating func beginEntry(kind: EntryKind, openingDelimiter: Character) {
            pendingEntry = nil
            entryKind = kind
            entryOpeningDelimiter = openingDelimiter
            entryClosingDelimiter = openingDelimiter == "{" ? "}" : ")"
            entryDepth = 1
            expectingCitationKey = kind == .regular
            expectingFieldValue = kind == .preamble
            fieldValueBraceDepth = 0
            quotedValueBraceDepth = nil
        }

        mutating func endEntry() {
            pendingEntry = nil
            entryKind = nil
            entryOpeningDelimiter = nil
            entryClosingDelimiter = nil
            entryDepth = 0
            expectingCitationKey = false
            expectingFieldValue = false
            fieldValueBraceDepth = 0
            quotedValueBraceDepth = nil
        }
    }

    // MARK: - Token Scanning

    private func consumeToken(
        in input: String,
        at index: inout String.Index,
        context: inout TokenContext
    ) -> BibTeXToken {
        if let braceDepth = context.quotedValueBraceDepth {
            return consumeQuotedValueToken(
                in: input,
                at: &index,
                braceDepth: braceDepth,
                context: &context
            )
        }

        let first = input[index]

        if first.isWhitespace {
            consumeWhitespace(in: input, at: &index)
            return .whitespace
        }

        if first == "%",
           context.fieldValueBraceDepth == 0,
           context.entryKind != .comment {
            consumeComment(in: input, at: &index)
            return .comment
        }

        if first == "@",
           context.entryKind == nil,
           let entryKind = consumeEntryTypeIfPresent(in: input, at: &index) {
            context.pendingEntry = entryKind
            return entryKind == .regular ? .entryType : .special
        }

        if let pendingEntry = context.pendingEntry {
            if first == "{" || first == "(" {
                input.formIndex(after: &index)
                context.beginEntry(kind: pendingEntry, openingDelimiter: first)
                return .punctuation
            }
            context.pendingEntry = nil
        }

        if context.expectingCitationKey {
            if first == "," {
                input.formIndex(after: &index)
                context.expectingCitationKey = false
                return .punctuation
            }
            if context.entryOpeningDelimiter == "{",
               first == context.entryClosingDelimiter {
                consumeClosingDelimiter(first, in: input, at: &index, context: &context)
                return .punctuation
            }

            consumeCitationKey(
                in: input,
                at: &index,
                openingDelimiter: context.entryOpeningDelimiter,
                closingDelimiter: context.entryClosingDelimiter
            )
            context.expectingCitationKey = false
            return .citationKey
        }

        if first == "{" || first == "(" {
            if context.fieldValueBraceDepth > 0, first == "(" {
                input.formIndex(after: &index)
                return .string
            }

            input.formIndex(after: &index)

            if context.expectingFieldValue, first == "{" {
                context.fieldValueBraceDepth = 1
                context.expectingFieldValue = false
            } else if context.fieldValueBraceDepth > 0, first == "{" {
                context.fieldValueBraceDepth += 1
            }

            if first == context.entryOpeningDelimiter {
                context.entryDepth += 1
            }
            return .punctuation
        }

        if first == "}" || first == ")" {
            if context.fieldValueBraceDepth > 0, first == ")" {
                input.formIndex(after: &index)
                return .string
            }

            consumeClosingDelimiter(first, in: input, at: &index, context: &context)
            return .punctuation
        }

        if first == "," {
            input.formIndex(after: &index)
            if context.fieldValueBraceDepth > 0 {
                return .string
            }
            context.expectingCitationKey = false
            context.expectingFieldValue = false
            return .punctuation
        }

        if first == "=" {
            input.formIndex(after: &index)
            guard context.fieldValueBraceDepth == 0,
                  context.entryKind != nil,
                  context.entryKind != .comment else {
                return context.fieldValueBraceDepth > 0 ? .string : .text
            }
            context.expectingFieldValue = true
            return .operator
        }

        if first == "#" {
            input.formIndex(after: &index)
            guard context.fieldValueBraceDepth == 0,
                  context.entryKind != nil,
                  context.entryKind != .comment else {
                return context.fieldValueBraceDepth > 0 ? .string : .text
            }
            context.expectingFieldValue = true
            return .operator
        }

        if let identifier = bibTeXIdentifierToken(
            in: input,
            at: index,
            context: context
        ) {
            index = identifier.endIndex
            if identifier.token == .constant {
                context.expectingFieldValue = false
            }
            return identifier.token
        }

        if first == "\"" {
            if context.fieldValueBraceDepth > 0 {
                input.formIndex(after: &index)
                return .string
            }

            if context.expectingFieldValue {
                input.formIndex(after: &index)
                context.expectingFieldValue = false
                context.quotedValueBraceDepth = 0
                return .string
            }

            consumeQuotedString(in: input, at: &index)
            context.expectingFieldValue = false
            return .string
        }

        if first == "\\" {
            return consumeLaTeXCommand(in: input, at: &index)
        }

        if first == "$" {
            if context.fieldValueBraceDepth > 0 {
                consumeBracedMathMode(
                    in: input,
                    at: &index,
                    context: &context
                )
            } else {
                consumeMathMode(in: input, at: &index)
            }
            return .math
        }

        if first.isNumber {
            consumeNumber(in: input, at: &index)

            if context.fieldValueBraceDepth > 0 {
                return .string
            }
            if context.expectingFieldValue {
                context.expectingFieldValue = false
                return .number
            }
            return .text
        }

        if first.isLetter
            || first == "_"
            || (canContainFields(context.entryKind) && isWordCharacter(first)) {
            let startIndex = index
            consumeWord(in: input, at: &index)

            if context.fieldValueBraceDepth > 0 {
                return .string
            }
            if context.expectingFieldValue {
                context.expectingFieldValue = false
                return .constant
            }
            if isKnownMonth(in: input, range: startIndex..<index) {
                return .constant
            }
            return .text
        }

        input.formIndex(after: &index)
        return context.fieldValueBraceDepth > 0 ? .string : .text
    }

    private func consumeClosingDelimiter(
        _ delimiter: Character,
        in input: String,
        at index: inout String.Index,
        context: inout TokenContext
    ) {
        input.formIndex(after: &index)

        if context.fieldValueBraceDepth > 0 {
            if delimiter == "}" {
                context.fieldValueBraceDepth -= 1
                if context.entryOpeningDelimiter == "{" {
                    context.entryDepth = max(0, context.entryDepth - 1)
                }
            }
            return
        }

        guard delimiter == context.entryClosingDelimiter else {
            return
        }

        context.entryDepth = max(0, context.entryDepth - 1)
        if context.entryDepth == 0 {
            context.endEntry()
        }
    }

    // MARK: - Token Consumers

    private func consumeQuotedValueToken(
        in input: String,
        at index: inout String.Index,
        braceDepth: Int,
        context: inout TokenContext
    ) -> BibTeXToken {
        let character = input[index]
        switch character {
        case "{":
            input.formIndex(after: &index)
            context.quotedValueBraceDepth = braceDepth + 1
            return .punctuation
        case "}":
            if braceDepth > 0 {
                input.formIndex(after: &index)
                context.quotedValueBraceDepth = braceDepth - 1
            } else {
                context.quotedValueBraceDepth = nil
                consumeClosingDelimiter(character, in: input, at: &index, context: &context)
            }
            return .punctuation
        case "\"":
            input.formIndex(after: &index)
            if braceDepth == 0 {
                context.quotedValueBraceDepth = nil
            }
            return .string
        case "\\":
            let nextIndex = input.index(after: index)
            if braceDepth == 0,
               nextIndex < input.endIndex,
               input[nextIndex] == "\"" {
                input.formIndex(after: &index)
                return .command
            }
            return consumeLaTeXCommand(in: input, at: &index)
        case "$":
            consumeQuotedMathMode(in: input, at: &index)
            return .math
        default:
            consumeQuotedValueText(in: input, at: &index)
            return .string
        }
    }

    private func consumeQuotedValueText(in input: String, at index: inout String.Index) {
        repeat {
            input.formIndex(after: &index)
        } while index < input.endIndex
            && input[index] != "{"
            && input[index] != "}"
            && input[index] != "\""
            && input[index] != "\\"
            && input[index] != "$"
    }

    private func consumeWhitespace(in input: String, at index: inout String.Index) {
        repeat {
            input.formIndex(after: &index)
        } while index < input.endIndex && input[index].isWhitespace
    }

    private func consumeComment(in input: String, at index: inout String.Index) {
        repeat {
            input.formIndex(after: &index)
        } while index < input.endIndex && !input[index].isNewline
    }

    private func consumeEntryTypeIfPresent(
        in input: String,
        at index: inout String.Index
    ) -> EntryKind? {
        let atIndex = index
        input.formIndex(after: &index)
        while index < input.endIndex, input[index].isWhitespace {
            input.formIndex(after: &index)
        }
        let nameStart = index

        guard index < input.endIndex, isIdentifierStartCharacter(input[index]) else {
            index = atIndex
            return nil
        }

        while index < input.endIndex, isIdentifierCharacter(input[index]) {
            input.formIndex(after: &index)
        }

        let nameRange = nameStart..<index
        if equalsASCII("comment", in: input, range: nameRange) {
            return .comment
        }
        if equalsASCII("preamble", in: input, range: nameRange) {
            return .preamble
        }
        if equalsASCII("string", in: input, range: nameRange) {
            return .string
        }
        return .regular
    }

    private func consumeCitationKey(
        in input: String,
        at index: inout String.Index,
        openingDelimiter: Character?,
        closingDelimiter: Character?
    ) {
        repeat {
            input.formIndex(after: &index)
        } while index < input.endIndex
            && !input[index].isWhitespace
            && input[index] != ","
            && input[index] != "%"
            && !citationKeyIsTerminated(
                by: input[index],
                openingDelimiter: openingDelimiter,
                closingDelimiter: closingDelimiter
            )
    }

    private func citationKeyIsTerminated(
        by character: Character,
        openingDelimiter: Character?,
        closingDelimiter: Character?
    ) -> Bool {
        character == closingDelimiter && openingDelimiter != "("
    }

    private func consumeQuotedString(in input: String, at index: inout String.Index) {
        input.formIndex(after: &index)
        var braceDepth = 0

        while index < input.endIndex {
            let character = input[index]

            if character == "{" {
                braceDepth += 1
            } else if character == "}" {
                guard braceDepth > 0 else {
                    return
                }
                braceDepth -= 1
            } else if character == "\"", braceDepth == 0 {
                input.formIndex(after: &index)
                return
            }
            input.formIndex(after: &index)
        }
    }

    private func consumeLaTeXCommand(
        in input: String,
        at index: inout String.Index
    ) -> BibTeXToken {
        input.formIndex(after: &index)
        guard index < input.endIndex else {
            return .text
        }

        let commandStart = index
        let nextCharacter = input[index]

        if nextCharacter == "{" || nextCharacter == "}" {
            return .command
        }

        if isSpecialCommandCharacter(nextCharacter) {
            input.formIndex(after: &index)
            return .specialChar
        }

        if !nextCharacter.isLetter, Self.accentCommands.contains(nextCharacter) {
            input.formIndex(after: &index)
            consumeAccentArgumentIfPresent(in: input, at: &index)
            return .accent
        }

        if !nextCharacter.isLetter {
            input.formIndex(after: &index)
            return .command
        }

        while index < input.endIndex && input[index].isLetter {
            input.formIndex(after: &index)
        }
        let commandEnd = index

        if commandEnd == input.index(after: commandStart),
           Self.accentCommands.contains(nextCharacter) {
            consumeAccentArgumentIfPresent(in: input, at: &index)
            return .accent
        }

        if index < input.endIndex && input[index] == "*" {
            input.formIndex(after: &index)
        }

        if equalsASCII("begin", in: input, range: commandStart..<commandEnd)
            || equalsASCII("end", in: input, range: commandStart..<commandEnd) {
            consumeBracedGroupIfPresent(in: input, at: &index)
            return .environment
        }

        return .command
    }

    private func consumeAccentArgumentIfPresent(in input: String, at index: inout String.Index) {
        guard index < input.endIndex else { return }

        if input[index] == "{" {
            consumeBracedGroupIfPresent(in: input, at: &index)
        } else if input[index].isLetter {
            input.formIndex(after: &index)
        }
    }

    private func consumeBracedGroupIfPresent(in input: String, at index: inout String.Index) {
        guard index < input.endIndex, input[index] == "{" else {
            return
        }

        var depth = 0

        while index < input.endIndex {
            let character = input[index]

            if character == "{" {
                depth += 1
            } else if character == "}" {
                depth -= 1
            }

            input.formIndex(after: &index)
            if depth == 0 {
                return
            }
        }
    }

    private func consumeMathMode(in input: String, at index: inout String.Index) {
        input.formIndex(after: &index)

        let isDisplayMath = index < input.endIndex && input[index] == "$"
        if isDisplayMath {
            input.formIndex(after: &index)
        }

        var escaped = false
        while index < input.endIndex {
            let character = input[index]

            if escaped {
                escaped = false
                input.formIndex(after: &index)
            } else if character == "\\" {
                escaped = true
                input.formIndex(after: &index)
            } else if character == "$" {
                let nextIndex = input.index(after: index)
                if isDisplayMath {
                    if nextIndex < input.endIndex, input[nextIndex] == "$" {
                        index = input.index(after: nextIndex)
                        return
                    }
                    index = nextIndex
                } else {
                    index = nextIndex
                    return
                }
            } else {
                input.formIndex(after: &index)
            }
        }
    }

    private func consumeBracedMathMode(
        in input: String,
        at index: inout String.Index,
        context: inout TokenContext
    ) {
        let containingBraceDepth = context.fieldValueBraceDepth
        input.formIndex(after: &index)

        let isDisplayMath = index < input.endIndex && input[index] == "$"
        if isDisplayMath {
            input.formIndex(after: &index)
        }

        var escaped = false
        while index < input.endIndex {
            let character = input[index]

            if character == "{" {
                escaped = false
                input.formIndex(after: &index)
                context.fieldValueBraceDepth += 1
                if context.entryOpeningDelimiter == "{" {
                    context.entryDepth += 1
                }
            } else if character == "}" {
                guard context.fieldValueBraceDepth > containingBraceDepth else {
                    return
                }
                escaped = false
                consumeClosingDelimiter(
                    character,
                    in: input,
                    at: &index,
                    context: &context
                )
            } else if escaped {
                escaped = false
                input.formIndex(after: &index)
            } else if character == "\\" {
                escaped = true
                input.formIndex(after: &index)
            } else if character == "$" {
                let nextIndex = input.index(after: index)
                if isDisplayMath {
                    if nextIndex < input.endIndex, input[nextIndex] == "$" {
                        index = input.index(after: nextIndex)
                        return
                    }
                    index = nextIndex
                } else {
                    index = nextIndex
                    return
                }
            } else {
                input.formIndex(after: &index)
            }
        }
    }

    private func consumeQuotedMathMode(in input: String, at index: inout String.Index) {
        input.formIndex(after: &index)

        let isDisplayMath = index < input.endIndex && input[index] == "$"
        if isDisplayMath {
            input.formIndex(after: &index)
        }

        var escaped = false
        while index < input.endIndex {
            let character = input[index]

            if character == "{" || character == "}" || character == "\"" {
                return
            }
            if escaped {
                escaped = false
                input.formIndex(after: &index)
            } else if character == "\\" {
                escaped = true
                input.formIndex(after: &index)
            } else if character == "$" {
                let nextIndex = input.index(after: index)
                if isDisplayMath {
                    if nextIndex < input.endIndex, input[nextIndex] == "$" {
                        index = input.index(after: nextIndex)
                        return
                    }
                    index = nextIndex
                } else {
                    index = nextIndex
                    return
                }
            } else {
                input.formIndex(after: &index)
            }
        }
    }

    private func consumeNumber(in input: String, at index: inout String.Index) {
        repeat {
            input.formIndex(after: &index)
        } while index < input.endIndex && input[index].isNumber
    }

    private func consumeWord(in input: String, at index: inout String.Index) {
        repeat {
            input.formIndex(after: &index)
        } while index < input.endIndex && isWordCharacter(input[index])
    }

    // MARK: - Classification Helpers

    private func canContainFields(_ entryKind: EntryKind?) -> Bool {
        entryKind == .regular || entryKind == .string
    }

    private func isFollowedByEquals(in input: String, after index: String.Index) -> Bool {
        var lookahead = index

        while lookahead < input.endIndex {
            if input[lookahead].isWhitespace {
                input.formIndex(after: &lookahead)
            } else if input[lookahead] == "%" {
                repeat {
                    input.formIndex(after: &lookahead)
                } while lookahead < input.endIndex && !input[lookahead].isNewline
            } else {
                return input[lookahead] == "="
            }
        }

        return false
    }

    private func bibTeXIdentifierToken(
        in input: String,
        at index: String.Index,
        context: TokenContext
    ) -> (endIndex: String.Index, token: BibTeXToken)? {
        guard context.fieldValueBraceDepth == 0 else {
            return nil
        }

        if context.expectingFieldValue {
            guard isIdentifierStartCharacter(input[index]) else {
                return nil
            }

            var endIndex = index
            while endIndex < input.endIndex,
                  isIdentifierCharacter(input[endIndex]) {
                input.formIndex(after: &endIndex)
            }
            return (endIndex, .constant)
        }

        guard canContainFields(context.entryKind) else {
            return nil
        }

        let token: BibTeXToken
        if isIdentifierStartCharacter(input[index]) {
            token = .fieldName
        } else if input[index].isNumber {
            token = .text
        } else {
            return nil
        }

        var endIndex = index
        while endIndex < input.endIndex,
              isIdentifierCharacter(input[endIndex]) {
            input.formIndex(after: &endIndex)
        }

        guard isFollowedByEquals(in: input, after: endIndex) else {
            return nil
        }
        return (endIndex, token)
    }

    private func isKnownMonth(in input: String, range: Range<String.Index>) -> Bool {
        var iterator = input[range].utf8.makeIterator()
        guard let firstByte = iterator.next(),
              let first = asciiLowercasedLetter(firstByte),
              let secondByte = iterator.next(),
              let second = asciiLowercasedLetter(secondByte),
              let thirdByte = iterator.next(),
              let third = asciiLowercasedLetter(thirdByte),
              iterator.next() == nil else {
            return false
        }
        let packed = UInt32(first) << 16
            | UInt32(second) << 8
            | UInt32(third)
        switch packed {
        case 0x6A_61_6E, 0x66_65_62, 0x6D_61_72, 0x61_70_72,
             0x6D_61_79, 0x6A_75_6E, 0x6A_75_6C, 0x61_75_67,
             0x73_65_70, 0x6F_63_74, 0x6E_6F_76, 0x64_65_63:
            return true
        default:
            return false
        }
    }

    private func equalsASCII(
        _ expected: String,
        in input: String,
        range: Range<String.Index>
    ) -> Bool {
        input[range].utf8.elementsEqual(expected.utf8) { byte, expectedByte in
            asciiLowercasedLetter(byte) == expectedByte
        }
    }

    private func asciiLowercasedLetter(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 0x41...0x5A:
            byte | 0x20
        case 0x61...0x7A:
            byte
        default:
            nil
        }
    }

    private func isSpecialCommandCharacter(_ character: Character) -> Bool {
        switch character {
        case "\\", "&", "%", "$", "#", "_", "{", "}":
            return true
        default:
            return false
        }
    }

    private func isWordCharacter(_ character: Character) -> Bool {
        guard !character.isWhitespace else { return false }

        switch character {
        case "\"", "#", "$", "%", "'", "(", ")", ",", "=", "@", "\\", "{", "}":
            return false
        default:
            return true
        }
    }

    private func isIdentifierCharacter(_ character: Character) -> Bool {
        guard !character.isWhitespace, character.unicodeScalars.allSatisfy({
            switch $0.properties.generalCategory {
            case .control, .format, .surrogate, .privateUse, .unassigned,
                 .lineSeparator, .paragraphSeparator:
                return false
            default:
                return true
            }
        }) else {
            return false
        }

        switch character {
        case "\"", "#", "%", "'", "(", ")", ",", "=", "{", "}":
            return false
        default:
            return true
        }
    }

    private func isIdentifierStartCharacter(_ character: Character) -> Bool {
        !character.isNumber && isIdentifierCharacter(character)
    }

    private func estimatedTokenCount(for input: String) -> Int {
        min(max(8, input.utf8.count / 6), 4_096)
    }
}
