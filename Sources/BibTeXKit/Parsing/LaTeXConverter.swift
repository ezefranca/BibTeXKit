//
//  LaTeXConverter.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

/// Converts common LaTeX characters, accents, and symbols to Unicode.
///
/// `LaTeXConverter` intentionally implements a display-oriented subset of
/// LaTeX. Unknown commands and unmatched grouping characters are preserved.
///
/// ## Usage
///
/// ```swift
/// let unicode = LaTeXConverter.toUnicode("Caf\\'{e}")
/// // Returns "Café"
///
/// let latex = LaTeXConverter.toLaTeX("Müller")
/// // Returns "M\\\"uller"
/// ```
public struct LaTeXConverter: Sendable {

    // MARK: - Public Methods

    /// Converts supported LaTeX commands to Unicode.
    ///
    /// Control words are matched as complete tokens. For example, `\infty`
    /// converts to `∞`, while the unknown command `\infinity` is preserved.
    ///
    /// - Parameter input: The LaTeX string to convert.
    /// - Returns: A Unicode string.
    public static func toUnicode(_ input: String) -> String {
        toUnicode(input, preservingGroupingBraces: false)
    }

    /// Converts supported LaTeX while retaining BibTeX grouping semantics.
    ///
    /// This internal mode is used by ``BibTeXParser`` so capitalization
    /// protection survives parse-format round trips. The public display API
    /// keeps its established behavior of hiding empty and single-character
    /// presentation groups.
    static func toUnicode(
        _ input: String,
        preservingGroupingBraces: Bool
    ) -> String {
        guard !input.isEmpty else { return input }

        var output = UnicodeOutput(
            minimumCapacity: input.utf8.count,
            preservingGroupingBraces: preservingGroupingBraces
        )
        var index = input.startIndex

        while index < input.endIndex {
            let character = input[index]

            switch character {
            case "\\":
                index = convertCommand(in: input, at: index, into: &output)

            case "{":
                output.beginGroup()
                input.formIndex(after: &index)

            case "}":
                output.endGroup()
                input.formIndex(after: &index)

            case "-":
                let second = input.index(after: index)
                if second < input.endIndex, input[second] == "-" {
                    let third = input.index(after: second)
                    if third < input.endIndex, input[third] == "-" {
                        output.append("—")
                        index = input.index(after: third)
                    } else {
                        output.append("–")
                        index = third
                    }
                } else {
                    output.append(character)
                    index = second
                }

            case "`":
                let next = input.index(after: index)
                if next < input.endIndex, input[next] == "`" {
                    output.append("“")
                    index = input.index(after: next)
                } else {
                    output.append("'")
                    index = next
                }

            case "'":
                let next = input.index(after: index)
                if next < input.endIndex, input[next] == "'" {
                    output.append("”")
                    index = input.index(after: next)
                } else {
                    output.append(character)
                    index = next
                }

            default:
                output.append(character)
                input.formIndex(after: &index)
            }
        }

        return output.finish()
    }

    /// Converts supported Unicode characters to LaTeX.
    ///
    /// - Parameter input: The Unicode string to convert.
    /// - Returns: A LaTeX string.
    public static func toLaTeX(_ input: String) -> String {
        guard !input.isEmpty else { return input }

        var result = ""
        result.reserveCapacity(input.utf8.count)

        var index = input.startIndex
        while index < input.endIndex {
            let character = input[index]
            let next = input.index(after: index)

            if let latex = unicodeToLaTeX[character] {
                result.append(contentsOf: latex)

                // TeX control words consume all following ASCII letters.
                // Insert an empty group only when it is needed to keep the
                // generated command and following text as separate tokens.
                if next < input.endIndex,
                   isControlWord(latex),
                   isASCIIControlLetter(input[next]) {
                    result.append(contentsOf: "{}")
                }
            } else {
                result.append(character)

                // Prevent literal ASCII punctuation from being reinterpreted
                // as TeX ligatures during a round trip. Empty groups separate
                // the source characters without changing rendered output.
                if next < input.endIndex,
                   (character == "'" || character == "-"),
                   input[next] == character {
                    result.append(contentsOf: "{}")
                }
            }

            index = next
        }

        return result
    }

    // MARK: - Command Parsing

