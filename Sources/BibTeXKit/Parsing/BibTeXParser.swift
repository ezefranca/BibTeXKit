//
//  BibTeXParser.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// A parser for BibTeX content.
///
/// `BibTeXParser` converts raw BibTeX strings into structured
/// `BibTeXEntry` objects. Named constants declared by `@string` are
/// resolved in subsequent entries; `@comment` and `@preamble` directives
/// are validated but are not returned as bibliography entries. When a
/// database repeats a citation key, comparison is case-insensitive and the
/// first entry wins, matching BibTeX's whole-file identity rules.
///
/// ## Parsing a Single Entry
///
/// ```swift
/// let bibtex = """
/// @article{doe2024,
///     author = {John Doe},
///     title = {Example Paper},
///     year = {2024}
/// }
/// """
///
/// let entries = try BibTeXParser.parse(bibtex)
/// print(entries.first?.title)  // "Example Paper"
/// ```
///
/// ## Parsing Multiple Entries
///
/// ```swift
/// let entries = try BibTeXParser.parse(bibtexFile)
/// for entry in entries {
///     print(entry.citationKey)
/// }
/// ```
///
/// ## Error Handling
///
/// ```swift
/// do {
///     let entries = try BibTeXParser.parse(bibtex)
/// } catch let error as BibTeXParser.Error {
///     print(error.localizedDescription)
/// }
/// ```
public struct BibTeXParser: Sendable {
    
    // MARK: - Error Types
    
    /// Errors that can occur during BibTeX parsing.
    public enum Error: LocalizedError, Sendable, Equatable {
        /// The input string is empty.
        case emptyInput
        
        /// No bibliography entries were found after comments and directives were processed.
        case noEntriesFound
        
        /// The entry type is missing or invalid.
        case invalidEntryType(position: Int)
        
        /// The citation key is missing.
        case missingCitationKey(entryType: String, position: Int)
        
        /// An opening brace or parenthesis is missing.
        case missingOpeningBrace(position: Int)
        
        /// A closing brace or parenthesis is missing.
        case unmatchedBraces(position: Int)
        
        /// A field value is malformed.
        case invalidFieldValue(field: String, position: Int)
        
        /// An unexpected character was encountered.
        case unexpectedCharacter(character: Character, position: Int)
        
