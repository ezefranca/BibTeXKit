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
/// `BibTeXEntry` objects.
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
        
        /// No valid entries were found.
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
        
        /// Whether to convert LaTeX accents to Unicode.
        public var convertLaTeXToUnicode: Bool
        
        /// The default options.
        public static let `default` = Options()
        
        /// Options for strict parsing.
        public static let strict = Options(
            preserveRawBibTeX: true,
            normalizeFieldNames: true,
            stripDelimiters: true,
            convertLaTeXToUnicode: false
        )
        
        public init(
            preserveRawBibTeX: Bool = false,
            normalizeFieldNames: Bool = true,
            stripDelimiters: Bool = true,
            convertLaTeXToUnicode: Bool = true
        ) {
            self.preserveRawBibTeX = preserveRawBibTeX
            self.normalizeFieldNames = normalizeFieldNames
            self.stripDelimiters = stripDelimiters
            self.convertLaTeXToUnicode = convertLaTeXToUnicode
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
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw Error.emptyInput
        }
        
        var entries: [BibTeXEntry] = []
        var index = trimmed.startIndex
        
        while index < trimmed.endIndex {
            // Skip whitespace and comments
            index = skipWhitespaceAndComments(in: trimmed, from: index)
            
            guard index < trimmed.endIndex else { break }
            
            // Look for @ to start an entry
            if trimmed[index] == "@" {
                if let entry = try parseEntry(from: trimmed, startingAt: &index) {
                    entries.append(entry)
                }
            } else {
                index = trimmed.index(after: index)
            }
        }
        
        return entries
    }
    
    // MARK: - Private Methods
    
    private func skipWhitespaceAndComments(in input: String, from index: String.Index) -> String.Index {
        var current = index
        
        while current < input.endIndex {
            let char = input[current]
            
            if char.isWhitespace {
                current = input.index(after: current)
            } else if char == "%" {
                // Skip to end of line
                while current < input.endIndex && input[current] != "\n" {
                    current = input.index(after: current)
                }
            } else {
                break
            }
        }
        
        return current
    }
    
    private func parseEntry(from input: String, startingAt index: inout String.Index) throws -> BibTeXEntry? {
        let entryStart = index
        
        // Consume @
        guard input[index] == "@" else { return nil }
        index = input.index(after: index)
        
        // Parse entry type
        let typeStart = index
        while index < input.endIndex && input[index].isLetter {
            index = input.index(after: index)
        }
        
        let typeName = String(input[typeStart..<index])
        guard !typeName.isEmpty else {
            throw Error.invalidEntryType(position: input.distance(from: input.startIndex, to: typeStart))
        }
        
        let entryType = BibTeXEntryType(rawValue: typeName)
        
        // Skip whitespace
        index = skipWhitespaceAndComments(in: input, from: index)
        
        // Expect opening brace or parenthesis
        guard index < input.endIndex else {
            throw Error.missingOpeningBrace(position: input.distance(from: input.startIndex, to: index))
        }
        
        let openingBrace = input[index]
        guard openingBrace == "{" || openingBrace == "(" else {
            throw Error.missingOpeningBrace(position: input.distance(from: input.startIndex, to: index))
        }
        
        let closingBrace: Character = openingBrace == "{" ? "}" : ")"
        index = input.index(after: index)
        
        // Handle special entries (@preamble, @string, @comment)
        if typeName.lowercased() == "comment" {
            // Skip to closing brace
            var depth = 1
            while index < input.endIndex && depth > 0 {
                if input[index] == openingBrace { depth += 1 }
                if input[index] == closingBrace { depth -= 1 }
                index = input.index(after: index)
            }
            return nil
        }
        
        // Skip whitespace
        index = skipWhitespaceAndComments(in: input, from: index)
        
        // Parse citation key
        let keyStart = index
        while index < input.endIndex {
            let char = input[index]
            if char == "," || char == closingBrace || char.isWhitespace {
                break
            }
            index = input.index(after: index)
        }
        
        let citationKey = String(input[keyStart..<index]).trimmingCharacters(in: .whitespaces)
        
        if citationKey.isEmpty && typeName.lowercased() != "preamble" && typeName.lowercased() != "string" {
            throw Error.missingCitationKey(
                entryType: typeName,
                position: input.distance(from: input.startIndex, to: keyStart)
            )
        }
        
        // Skip whitespace and comma
        index = skipWhitespaceAndComments(in: input, from: index)
        if index < input.endIndex && input[index] == "," {
            index = input.index(after: index)
        }
        
        // Parse fields
        var fields: [String: String] = [:]
        
        while index < input.endIndex && input[index] != closingBrace {
            index = skipWhitespaceAndComments(in: input, from: index)
            
            guard index < input.endIndex && input[index] != closingBrace else { break }
            
            // Parse field name
            let fieldStart = index
            while index < input.endIndex {
                let char = input[index]
                if char == "=" || char.isWhitespace {
                    break
                }
                index = input.index(after: index)
            }
            
            var fieldName = String(input[fieldStart..<index])
            if options.normalizeFieldNames {
                fieldName = fieldName.lowercased()
            }
            
            guard !fieldName.isEmpty else {
                index = skipWhitespaceAndComments(in: input, from: index)
                if index < input.endIndex && input[index] == "," {
                    index = input.index(after: index)
                }
                continue
            }
            
            // Skip whitespace
            index = skipWhitespaceAndComments(in: input, from: index)
            
            // Expect =
            guard index < input.endIndex && input[index] == "=" else {
                continue
            }
            index = input.index(after: index)
            
            // Skip whitespace
            index = skipWhitespaceAndComments(in: input, from: index)
            
            // Parse field value
            let value = try parseFieldValue(from: input, at: &index, closingBrace: closingBrace)
            
            // Process value
            var processedValue = value
            if options.stripDelimiters {
                processedValue = stripDelimiters(from: processedValue)
            }
            if options.convertLaTeXToUnicode {
                processedValue = LaTeXConverter.toUnicode(processedValue)
            }
            
            fields[fieldName] = processedValue
            
            // Skip whitespace and comma
            index = skipWhitespaceAndComments(in: input, from: index)
            if index < input.endIndex && input[index] == "," {
                index = input.index(after: index)
            }
        }
        
        // Consume closing brace
        if index < input.endIndex && input[index] == closingBrace {
            index = input.index(after: index)
        }
        
        // Extract raw BibTeX if needed
        let rawBibTeX = options.preserveRawBibTeX
            ? String(input[entryStart..<index])
            : nil
        
        return BibTeXEntry(
            type: entryType,
            citationKey: citationKey,
            fields: fields,
            rawBibTeX: rawBibTeX
        )
    }
    
    private func parseFieldValue(
        from input: String,
        at index: inout String.Index,
        closingBrace: Character
    ) throws -> String {
        var value = ""
        
        while index < input.endIndex {
            let char = input[index]
            
            if char == "," || char == closingBrace {
                break
            } else if char == "\"" {
                // Quoted string
                value += parseQuotedString(from: input, at: &index)
            } else if char == "{" {
                // Braced string
                value += parseBracedString(from: input, at: &index)
            } else if char == "#" {
                // String concatenation
                index = input.index(after: index)
                index = skipWhitespaceAndComments(in: input, from: index)
            } else if char.isNumber {
                // Bare number
                value += parseNumber(from: input, at: &index)
            } else if char.isLetter {
                // String constant
                value += parseConstant(from: input, at: &index)
            } else if char.isWhitespace {
                index = input.index(after: index)
            } else {
                index = input.index(after: index)
            }
        }
        
        return value
    }
    
    private func parseQuotedString(from input: String, at index: inout String.Index) -> String {
        guard input[index] == "\"" else { return "" }
        
        var result = "\""
        index = input.index(after: index)
        var escaped = false
        
        while index < input.endIndex {
            let char = input[index]
            result.append(char)
            
            if escaped {
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "\"" {
                index = input.index(after: index)
                break
            }
            index = input.index(after: index)
        }
        
        return result
    }
    
    private func parseBracedString(from input: String, at index: inout String.Index) -> String {
        guard input[index] == "{" else { return "" }
        
        var result = "{"
        index = input.index(after: index)
        var depth = 1
        
        while index < input.endIndex && depth > 0 {
            let char = input[index]
            result.append(char)
            
            if char == "{" {
                depth += 1
            } else if char == "}" {
                depth -= 1
            }
            index = input.index(after: index)
        }
        
        return result
    }
    
    private func parseNumber(from input: String, at index: inout String.Index) -> String {
        var result = ""
        
        while index < input.endIndex && input[index].isNumber {
            result.append(input[index])
            index = input.index(after: index)
        }
        
        return result
    }
    
    private func parseConstant(from input: String, at index: inout String.Index) -> String {
        var result = ""
        
        while index < input.endIndex {
            let char = input[index]
            if char.isLetter || char.isNumber || char == "_" {
                result.append(char)
                index = input.index(after: index)
            } else {
                break
            }
        }
        
        // Expand known constants
        switch result.lowercased() {
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
        default: return result
        }
    }
    
    private func stripDelimiters(from value: String) -> String {
        var result = value.trimmingCharacters(in: .whitespaces)
        
        // Strip outer quotes
        if result.hasPrefix("\"") && result.hasSuffix("\"") && result.count >= 2 {
            result = String(result.dropFirst().dropLast())
            result = result.trimmingCharacters(in: .whitespaces)
        }
        
        // Strip outer braces
        if result.hasPrefix("{") && result.hasSuffix("}") && result.count >= 2 {
            result = String(result.dropFirst().dropLast())
            result = result.trimmingCharacters(in: .whitespaces)
        }
        
        return result
    }
}