    private static func convertCommand(
        in input: String,
        at slash: String.Index,
        into output: inout UnicodeOutput
    ) -> String.Index {
        let commandStart = input.index(after: slash)
        guard commandStart < input.endIndex else {
            output.append("\\")
            return input.endIndex
        }

        let first = input[commandStart]

        if isASCIIControlLetter(first) {
            var commandEnd = input.index(after: commandStart)
            while commandEnd < input.endIndex,
                  isASCIIControlLetter(input[commandEnd]) {
                input.formIndex(after: &commandEnd)
            }

            let command = input[commandStart..<commandEnd]

            // Letter-named accents require a separated argument in TeX. This
            // also prevents partial conversions such as `\category` → `çtegory`.
            if command.count == 1,
               let accent = command.first,
               let characterMap = accentMappings[accent],
               let target = accentTarget(
                   in: input,
                   after: commandEnd,
                   argumentPosition: .separated
               ),
               let replacement = characterMap[target.character] {
                output.append(replacement)
                return target.endIndex
            }

            if let replacement = namedCharacters[command] {
                output.append(replacement)

                if delimiterConsumingCommands.contains(command),
                   commandEnd < input.endIndex,
                   input[commandEnd] == " " {
                    return input.index(after: commandEnd)
                }

                // An empty group immediately after a converted control word is
                // a token delimiter, not bibliographic content.
                return endOfEmptyGroup(in: input, at: commandEnd) ?? commandEnd
            }

            output.append("\\")
            output.append(command)
            // Unknown control words and any immediately following group are
            // preserved structurally. Known commands nested in that group are
            // still converted during the normal scan.
            output.preserveImmediatelyFollowingGroup()
            return commandEnd
        }

        let commandEnd = input.index(after: commandStart)

        if let characterMap = accentMappings[first],
           let target = accentTarget(
               in: input,
               after: commandEnd,
               argumentPosition: .immediate
           ),
           let replacement = characterMap[target.character] {
            output.append(replacement)
            return target.endIndex
        }

        if let replacement = escapedCharacters[first] {
            output.append(replacement)
        } else {
            output.append("\\")
            output.append(first)
        }

        return commandEnd
    }

    private struct AccentTarget {
        let character: Character
        let endIndex: String.Index
    }

    private enum AccentArgumentPosition {
        case separated
        case immediate
    }

    private static func accentTarget(
        in input: String,
        after commandEnd: String.Index,
        argumentPosition: AccentArgumentPosition
    ) -> AccentTarget? {
        guard commandEnd < input.endIndex else { return nil }

        var targetStart = commandEnd
        if input[targetStart] == " " {
            input.formIndex(after: &targetStart)
            guard targetStart < input.endIndex else { return nil }
            return dotlessOrLiteralTarget(in: input, at: targetStart, requiresClosingBrace: false)
        }

        if input[targetStart] == "{" {
            input.formIndex(after: &targetStart)
            guard targetStart < input.endIndex else { return nil }
            return dotlessOrLiteralTarget(in: input, at: targetStart, requiresClosingBrace: true)
        }

        switch argumentPosition {
        case .separated:
            return nil
        case .immediate:
            return dotlessOrLiteralTarget(in: input, at: targetStart, requiresClosingBrace: false)
        }
    }

    /// Parses either a literal accent target or the TeX dotless-letter commands
    /// `\i` and `\j`, with an optional required closing group delimiter.
    private static func dotlessOrLiteralTarget(
        in input: String,
        at start: String.Index,
        requiresClosingBrace: Bool
    ) -> AccentTarget? {
        let character: Character
        var end: String.Index

        if input[start] == "\\" {
            let command = input.index(after: start)
            guard command < input.endIndex,
                  input[command] == "i" || input[command] == "j" else {
                return nil
            }

            character = input[command]
            end = input.index(after: command)
            guard end == input.endIndex || !isASCIIControlLetter(input[end]) else {
                return nil
            }
        } else {
            character = input[start]
            end = input.index(after: start)
        }

        if requiresClosingBrace {
            guard end < input.endIndex, input[end] == "}" else { return nil }
            input.formIndex(after: &end)
        }

        return AccentTarget(character: character, endIndex: end)
    }

    private static func isASCIIControlLetter(_ character: Character) -> Bool {
        guard let value = character.asciiValue else { return false }
        return (65...90).contains(value) || (97...122).contains(value)
    }

