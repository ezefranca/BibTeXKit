//
//  BibTeXEntry.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// A structured representation of a BibTeX entry.
///
/// `BibTeXEntry` provides a type-safe way to work with BibTeX data,
/// including access to individual fields and formatted output.
///
/// ## Creating Entries
///
/// Parse from a raw BibTeX string:
///
/// ```swift
/// let entries = try BibTeXParser.parse(bibtexString)
/// let entry = entries.first!
/// ```
///
/// Or create programmatically:
///
/// ```swift
/// let entry = BibTeXEntry(
///     type: .article,
///     citationKey: "doe2024",
///     fields: [
///         "author": "John Doe",
///         "title": "Example Paper",
///         "year": "2024"
///     ]
/// )
/// ```
///
/// ## Accessing Fields
///
/// Use convenience properties for common fields:
///
/// ```swift
/// entry.title      // "Example Paper"
/// entry.authors    // ["John Doe"]
/// entry.year       // 2025
/// ```
///
/// Or access any field by name:
///
/// ```swift
/// entry["journal"]  // Optional field value
/// entry["doi"]      // nil if not present
/// ```
public struct BibTeXEntry: Identifiable, Hashable, Sendable, Equatable {
    
    // MARK: - Properties
    
    /// A unique identifier for this entry instance.
    public let id: UUID
    
    /// The type of this BibTeX entry.
    public let type: BibTeXEntryType
    
    /// The citation key used to reference this entry.
    public let citationKey: String
    
    /// The raw field values as key-value pairs.
    public private(set) var fields: [String: String]
    
    /// The original raw BibTeX string, if available.
    public let rawBibTeX: String?
    
    // MARK: - Initialization
    
    /// Creates a new BibTeX entry.
    ///
    /// - Parameters:
    ///   - type: The entry type.
    ///   - citationKey: The citation key for referencing.
    ///   - fields: The field values.
    ///   - rawBibTeX: The original raw BibTeX string.
    public init(
        type: BibTeXEntryType,
        citationKey: String,
        fields: [String: String] = [:],
        rawBibTeX: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.citationKey = citationKey
        self.fields = fields
        self.rawBibTeX = rawBibTeX
    }
    
    // MARK: - Subscript Access
    
    /// Accesses a field by name.
    ///
    /// - Parameter field: The field name (case-insensitive).
    /// - Returns: The field value, or `nil` if not present.
    public subscript(field: String) -> String? {
        get { fields[field.lowercased()] }
        set { fields[field.lowercased()] = newValue }
    }
    
    // MARK: - Convenience Accessors
    
    /// The title of the work.
    public var title: String? {
        self["title"]
    }
    
    /// The authors as a formatted string.
    public var authorString: String? {
        self["author"]
    }
    