        public var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "The input string is empty"
            case .noEntriesFound:
                return "No valid BibTeX entries were found"
            case .invalidEntryType(let position):
                return "Invalid entry type at position \(position)"
            case .missingCitationKey(let entryType, let position):
                return "Missing citation key for @\(entryType) at position \(position)"
            case .missingOpeningBrace(let position):
                return "Missing opening brace at position \(position)"
            case .unmatchedBraces(let position):
                return "Unmatched braces at position \(position)"
            case .invalidFieldValue(let field, let position):
                return "Invalid value for field '\(field)' at position \(position)"
            case .unexpectedCharacter(let character, let position):
                return "Unexpected character '\(character)' at position \(position)"
            }
        }
    }
    
    // MARK: - Configuration
    
    /// Options for parsing BibTeX.
    public struct Options: Sendable {
        /// Whether to preserve the original raw BibTeX in parsed entries.
        public var preserveRawBibTeX: Bool
        
        /// Whether to normalize field names to lowercase.
        public var normalizeFieldNames: Bool
        
        /// Whether to strip surrounding braces/quotes from values.
        public var stripDelimiters: Bool
        
        /// Whether to convert supported LaTeX accents, commands, symbols, and
        /// typography to Unicode.
        public var convertLaTeXToUnicode: Bool

        /// Whether a nonempty input must contain at least one bibliography entry.
        ///
        /// When false, comment-only, directive-only, and other entry-free input
        /// parses as an empty array, preserving standard BibTeX behavior.
        public var requireEntries: Bool
        
        /// The default options.
        public static let `default` = Options()
        
        /// Options for strict parsing.
        public static let strict = Options(
            preserveRawBibTeX: true,
            normalizeFieldNames: true,
            stripDelimiters: true,
            convertLaTeXToUnicode: false,
            requireEntries: true
        )
        
        public init(
            preserveRawBibTeX: Bool = false,
            normalizeFieldNames: Bool = true,
            stripDelimiters: Bool = true,
            convertLaTeXToUnicode: Bool = true,
            requireEntries: Bool = false
        ) {
            self.preserveRawBibTeX = preserveRawBibTeX
            self.normalizeFieldNames = normalizeFieldNames
            self.stripDelimiters = stripDelimiters
            self.convertLaTeXToUnicode = convertLaTeXToUnicode
            self.requireEntries = requireEntries
        }
    }
    
    // MARK: - Properties
    
    /// The parsing options.
    public let options: Options
    
    // MARK: - Initialization
    
    /// Creates a new parser with the specified options.
    ///
    /// - Parameter options: The parsing options.
    public init(options: Options = .default) {
        self.options = options
    }
    
    // MARK: - Static Methods
    
    /// Parses a BibTeX string into entries.
    ///
    /// - Parameters:
    ///   - input: The BibTeX string to parse.
    ///   - options: The parsing options.
    /// - Returns: An array of parsed entries.
    /// - Throws: `BibTeXParser.Error` if parsing fails.
    public static func parse(_ input: String, options: Options = .default) throws -> [BibTeXEntry] {
        let parser = BibTeXParser(options: options)
        return try parser.parse(input)
    }
    
    /// Attempts to parse a BibTeX string, returning nil on failure.
    ///
    /// - Parameters:
    ///   - input: The BibTeX string to parse.
    ///   - options: The parsing options.
    /// - Returns: An array of parsed entries, or nil if parsing fails.
    public static func parseOrNil(_ input: String, options: Options = .default) -> [BibTeXEntry]? {
        try? parse(input, options: options)
    }
    
    // MARK: - Instance Methods
    
    /// Parses a BibTeX string into entries.
    ///
    /// - Parameter input: The BibTeX string to parse.
    /// - Returns: An array of parsed entries.
    /// - Throws: `BibTeXParser.Error` if parsing fails.
    public func parse(_ input: String) throws -> [BibTeXEntry] {
        var index = input.startIndex
        while index < input.endIndex && input[index].isWhitespace {
            input.formIndex(after: &index)
        }

        guard index < input.endIndex else {
            throw Error.emptyInput
        }

        var entries: [BibTeXEntry] = []
        var seenCitationKeys: Set<String> = []
        var stringConstants: [String: String] = [:]

        while true {
            skipWhitespaceAndComments(in: input, at: &index)

            guard index < input.endIndex else { break }

            if input[index] == "@" {
                if let entry = try parseElement(
                    from: input,
                    at: &index,
                    stringConstants: &stringConstants
                ), seenCitationKeys.insert(
                    entry.citationKey.lowercased()
                ).inserted {
                    entries.append(entry)
                }
            } else {
                input.formIndex(after: &index)
            }
        }

        guard !entries.isEmpty || !options.requireEntries else {
            throw Error.noEntriesFound
        }

        return entries
    }

    // MARK: - Private Methods

    private func skipWhitespaceAndComments(in input: String, at index: inout String.Index) {
        while index < input.endIndex {
            let char = input[index]

            if char.isWhitespace {
                input.formIndex(after: &index)
            } else if char == "%" {
                repeat {
                    input.formIndex(after: &index)
                } while index < input.endIndex && !input[index].isNewline
            } else {
                break
            }
        }
    }

    private func parseElement(
        from input: String,
        at index: inout String.Index,
        stringConstants: inout [String: String]
    ) throws -> BibTeXEntry? {
        let entryStart = index

        // The scanner calls this method only after recognizing an entry marker.
        input.formIndex(after: &index)
        skipWhitespaceAndComments(in: input, at: &index)

        let typeStart = index
        guard index < input.endIndex,
              isIdentifierStartCharacter(input[index]) else {
            throw Error.invalidEntryType(position: offset(of: typeStart, in: input))
        }
        while index < input.endIndex && isIdentifierCharacter(input[index]) {
            input.formIndex(after: &index)
        }

        let typeName = String(input[typeStart..<index])
        let normalizedType = typeName.lowercased()

        skipWhitespaceAndComments(in: input, at: &index)

        if normalizedType == "comment" {
            if index < input.endIndex,
               input[index] == "{" || input[index] == "(" {
                let openingDelimiter = input[index]
                let openingIndex = index
                let closingDelimiter: Character = openingDelimiter == "{" ? "}" : ")"
                input.formIndex(after: &index)
                try skipBalancedBody(
                    in: input,
                    at: &index,
                    openingDelimiter: openingDelimiter,
                    closingDelimiter: closingDelimiter,
                    openingIndex: openingIndex
                )
            }
            return nil
        }

        guard index < input.endIndex else {
            throw Error.missingOpeningBrace(position: offset(of: index, in: input))
        }

        let openingDelimiter = input[index]
        guard openingDelimiter == "{" || openingDelimiter == "(" else {
            throw Error.missingOpeningBrace(position: offset(of: index, in: input))
        }

        let openingIndex = index
        let closingDelimiter: Character = openingDelimiter == "{" ? "}" : ")"
        input.formIndex(after: &index)

        switch normalizedType {
        case "preamble":
            try parsePreambleDirective(
                from: input,
                at: &index,
                closingDelimiter: closingDelimiter,
                openingIndex: openingIndex,
                stringConstants: stringConstants
            )
            return nil
        case "string":
            try parseStringDirective(
                from: input,
                at: &index,
                closingDelimiter: closingDelimiter,
                openingIndex: openingIndex,
                stringConstants: &stringConstants
            )
            return nil
        default:
            break
        }

        skipWhitespaceAndComments(in: input, at: &index)

        let keyStart = index
        while index < input.endIndex {
            let char = input[index]
            if char == ","
                || (openingDelimiter == "{" && char == closingDelimiter)
                || char.isWhitespace
                || char == "%" {
                break
            }
            input.formIndex(after: &index)
        }

        guard keyStart != index else {
            throw Error.missingCitationKey(
                entryType: typeName,
                position: offset(of: keyStart, in: input)
            )
        }

        let citationKey = String(input[keyStart..<index])
        skipWhitespaceAndComments(in: input, at: &index)

        guard index < input.endIndex else {
            throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
        }

        if input[index] == closingDelimiter {
            input.formIndex(after: &index)
            return makeEntry(
                typeName: typeName,
                citationKey: citationKey,
                fields: [:],
                rawRange: entryStart..<index,
                input: input
            )
        }

        guard input[index] == "," else {
            throw Error.unexpectedCharacter(
                character: input[index],
                position: offset(of: index, in: input)
            )
        }
        input.formIndex(after: &index)

        var fields: [String: String] = [:]
        var seenFieldNames: Set<String> = []

        while true {
            skipWhitespaceAndComments(in: input, at: &index)

            guard index < input.endIndex else {
                throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
            }

            if input[index] == closingDelimiter {
                input.formIndex(after: &index)
                break
            }

            let fieldStart = index
            guard isIdentifierStartCharacter(input[index]) else {
                throw Error.unexpectedCharacter(
                    character: input[index],
                    position: offset(of: index, in: input)
                )
            }
            while index < input.endIndex && isIdentifierCharacter(input[index]) {
                input.formIndex(after: &index)
            }

            var fieldName = String(input[fieldStart..<index])
            if options.normalizeFieldNames {
                fieldName = fieldName.lowercased()
            }

            skipWhitespaceAndComments(in: input, at: &index)

            guard index < input.endIndex else {
                throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
            }

            guard input[index] == "=" else {
                throw Error.unexpectedCharacter(
                    character: input[index],
                    position: offset(of: index, in: input)
                )
            }
            input.formIndex(after: &index)

            skipWhitespaceAndComments(in: input, at: &index)
            var processedValue = try parseFieldValue(
                from: input,
                at: &index,
                fieldName: fieldName,
                outerClosingDelimiter: closingDelimiter,
                stringConstants: stringConstants
            )

            if options.stripDelimiters {
                processedValue = trimmingBoundaryWhitespace(from: processedValue)
            }
            if options.convertLaTeXToUnicode && mayContainLaTeXSyntax(processedValue) {
                processedValue = LaTeXConverter.toUnicode(
                    processedValue,
                    preservingGroupingBraces: true
                )
            }

            if seenFieldNames.insert(fieldName.lowercased()).inserted {
                fields[fieldName] = processedValue
            }

            skipWhitespaceAndComments(in: input, at: &index)

            guard index < input.endIndex else {
                throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
            }

            if input[index] == "," {
                input.formIndex(after: &index)
            } else if input[index] != closingDelimiter {
                throw Error.unexpectedCharacter(
                    character: input[index],
                    position: offset(of: index, in: input)
                )
            }
        }

        return makeEntry(
            typeName: typeName,
            citationKey: citationKey,
            fields: fields,
            rawRange: entryStart..<index,
            input: input
        )
    }

    private func parsePreambleDirective(
        from input: String,
        at index: inout String.Index,
        closingDelimiter: Character,
        openingIndex: String.Index,
        stringConstants: [String: String]
    ) throws {
        skipWhitespaceAndComments(in: input, at: &index)

        _ = try parseFieldValue(
            from: input,
            at: &index,
            fieldName: "preamble",
            outerClosingDelimiter: closingDelimiter,
            stringConstants: stringConstants
        )

        skipWhitespaceAndComments(in: input, at: &index)
        guard index < input.endIndex else {
            throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
        }
        guard input[index] == closingDelimiter else {
            throw Error.unexpectedCharacter(
                character: input[index],
                position: offset(of: index, in: input)
            )
        }
        input.formIndex(after: &index)
    }

    private func parseStringDirective(
        from input: String,
        at index: inout String.Index,
        closingDelimiter: Character,
        openingIndex: String.Index,
        stringConstants: inout [String: String]
    ) throws {
        skipWhitespaceAndComments(in: input, at: &index)

        guard index < input.endIndex else {
            throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
        }

        let nameStart = index
        guard isIdentifierStartCharacter(input[index]) else {
            throw Error.invalidFieldValue(
                field: "string",
                position: offset(of: index, in: input)
            )
        }
        while index < input.endIndex && isIdentifierCharacter(input[index]) {
            input.formIndex(after: &index)
        }

        let name = String(input[nameStart..<index]).lowercased()
        skipWhitespaceAndComments(in: input, at: &index)

        guard index < input.endIndex else {
            throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
        }
        guard input[index] == "=" else {
            throw Error.unexpectedCharacter(
                character: input[index],
                position: offset(of: index, in: input)
            )
        }
        input.formIndex(after: &index)
        skipWhitespaceAndComments(in: input, at: &index)

        var value = try parseFieldValue(
            from: input,
            at: &index,
            fieldName: name,
            outerClosingDelimiter: closingDelimiter,
            stringConstants: stringConstants
        )
        if options.stripDelimiters {
            value = trimmingBoundaryWhitespace(from: value)
        }
        if options.convertLaTeXToUnicode && mayContainLaTeXSyntax(value) {
            value = LaTeXConverter.toUnicode(
                value,
                preservingGroupingBraces: true
            )
        }

        skipWhitespaceAndComments(in: input, at: &index)
        if index < input.endIndex && input[index] == "," {
            input.formIndex(after: &index)
            skipWhitespaceAndComments(in: input, at: &index)
        }

        guard index < input.endIndex else {
            throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
        }
        guard input[index] == closingDelimiter else {
            throw Error.unexpectedCharacter(
                character: input[index],
                position: offset(of: index, in: input)
            )
        }
        input.formIndex(after: &index)
        stringConstants[name] = value
    }

    private func parseFieldValue(
        from input: String,
        at index: inout String.Index,
        fieldName: String,
        outerClosingDelimiter: Character,
        stringConstants: [String: String]
    ) throws -> String {
        let valueStart = index
        var value = ""

        while true {
            skipWhitespaceAndComments(in: input, at: &index)

            guard index < input.endIndex,
                  input[index] != ",",
                  input[index] != outerClosingDelimiter else {
                throw Error.invalidFieldValue(
                    field: fieldName,
                    position: offset(of: valueStart, in: input)
                )
            }

            let component: String
            switch input[index] {
            case "\"":
                component = try parseQuotedString(
                    from: input,
                    at: &index,
                    fieldName: fieldName
                )
            case "{":
                component = try parseBracedString(from: input, at: &index)
            default:
                component = try parseBareValue(
                    from: input,
                    at: &index,
                    fieldName: fieldName,
                    stringConstants: stringConstants
                )
            }

            value.append(contentsOf: component)

            skipWhitespaceAndComments(in: input, at: &index)
            guard index < input.endIndex else {
                break
            }
            guard input[index] == "#" else {
                break
            }
            input.formIndex(after: &index)
        }

        return value
    }

    private func parseQuotedString(
        from input: String,
        at index: inout String.Index,
        fieldName: String
    ) throws -> String {
        let openingIndex = index
        input.formIndex(after: &index)
        let contentStart = index
        var braceDepth = 0

        while index < input.endIndex {
            let char = input[index]

            if char == "{" {
                braceDepth += 1
            } else if char == "}" {
                guard braceDepth > 0 else {
                    throw Error.invalidFieldValue(
                        field: fieldName,
                        position: offset(of: openingIndex, in: input)
                    )
                }
                braceDepth -= 1
            } else if char == "\"", braceDepth == 0 {
                let contentEnd = index
                input.formIndex(after: &index)
                return options.stripDelimiters
                    ? String(input[contentStart..<contentEnd])
                    : String(input[openingIndex..<index])
            }
            input.formIndex(after: &index)
        }

        throw Error.invalidFieldValue(
            field: fieldName,
            position: offset(of: openingIndex, in: input)
        )
    }

    private func parseBracedString(
        from input: String,
        at index: inout String.Index
    ) throws -> String {
        let openingIndex = index
        input.formIndex(after: &index)
        let contentStart = index
        var depth = 1

        while index < input.endIndex {
            let char = input[index]

            if char == "{" {
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0 {
                    let contentEnd = index
                    input.formIndex(after: &index)
                    return options.stripDelimiters
                        ? String(input[contentStart..<contentEnd])
                        : String(input[openingIndex..<index])
                }
            }
            input.formIndex(after: &index)
        }

        throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
    }

    private func parseBareValue(
        from input: String,
        at index: inout String.Index,
        fieldName: String,
        stringConstants: [String: String]
    ) throws -> String {
        let start = index

        if input[index].isNumber {
            while index < input.endIndex && input[index].isNumber {
                input.formIndex(after: &index)
            }
        } else if isIdentifierStartCharacter(input[index]) {
            while index < input.endIndex && isIdentifierCharacter(input[index]) {
                input.formIndex(after: &index)
            }
        } else {
            throw Error.invalidFieldValue(
                field: fieldName,
                position: offset(of: index, in: input)
            )
        }

        let rawValue = String(input[start..<index])
        if let constant = stringConstants[rawValue.lowercased()] {
            return constant
        }
        if let month = expandedMonth(named: rawValue) {
            return month
        }
        return rawValue
    }

    private func expandedMonth(named value: String) -> String? {
        switch value.lowercased() {
        case "jan": return "January"
        case "feb": return "February"
        case "mar": return "March"
        case "apr": return "April"
        case "may": return "May"
        case "jun": return "June"
        case "jul": return "July"
        case "aug": return "August"
        case "sep": return "September"
        case "oct": return "October"
        case "nov": return "November"
        case "dec": return "December"
        default: return nil
        }
    }

    private func skipBalancedBody(
        in input: String,
        at index: inout String.Index,
        openingDelimiter: Character,
        closingDelimiter: Character,
        openingIndex: String.Index
    ) throws {
        var depth = 1

        while index < input.endIndex {
            let char = input[index]

            if char == openingDelimiter {
                depth += 1
            } else if char == closingDelimiter {
                depth -= 1
                input.formIndex(after: &index)
                if depth == 0 {
                    return
                }
                continue
            }
            input.formIndex(after: &index)
        }

        throw Error.unmatchedBraces(position: offset(of: openingIndex, in: input))
    }

    private func makeEntry(
        typeName: String,
        citationKey: String,
        fields: [String: String],
        rawRange: Range<String.Index>,
        input: String
    ) -> BibTeXEntry {
        BibTeXEntry(
            type: BibTeXEntryType(rawValue: typeName),
            citationKey: citationKey,
            fields: fields,
            rawBibTeX: options.preserveRawBibTeX ? String(input[rawRange]) : nil
        )
    }

    private func trimmingBoundaryWhitespace(from value: String) -> String {
        var lowerBound = value.startIndex
        while lowerBound < value.endIndex, value[lowerBound].isWhitespace {
            value.formIndex(after: &lowerBound)
        }

        var upperBound = value.endIndex
        while upperBound > lowerBound {
            let previousIndex = value.index(before: upperBound)
            guard value[previousIndex].isWhitespace else { break }
            upperBound = previousIndex
        }

        return String(value[lowerBound..<upperBound])
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

    /// A low-cost preflight used to avoid invoking the converter for plain
    /// values. Internal visibility keeps this performance contract directly
    /// testable without making it part of the public API.
    func mayContainLaTeXSyntax(_ value: String) -> Bool {
        var previousByte: UInt8?

        for byte in value.utf8 {
            switch byte {
            case 0x5C, 0x60, 0x7B, 0x7D:
                return true
            case 0x27 where previousByte == byte:
                return true
            case 0x2D where previousByte == byte:
                return true
            default:
                previousByte = byte
            }
        }
        return false
    }

    private func offset(of index: String.Index, in input: String) -> Int {
        input.distance(from: input.startIndex, to: index)
    }
}