    /// Returns the end of a balanced group containing only nested empty groups.
    private static func endOfEmptyGroup(
        in input: String,
        at start: String.Index
    ) -> String.Index? {
        guard start < input.endIndex, input[start] == "{" else {
            return nil
        }

        var index = start
        var depth = 0
        while index < input.endIndex {
            switch input[index] {
            case "{":
                depth += 1
            case "}":
                depth -= 1
                input.formIndex(after: &index)
                if depth == 0 {
                    return index
                }
                continue
            default:
                return nil
            }
            input.formIndex(after: &index)
        }
        return nil
    }

    private static func isControlWord(_ latex: String) -> Bool {
        var iterator = latex.utf8.makeIterator()
        guard iterator.next() == 92,
              let firstCommandByte = iterator.next(),
              let lastByte = latex.utf8.last,
              (65...90).contains(lastByte) || (97...122).contains(lastByte) else {
            return false
        }
        return (65...90).contains(firstCommandByte)
            || (97...122).contains(firstCommandByte)
    }

    // MARK: - Conversion Buffer

    /// A byte-backed output buffer that handles grouping braces without
    /// recursion. Parser mode preserves every group because braces can protect
    /// capitalization in BibTeX. Display mode hides empty and
    /// single-character presentation groups.
    ///
    /// The explicit group stack keeps deeply nested, hostile input bounded by
    /// heap capacity rather than the call stack.
    private struct UnicodeOutput {
        private struct Group {
            let openingBraceOffset: Int
            let preserveBraces: Bool
            var visibleCharacterCount: UInt8
        }

        // This byte cannot occur in a valid UTF-8 string, so it can safely mark
        // grouping braces for removal during the final linear compaction.
        private static let removedBraceMarker: UInt8 = 0xFF

        private var bytes: [UInt8] = []
        private var groups: [Group] = []
        private var firstRemovedBraceOffset: Int?
        private var preserveNextGroup = false
        private let preservingGroupingBraces: Bool

        init(
            minimumCapacity: Int,
            preservingGroupingBraces: Bool
        ) {
            self.preservingGroupingBraces = preservingGroupingBraces
            bytes.reserveCapacity(minimumCapacity)
        }

        mutating func append(_ character: Character) {
            preserveNextGroup = false
            bytes.append(contentsOf: character.utf8)
            recordVisibleCharacters(1)
        }

        mutating func append(_ string: String) {
            preserveNextGroup = false
            bytes.append(contentsOf: string.utf8)
            recordVisibleCharacters(visibleCount(of: string))
        }

        mutating func append(_ substring: Substring) {
            bytes.append(contentsOf: substring.utf8)
            recordVisibleCharacters(visibleCount(of: substring))
        }

        mutating func beginGroup() {
            let preserveBraces = preserveNextGroup
                || preservingGroupingBraces
                || groups.last?.preserveBraces == true
            preserveNextGroup = false
            let offset = bytes.count
            bytes.append(123) // {
            groups.append(
                Group(
                    openingBraceOffset: offset,
                    preserveBraces: preserveBraces,
                    visibleCharacterCount: 0
                )
            )
        }

        mutating func endGroup() {
            preserveNextGroup = false
            guard let group = groups.popLast() else {
                append("}")
                return
            }

            if !group.preserveBraces,
               group.visibleCharacterCount < 2 {
                bytes[group.openingBraceOffset] = Self.removedBraceMarker
                firstRemovedBraceOffset =
                    firstRemovedBraceOffset ?? group.openingBraceOffset
            } else {
                bytes.append(125) // }
                recordVisibleCharacters(2)
            }
        }

        mutating func preserveImmediatelyFollowingGroup() {
            preserveNextGroup = true
        }

        consuming func finish() -> String {
            var finalBytes = bytes
            if firstRemovedBraceOffset != nil {
                finalBytes.removeAll { $0 == Self.removedBraceMarker }
            }
            return String(decoding: finalBytes, as: UTF8.self)
        }

        private mutating func recordVisibleCharacters(_ count: UInt8) {
            guard !groups.isEmpty else { return }
            let current = groups.index(before: groups.endIndex)
            groups[current].visibleCharacterCount = min(
                2,
                groups[current].visibleCharacterCount + count
            )
        }

        private func visibleCount<S: StringProtocol>(of value: S) -> UInt8 {
            UInt8(value.prefix(2).count)
        }
    }

    // MARK: - Accent Mappings