    /// The authors parsed into individual names.
    public var authors: [String] {
        guard let authorField = self["author"] else { return [] }
        return authorField
            .components(separatedBy: " and ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// The publication year as an integer.
    public var year: Int? {
        guard let yearString = self["year"] else { return nil }
        return Int(yearString)
    }
    
    /// The publication year as a string.
    public var yearString: String? {
        self["year"]
    }
    
    /// The DOI if available.
    public var doi: String? {
        self["doi"]
    }
    
    /// The journal name.
    public var journal: String? {
        self["journal"]
    }
    
    /// The book title (for book chapters or proceedings).
    public var booktitle: String? {
        self["booktitle"]
    }
    
    /// The publisher name.
    public var publisher: String? {
        self["publisher"]
    }
    
    /// The volume number.
    public var volume: String? {
        self["volume"]
    }
    
    /// The issue number.
    public var number: String? {
        self["number"]
    }
    
    /// The page range.
    public var pages: String? {
        self["pages"]
    }
    
    /// The URL if available.
    public var url: URL? {
        guard let urlString = self["url"] else { return nil }
        return URL(string: urlString)
    }
    
    /// The abstract if available.
    public var abstract: String? {
        self["abstract"]
    }
    
    /// The month of publication.
    public var month: String? {
        self["month"]
    }
    
    /// Keywords associated with the entry.
    public var keywords: [String] {
        guard let keywordsField = self["keywords"] else { return [] }
        return keywordsField
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Validation
    
    /// Whether this entry has all required fields for its type.
    public var isValid: Bool {
        type.requiredFields.allSatisfy { fields[$0] != nil }
    }
    
    /// Returns the missing required fields for this entry type.
    public var missingRequiredFields: Set<String> {
        type.requiredFields.subtracting(Set(fields.keys))
    }
    
    // MARK: - Mutation
    
    /// Returns a copy with the specified field updated.
    ///
    /// - Parameters:
    ///   - field: The field name.
    ///   - value: The new value, or `nil` to remove.
    /// - Returns: A new entry with the updated field.
    public func settingField(_ field: String, to value: String?) -> BibTeXEntry {
        var copy = self
        copy.fields[field.lowercased()] = value
        return copy
    }
    
    /// Returns a copy with multiple fields updated.
    ///
    /// - Parameter newFields: The fields to update.
    /// - Returns: A new entry with the updated fields.
    public func settingFields(_ newFields: [String: String]) -> BibTeXEntry {
        var copy = self
        for (key, value) in newFields {
            copy.fields[key.lowercased()] = value
        }
        return copy
    }
    
    // MARK: - Equatable (content-based)

    public static func == (lhs: BibTeXEntry, rhs: BibTeXEntry) -> Bool {
        lhs.type == rhs.type
        && lhs.citationKey.lowercased() == rhs.citationKey.lowercased()
        && lhs.fields == rhs.fields
    }

    // MARK: - Hashable (content-based, stable)

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(citationKey.lowercased())

        for key in fields.keys.sorted() {
            hasher.combine(key)
            hasher.combine(fields[key] ?? "")
        }
    }
}

// MARK: - Formatting

extension BibTeXEntry {
    
    /// Style options for formatting BibTeX output.
    public struct FormattingStyle: Sendable, Equatable {
        
        /// The preferred order of fields in the output.
        public let fieldOrder: [String]
        
        /// Whether to include all fields or only ordered ones.
        public let includeUnorderedFields: Bool
        
        /// The indentation string.
        public let indentation: String
        
        /// Whether to align equals signs.
        public let alignEquals: Bool
        
        /// Creates a custom formatting style.
        public init(
            fieldOrder: [String] = Self.standardFieldOrder,
            includeUnorderedFields: Bool = true,
            indentation: String = "    ",
            alignEquals: Bool = false
        ) {
            self.fieldOrder = fieldOrder
            self.includeUnorderedFields = includeUnorderedFields
            self.indentation = indentation
            self.alignEquals = alignEquals
        }
        
        /// Standard field ordering.
        public static let standardFieldOrder = [
            "author", "title", "journal", "booktitle", "year",
            "volume", "number", "pages", "month", "publisher",
            "address", "edition", "editor", "series", "chapter",
            "school", "institution", "organization", "howpublished",
            "doi", "url", "isbn", "issn", "note", "abstract", "keywords"
        ]
        
        /// The standard formatting style.
        public static let standard = FormattingStyle()
        
        /// A compact style with fewer fields.
        public static let compact = FormattingStyle(
            fieldOrder: ["author", "title", "year", "doi", "url"],
            includeUnorderedFields: false
        )
        
        /// A minimal style with only essential fields.
        public static let minimal = FormattingStyle(
            fieldOrder: ["author", "title", "year"],
            includeUnorderedFields: false
        )
        
        /// An aligned style with equal signs aligned.
        public static let aligned = FormattingStyle(alignEquals: true)
    }
    
    /// Returns the formatted BibTeX string.
    ///
    /// - Parameter style: The formatting style to use.
    /// - Returns: A properly formatted BibTeX string.
    public func formatted(style: FormattingStyle = .standard) -> String {
        var output = "@\(type.rawValue){\(citationKey)"
        
        // Collect fields in order
        var orderedFields: [(key: String, value: String)] = []
        
        for field in style.fieldOrder {
            if let value = fields[field] {
                orderedFields.append((field, value))
            }
        }
        
        // Add remaining fields if requested
        if style.includeUnorderedFields {
            let remainingFields = fields
                .filter { !style.fieldOrder.contains($0.key) }
                .sorted { $0.key < $1.key }
            orderedFields.append(contentsOf: remainingFields.map { ($0.key, $0.value) })
        }
        
        guard !orderedFields.isEmpty else {
            return output + "}"
        }
        
        output += ",\n"
        
        // Calculate max key length for alignment
        let maxKeyLength = style.alignEquals
            ? orderedFields.map(\.key.count).max() ?? 0
            : 0
        
        for (index, (key, value)) in orderedFields.enumerated() {
            let isLast = index == orderedFields.count - 1
            let paddedKey = style.alignEquals
                ? key.padding(toLength: maxKeyLength, withPad: " ", startingAt: 0)
                : key
            
            output += "\(style.indentation)\(paddedKey) = {\(value)}"
            output += isLast ? "\n" : ",\n"
        }
        
        output += "}"
        return output
    }
}

// MARK: - Citation Formatting

extension BibTeXEntry {
    
    /// Citation style for plain text output.
    public enum CitationStyle: String, Sendable, CaseIterable {
        case apa = "APA"
        case mla = "MLA"
        case chicago = "Chicago"
        case ieee = "IEEE"
        case harvard = "Harvard"
    }
    
    /// Returns a plain text citation.
    ///
    /// - Parameter style: The citation style to use.
    /// - Returns: A formatted citation string.
    public func citation(style: CitationStyle = .apa) -> String {
        switch style {
        case .apa:
            return formatAPACitation()
        case .mla:
            return formatMLACitation()
        case .chicago:
            return formatChicagoCitation()
        case .ieee:
            return formatIEEECitation()
        case .harvard:
            return formatHarvardCitation()
        }
    }
    
    private func formatAPACitation() -> String {
        var parts: [String] = []
        
        if let authors = formatAuthorsAPA() {
            parts.append(authors)
        }
        
        if let year = yearString {
            parts.append("(\(year)).")
        }
        
        if let title = title {
            parts.append("\(title).")
        }
        
        if let journal = journal {
            var journalPart = "*\(journal)*"
            if let volume = volume {
                journalPart += ", *\(volume)*"
                if let number = number {
                    journalPart += "(\(number))"
                }
            }
            if let pages = pages {
                journalPart += ", \(pages)"
            }
            parts.append(journalPart + ".")
        }
        
        if let doi = doi {
            parts.append("https://doi.org/\(doi)")
        }
        
        return parts.joined(separator: " ")
    }
    
    private func formatMLACitation() -> String {
        var parts: [String] = []
        
        if let authors = formatAuthorsAPA() {
            parts.append("\(authors).")
        }
        
        if let title = title {
            parts.append("\"\(title).\"")
        }
        
        if let journal = journal {
            parts.append("*\(journal)*,")
        }
        
        if let volume = volume {
            parts.append("vol. \(volume),")
        }
        
        if let number = number {
            parts.append("no. \(number),")
        }
        
        if let year = yearString {
            parts.append("\(year),")
        }
        
        if let pages = pages {
            parts.append("pp. \(pages).")
        }
        
        return parts.joined(separator: " ")
    }
    
    private func formatChicagoCitation() -> String {
        var parts: [String] = []
        
        if let authors = formatAuthorsAPA() {
            parts.append("\(authors).")
        }
        
        if let title = title {
            parts.append("\"\(title).\"")
        }
        
        if let journal = journal {
            parts.append("*\(journal)*")
        }
        
        if let volume = volume, let number = number {
            parts.append("\(volume), no. \(number)")
        }
        
        if let year = yearString {
            parts.append("(\(year))")
        }
        
        if let pages = pages {
            parts.append(": \(pages).")
        }
        
        return parts.joined(separator: " ")
    }
    
    private func formatIEEECitation() -> String {
        var parts: [String] = []
        
        let authorList = authors
        if !authorList.isEmpty {
            let formatted = authorList.enumerated().map { index, author -> String in
                let components = author.components(separatedBy: ", ")
                if components.count >= 2 {
                    let initials = components[1].split(separator: " ").map { "\($0.first ?? Character(" "))." }.joined(separator: " ")
                    return "\(initials) \(components[0])"
                }
                return author
            }
            parts.append(formatted.joined(separator: ", "))
        }
        
        if let title = title {
            parts.append("\"\(title),\"")
        }
        
        if let journal = journal {
            parts.append("*\(journal)*,")
        }
        
        if let volume = volume {
            parts.append("vol. \(volume),")
        }
        
        if let number = number {
            parts.append("no. \(number),")
        }
        
        if let pages = pages {
            parts.append("pp. \(pages),")
        }
        
        if let year = yearString {
            parts.append("\(year).")
        }
        
        return parts.joined(separator: " ")
    }
    
    private func formatHarvardCitation() -> String {
        var parts: [String] = []
        
        if let authors = formatAuthorsAPA() {
            parts.append(authors)
        }
        
        if let year = yearString {
            parts.append("(\(year))")
        }
        
        if let title = title {
            parts.append("'\(title)',")
        }
        
        if let journal = journal {
            parts.append("*\(journal)*,")
        }
        
        if let volume = volume {
            parts.append("vol. \(volume),")
        }
        
        if let number = number {
            parts.append("no. \(number),")
        }
        
        if let pages = pages {
            parts.append("pp. \(pages).")
        }
        
        return parts.joined(separator: " ")
    }
    
    private func formatAuthorsAPA() -> String? {
        let authorList = authors
        guard !authorList.isEmpty else { return nil }
        
        switch authorList.count {
        case 1:
            return authorList[0]
        case 2:
            return "\(authorList[0]) & \(authorList[1])"
        default:
            return "\(authorList[0]) et al."
        }
    }
}

// MARK: - Codable

extension BibTeXEntry: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, type, citationKey, fields, rawBibTeX
    }
}

// MARK: - CustomStringConvertible

extension BibTeXEntry: CustomStringConvertible {
    public var description: String {
        formatted()
    }
}

// MARK: - Comparable

extension BibTeXEntry: Comparable {
    public static func < (lhs: BibTeXEntry, rhs: BibTeXEntry) -> Bool {
        if let lhsYear = lhs.year, let rhsYear = rhs.year, lhsYear != rhsYear {
            return lhsYear > rhsYear
        }
        if let lhsAuthor = lhs.authors.first, let rhsAuthor = rhs.authors.first, lhsAuthor != rhsAuthor {
            return lhsAuthor < rhsAuthor
        }
        return (lhs.title ?? "") < (rhs.title ?? "")
    }
}