    /// Mapping of LaTeX accents to precomposed Unicode characters.
    private static let accentMappings: [Character: [Character: Character]] = [
        "'": [
            "a": "á", "e": "é", "i": "í", "o": "ó", "u": "ú", "y": "ý",
            "A": "Á", "E": "É", "I": "Í", "O": "Ó", "U": "Ú", "Y": "Ý",
            "c": "ć", "C": "Ć", "n": "ń", "N": "Ń", "s": "ś", "S": "Ś",
            "z": "ź", "Z": "Ź", "l": "ĺ", "L": "Ĺ", "r": "ŕ", "R": "Ŕ",
        ],
        "`": [
            "a": "à", "e": "è", "i": "ì", "o": "ò", "u": "ù",
            "A": "À", "E": "È", "I": "Ì", "O": "Ò", "U": "Ù",
        ],
        "^": [
            "a": "â", "e": "ê", "i": "î", "o": "ô", "u": "û",
            "A": "Â", "E": "Ê", "I": "Î", "O": "Ô", "U": "Û",
            "c": "ĉ", "C": "Ĉ", "g": "ĝ", "G": "Ĝ", "h": "ĥ", "H": "Ĥ",
            "j": "ĵ", "J": "Ĵ", "s": "ŝ", "S": "Ŝ", "w": "ŵ", "W": "Ŵ",
            "y": "ŷ", "Y": "Ŷ",
        ],
        "\"": [
            "a": "ä", "e": "ë", "i": "ï", "o": "ö", "u": "ü", "y": "ÿ",
            "A": "Ä", "E": "Ë", "I": "Ï", "O": "Ö", "U": "Ü", "Y": "Ÿ",
        ],
        "~": [
            "a": "ã", "n": "ñ", "o": "õ",
            "A": "Ã", "N": "Ñ", "O": "Õ",
        ],
        "=": [
            "a": "ā", "e": "ē", "i": "ī", "o": "ō", "u": "ū",
            "A": "Ā", "E": "Ē", "I": "Ī", "O": "Ō", "U": "Ū",
        ],
        ".": [
            "c": "ċ", "C": "Ċ", "e": "ė", "E": "Ė", "g": "ġ", "G": "Ġ",
            "z": "ż", "Z": "Ż", "I": "İ",
        ],
        "u": [
            "a": "ă", "A": "Ă", "g": "ğ", "G": "Ğ", "u": "ŭ", "U": "Ŭ",
        ],
        "v": [
            "c": "č", "C": "Č", "d": "ď", "D": "Ď", "e": "ě", "E": "Ě",
            "n": "ň", "N": "Ň", "r": "ř", "R": "Ř", "s": "š", "S": "Š",
            "t": "ť", "T": "Ť", "z": "ž", "Z": "Ž",
        ],
        "H": [
            "o": "ő", "O": "Ő", "u": "ű", "U": "Ű",
        ],
        "c": [
            "c": "ç", "C": "Ç", "s": "ş", "S": "Ş", "t": "ţ", "T": "Ţ",
        ],
        "k": [
            "a": "ą", "A": "Ą", "e": "ę", "E": "Ę",
        ],
        "r": [
            "a": "å", "A": "Å", "u": "ů", "U": "Ů",
        ],
    ]

    // MARK: - Named Character Mappings

    private static let namedCharacters: [Substring: String] = [
        // Text symbols and special letters
        "textasciitilde": "~",
        "textasciicircum": "^",
        "textasciigrave": "`",
        "textbackslash": "\\",
        "ss": "ß",
        "SS": "SS",
        "ae": "æ",
        "AE": "Æ",
        "oe": "œ",
        "OE": "Œ",
        "aa": "å",
        "AA": "Å",
        "o": "ø",
        "O": "Ø",
        "l": "ł",
        "L": "Ł",
        "i": "ı",
        "j": "ȷ",
        "dag": "†",
        "ddag": "‡",
        "S": "§",
        "P": "¶",
        "copyright": "©",
        "pounds": "£",
        "euro": "€",
        "yen": "¥",
        "textregistered": "®",
        "texttrademark": "™",
        "textdegree": "°",
        "textmu": "µ",
        "ldots": "…",
        "textendash": "–",
        "textemdash": "—",
        "textquoteleft": "'",
        "textquoteright": "'",
        "textquotedblleft": "“",
        "textquotedblright": "”",

        // Greek letters
        "alpha": "α", "beta": "β", "gamma": "γ", "delta": "δ",
        "epsilon": "ε", "zeta": "ζ", "eta": "η", "theta": "θ",
        "iota": "ι", "kappa": "κ", "lambda": "λ", "mu": "μ",
        "nu": "ν", "xi": "ξ", "pi": "π", "rho": "ρ",
        "sigma": "σ", "tau": "τ", "upsilon": "υ", "phi": "φ",
        "chi": "χ", "psi": "ψ", "omega": "ω",
        "Alpha": "Α", "Beta": "Β", "Gamma": "Γ", "Delta": "Δ",
        "Epsilon": "Ε", "Zeta": "Ζ", "Eta": "Η", "Theta": "Θ",
        "Iota": "Ι", "Kappa": "Κ", "Lambda": "Λ", "Mu": "Μ",
        "Nu": "Ν", "Xi": "Ξ", "Pi": "Π", "Rho": "Ρ",
        "Sigma": "Σ", "Tau": "Τ", "Upsilon": "Υ", "Phi": "Φ",
        "Chi": "Χ", "Psi": "Ψ", "Omega": "Ω",

        // Mathematical symbols
        "times": "×", "div": "÷", "pm": "±", "mp": "∓",
        "cdot": "·", "bullet": "•", "circ": "∘",
        "leq": "≤", "geq": "≥", "neq": "≠", "approx": "≈",
        "equiv": "≡", "sim": "∼", "propto": "∝",
        "infty": "∞", "partial": "∂", "nabla": "∇",
        "sum": "∑", "prod": "∏", "int": "∫",
        "sqrt": "√", "angle": "∠", "degree": "°",
        "forall": "∀", "exists": "∃", "in": "∈", "notin": "∉",
        "subset": "⊂", "supset": "⊃", "cup": "∪", "cap": "∩",
        "land": "∧", "lor": "∨", "neg": "¬",
        "rightarrow": "→", "leftarrow": "←", "leftrightarrow": "↔",
        "Rightarrow": "⇒", "Leftarrow": "⇐", "Leftrightarrow": "⇔",
    ]

    /// These TeX letter commands consume one delimiting space so input such as
    /// `\AA rhus` renders as `Århus`.
    private static let delimiterConsumingCommands: Set<Substring> = [
        "ss", "ae", "AE", "oe", "OE", "aa", "AA",
        "o", "O", "l", "L", "i", "j",
    ]

    private static let escapedCharacters: [Character: String] = [
        "&": "&",
        "%": "%",
        "$": "$",
        "#": "#",
        "_": "_",
        "{": "{",
        "}": "}",
    ]

    // MARK: - Reverse Mapping

    private static let unicodeToLaTeX: [Character: String] = {
        var mapping: [Character: String] = [:]
        let simpleAccents: Set<Character> = ["'", "`", "^", "\"", "~"]

        for (accent, characterMap) in accentMappings {
            for (original, converted) in characterMap {
                if simpleAccents.contains(accent) {
                    mapping[converted] = "\\\(accent)\(original)"
                } else {
                    mapping[converted] = "\\\(accent){\(original)}"
                }
            }
        }

        // Accent spellings remain preferred for characters such as å. Every
        // other one-character named result gets a deterministic reverse form.
        for (command, unicode) in namedCharacters {
            guard unicode.count == 1,
                  let character = unicode.first,
                  character.asciiValue == nil,
                  mapping[character] == nil else {
                continue
            }
            mapping[character] = "\\\(command)"
        }

        mapping["&"] = "\\&"
        mapping["%"] = "\\%"
        mapping["$"] = "\\$"
        mapping["#"] = "\\#"
        mapping["_"] = "\\_"
        mapping["{"] = "\\{"
        mapping["}"] = "\\}"
        mapping["\\"] = "\\textbackslash{}"
        mapping["~"] = "\\textasciitilde{}"
        mapping["^"] = "\\textasciicircum{}"
        mapping["`"] = "\\textasciigrave{}"

        // Prefer unambiguous text commands where multiple commands share a
        // Unicode result.
        mapping["°"] = "\\textdegree"
        mapping["µ"] = "\\textmu"
        mapping["–"] = "\\textendash"
        mapping["—"] = "\\textemdash"
        mapping["“"] = "\\textquotedblleft"
        mapping["”"] = "\\textquotedblright"

        return mapping
    }()
}
