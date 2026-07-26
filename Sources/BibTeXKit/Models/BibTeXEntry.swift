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
/// if let entry = entries.first {
///     // Use entry.
/// }
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
/// entry.title == "Example Paper"  // true
/// entry.authors == ["John Doe"]   // true
/// entry.year == 2024              // true
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
    
    /// A stable identifier preserved by value-style updates.
    ///
    /// Equality and hashing are content-based and do not use this value.
    public let id: UUID
    
    /// The type of this BibTeX entry.
    public let type: BibTeXEntryType
    
    /// The citation key used to reference this entry.
    public let citationKey: String
    
    /// The stored field values as key-value pairs.
    public private(set) var fields: [String: String]
    
    /// The original raw BibTeX string, if available.
    public let rawBibTeX: String?

    /// The case-folded key used by equality, hashing, and deterministic sorting.
    private let normalizedCitationKey: String
    
    // MARK: - Initialization
    
    /// Creates a new BibTeX entry.
    ///
    /// - Parameters:
    ///   - type: The entry type.
    ///   - citationKey: The citation key for referencing.
    ///   - fields: The field values.
    ///   - rawBibTeX: The original raw BibTeX string.
    ///   - id: The stable entry identity. Inject a value when deterministic
    ///     identity is required.
    public init(
        type: BibTeXEntryType,
        citationKey: String,
        fields: [String: String] = [:],
        rawBibTeX: String? = nil,
        id: UUID = UUID()
    ) {
        self.init(
            id: id,
            type: type,
            citationKey: citationKey,
            fields: fields,
            rawBibTeX: rawBibTeX
        )
    }

    private init(
        id: UUID,
        type: BibTeXEntryType,
        citationKey: String,
        fields: [String: String],
        rawBibTeX: String?
    ) {
        self.id = id
        self.type = type
        self.citationKey = citationKey
        self.fields = fields
        self.rawBibTeX = rawBibTeX
        self.normalizedCitationKey = citationKey.lowercased()
    }
    
    // MARK: - Subscript Access
    
    /// Accesses a field by name.
    ///
    /// - Parameter field: The field name (case-insensitive).
    /// - Returns: The field value, or `nil` if not present.
    public subscript(field: String) -> String? {
        get { value(forField: field) }
        set { setField(field, to: newValue) }
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

    /// The author field.
    ///
    /// This is an alias for ``authorString``.
    public var author: String? {
        authorString
    }
    
    /// The authors parsed into individual names.
    public var authors: [String] {
        guard let authorField = self["author"] else { return [] }
        return Self.parseAuthors(authorField)
    }
    
    /// The publication year as an integer.
    public var year: Int? {
        guard let yearString = self["year"] else { return nil }
        return Int(Self.trimmedSubstring(yearString))
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
        let trimmedURL = Self.trimmedSubstring(urlString)
        guard !trimmedURL.isEmpty else { return nil }
        return URL(string: String(trimmedURL))
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
        return Self.parseKeywords(keywordsField)
    }
    
    // MARK: - Validation
    
    /// Whether this entry has all required fields for its type.
    public var isValid: Bool {
        for field in type.requiredFields where !hasUsableValue(forField: field) {
            return false
        }

        for alternatives in type.requiredFieldAlternatives {
            var requirementSatisfied = false
            for field in alternatives where hasUsableValue(forField: field) {
                requirementSatisfied = true
                break
            }
            if !requirementSatisfied {
                return false
            }
        }

        return true
    }
    
    /// Returns the missing required fields for this entry type.
    public var missingRequiredFields: Set<String> {
        var missing: Set<String> = []
        missing.reserveCapacity(type.requiredFields.count)

        for field in type.requiredFields where !hasUsableValue(forField: field) {
            missing.insert(field)
        }

        for alternatives in type.requiredFieldAlternatives {
            var requirementSatisfied = false
            for field in alternatives where hasUsableValue(forField: field) {
                requirementSatisfied = true
                break
            }
            if !requirementSatisfied {
                missing.formUnion(alternatives)
            }
        }

        return missing
    }

    /// The result of validating an entry against its type metadata.
    public struct ValidationResult: Sendable, Equatable {
        /// Required field names that are absent or contain only whitespace.
        public let missingRequired: [String]

        /// Optional field names that are absent or contain only whitespace.
        public let missingOptional: [String]

        /// Unsatisfied groups where any one listed field would be sufficient.
        public let missingRequiredAlternatives: [[String]]

        /// Whether all required fields and alternative groups are satisfied.
        public var isValid: Bool {
            missingRequired.isEmpty
        }
    }

    /// Validates the entry and returns deterministic, alphabetically sorted
    /// diagnostics.
    public func validate() -> ValidationResult {
        var unsatisfiedAlternatives: [[String]] = []
        unsatisfiedAlternatives.reserveCapacity(type.requiredFieldAlternatives.count)
        for alternatives in type.requiredFieldAlternatives {
            var requirementSatisfied = false
            for field in alternatives where hasUsableValue(forField: field) {
                requirementSatisfied = true
                break
            }
            if !requirementSatisfied {
                unsatisfiedAlternatives.append(alternatives.sorted())
            }
        }
        unsatisfiedAlternatives.sort { $0.lexicographicallyPrecedes($1) }

        var missingOptional: [String] = []
        missingOptional.reserveCapacity(type.optionalFields.count)
        for field in type.optionalFields where !hasUsableValue(forField: field) {
            missingOptional.append(field)
        }
        missingOptional.sort()

        return ValidationResult(
            missingRequired: missingRequiredFields.sorted(),
            missingOptional: missingOptional,
            missingRequiredAlternatives: unsatisfiedAlternatives
        )
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
        copy.setField(field, to: value)
        return copy
    }
    
    /// Returns a copy with multiple fields updated.
    ///
    /// - Parameter newFields: The fields to update.
    /// - Returns: A new entry with the updated fields.
    public func settingFields(_ newFields: [String: String]) -> BibTeXEntry {
        let normalizedUpdates = Self.semanticFields(newFields)
        let updatedCanonicalNames = Set(normalizedUpdates.keys)

        var copy = self
        let replacedKeys = copy.fields.keys.filter {
            updatedCanonicalNames.contains($0.lowercased())
        }
        for key in replacedKeys {
            copy.fields.removeValue(forKey: key)
        }
        for (key, value) in normalizedUpdates {
            copy.fields[key] = value
        }
        return copy
    }

    /// Returns a copy with the specified field updated.
    public func with(field: String, value: String?) -> BibTeXEntry {
        settingField(field, to: value)
    }

    /// Returns a copy with multiple fields updated.
    public func with(fields: [String: String]) -> BibTeXEntry {
        settingFields(fields)
    }

    /// Returns a copy with a different citation key.
    public func with(key: String) -> BibTeXEntry {
        BibTeXEntry(
            id: id,
            type: type,
            citationKey: key,
            fields: fields,
            rawBibTeX: rawBibTeX
        )
    }

    /// Returns a copy with a different entry type.
    public func with(type: BibTeXEntryType) -> BibTeXEntry {
        BibTeXEntry(
            id: id,
            type: type,
            citationKey: citationKey,
            fields: fields,
            rawBibTeX: rawBibTeX
        )
    }
    
    // MARK: - Equatable (content-based)

    public static func == (lhs: BibTeXEntry, rhs: BibTeXEntry) -> Bool {
        lhs.type == rhs.type
        && lhs.normalizedCitationKey == rhs.normalizedCitationKey
        && (
            lhs.fields == rhs.fields
            || semanticFields(lhs.fields) == semanticFields(rhs.fields)
        )
    }

    // MARK: - Hashable (content-based)

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(normalizedCitationKey)

        let normalizedFields = Self.semanticFields(fields)
        hasher.combine(normalizedFields.count)
        for (key, value) in normalizedFields.sorted(
            by: { $0.key.lexicographicallyPrecedes($1.key) }
        ) {
            hasher.combine(key)
            hasher.combine(value)
        }
    }
}

// MARK: - Internal Field and Name Handling

private extension BibTeXEntry {
    func value(forField field: String) -> String? {
        fieldMatch(named: field)?.value
    }

    /// Finds a field without changing the spelling preserved in ``fields``.
    ///
    /// Lowercase field names win malformed case-collisions. Otherwise the
    /// lexicographically first spelling is selected, making the result
    /// independent of dictionary iteration order.
    func fieldMatch(named field: String) -> (key: String, value: String)? {
        let canonicalField = field.lowercased()
        if let value = fields[canonicalField] {
            return (canonicalField, value)
        }

        for (key, value) in fields.sorted(
            by: { $0.key.lexicographicallyPrecedes($1.key) }
        ) {
            if key.lowercased() == canonicalField {
                return (key, value)
            }
        }
        return nil
    }

    mutating func setField(_ field: String, to value: String?) {
        let canonicalField = field.lowercased()
        let matchingKeys = fields.keys.filter {
            $0.lowercased() == canonicalField
        }
        for key in matchingKeys {
            fields.removeValue(forKey: key)
        }
        if let value {
            fields[canonicalField] = value
        }
    }

    func hasUsableValue(forField field: String) -> Bool {
        guard let value = value(forField: field) else { return false }
        return value.contains { !$0.isWhitespace }
    }

    func citationField(_ field: String) -> String? {
        guard let value = value(forField: field) else { return nil }
        let trimmedValue = Self.trimmedSubstring(value)
        return trimmedValue.isEmpty ? nil : String(trimmedValue)
    }

    func firstParsedAuthor() -> String? {
        guard let authorField = value(forField: "author") else { return nil }
        return Self.firstAuthor(in: authorField)
    }

    static func semanticFields(_ fields: [String: String]) -> [String: String] {
        var normalizedFields: [String: String] = [:]
        normalizedFields.reserveCapacity(fields.count)

        for (key, value) in fields.sorted(
            by: { $0.key.lexicographicallyPrecedes($1.key) }
        ) {
            let canonicalKey = key.lowercased()
            if normalizedFields[canonicalKey] == nil || key == canonicalKey {
                normalizedFields[canonicalKey] = value
            }
        }
        return normalizedFields
    }

    func canonicalFieldIndex() -> [
        String: (key: String, value: String)
    ] {
        var index: [String: (key: String, value: String)] = [:]
        index.reserveCapacity(fields.count)

        for (key, value) in fields.sorted(
            by: { $0.key.lexicographicallyPrecedes($1.key) }
        ) {
            let canonicalKey = key.lowercased()

            if key == canonicalKey {
                index[canonicalKey] = (key, value)
                continue
            }

            if index[canonicalKey] == nil {
                index[canonicalKey] = (key, value)
            }
        }
        return index
    }

    static func trimmedSubstring(_ value: String) -> Substring {
        var lowerBound = value.startIndex
        while lowerBound < value.endIndex && value[lowerBound].isWhitespace {
            lowerBound = value.index(after: lowerBound)
        }

        var upperBound = value.endIndex
        while upperBound > lowerBound {
            let previousIndex = value.index(before: upperBound)
            guard value[previousIndex].isWhitespace else { break }
            upperBound = previousIndex
        }

        return value[lowerBound..<upperBound]
    }

    static func trimmedString(
        from value: String,
        in range: Range<String.Index>
    ) -> String? {
        var lowerBound = range.lowerBound
        while lowerBound < range.upperBound && value[lowerBound].isWhitespace {
            lowerBound = value.index(after: lowerBound)
        }

        var upperBound = range.upperBound
        while upperBound > lowerBound {
            let previousIndex = value.index(before: upperBound)
            guard value[previousIndex].isWhitespace else { break }
            upperBound = previousIndex
        }

        guard lowerBound < upperBound else { return nil }
        return String(value[lowerBound..<upperBound])
    }

    static func parseAuthors(_ value: String) -> [String] {
        var result: [String] = []
        result.reserveCapacity(2)
        forEachAuthor(in: value) {
            result.append($0)
            return true
        }
        return result
    }

    static func firstAuthor(in value: String) -> String? {
        var result: String?
        forEachAuthor(in: value) {
            result = $0
            return false
        }
        return result
    }

    static func forEachAuthor(
        in value: String,
        _ body: (String) -> Bool
    ) {
        var segmentStart = value.startIndex
        var index = value.startIndex
        var braceDepth = 0
        var isEscaped = false

        while index < value.endIndex {
            let character = value[index]

            if isEscaped {
                isEscaped = false
                index = value.index(after: index)
                continue
            }

            if character == "\\" {
                isEscaped = true
                index = value.index(after: index)
                continue
            }

            if character == "{" {
                braceDepth += 1
            } else if character == "}", braceDepth > 0 {
                braceDepth -= 1
            } else if braceDepth == 0,
                      let delimiterEnd = authorDelimiterEnd(
                        in: value,
                        at: index,
                        segmentStart: segmentStart
                      ) {
                if let author = trimmedString(
                    from: value,
                    in: segmentStart..<index
                ) {
                    guard body(author) else { return }
                }

                segmentStart = delimiterEnd
                index = delimiterEnd
                continue
            }

            index = value.index(after: index)
        }

        if let author = trimmedString(
            from: value,
            in: segmentStart..<value.endIndex
        ) {
            _ = body(author)
        }
    }

    static func authorDelimiterEnd(
        in value: String,
        at index: String.Index,
        segmentStart: String.Index
    ) -> String.Index? {
        guard index > segmentStart else { return nil }
        let previousIndex = value.index(before: index)
        guard value[previousIndex].isWhitespace else { return nil }

        switch value[index] {
        case "a", "A":
            break
        default:
            return nil
        }

        let secondIndex = value.index(after: index)
        guard secondIndex < value.endIndex else { return nil }
        switch value[secondIndex] {
        case "n", "N":
            break
        default:
            return nil
        }

        let thirdIndex = value.index(after: secondIndex)
        guard thirdIndex < value.endIndex else { return nil }
        switch value[thirdIndex] {
        case "d", "D":
            break
        default:
            return nil
        }

        let delimiterEnd = value.index(after: thirdIndex)
        guard delimiterEnd < value.endIndex,
              value[delimiterEnd].isWhitespace else {
            return nil
        }
        return value.index(after: delimiterEnd)
    }

    static func parseKeywords(_ value: String) -> [String] {
        splitTopLevelComponents(in: value, separators: ",;")
    }

    static func splitTopLevelComponents(
        in value: String,
        separators: String
    ) -> [String] {
        var result: [String] = []
        result.reserveCapacity(2)

        var segmentStart = value.startIndex
        var index = value.startIndex
        var braceDepth = 0
        var isEscaped = false

        while index < value.endIndex {
            let character = value[index]

            if isEscaped {
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else if character == "{" {
                braceDepth += 1
            } else if character == "}", braceDepth > 0 {
                braceDepth -= 1
            } else if braceDepth == 0, separators.contains(character) {
                if let component = trimmedString(
                    from: value,
                    in: segmentStart..<index
                ) {
                    result.append(component)
                }
                segmentStart = value.index(after: index)
            }

            index = value.index(after: index)
        }

        if let component = trimmedString(
            from: value,
            in: segmentStart..<value.endIndex
        ) {
            result.append(component)
        }
        return result
    }

    static func formatIEEEAuthor(_ author: String) -> String {
        let components = splitTopLevelComponents(in: author, separators: ",")
        guard components.count >= 2, let givenNames = components.last else {
            return author
        }

        var initials = ""
        for name in givenNames.split(whereSeparator: \.isWhitespace) {
            guard let initial = name.first(where: { $0.isLetter || $0.isNumber }) else {
                continue
            }
            if !initials.isEmpty {
                initials.append(" ")
            }
            initials.append(initial)
            initials.append(".")
        }
        guard !initials.isEmpty else { return author }

        var result = initials
        result.append(" ")
        result.append(contentsOf: components[0])

        for suffix in components.dropFirst().dropLast() {
            result.append(contentsOf: ", ")
            result.append(contentsOf: suffix)
        }
        return result
    }

    static func appendCitationPart(_ part: String, to citation: inout String) {
        if !citation.isEmpty {
            citation.append(" ")
        }
        citation.append(contentsOf: part)
    }

    static func doiReference(_ doi: String) -> String {
        DOIDetector.doiURL(for: doi)?.absoluteString ?? doi
    }
}

// MARK: - Formatting

extension BibTeXEntry {
    
    /// Style options for formatting BibTeX output.
    public struct FormattingStyle: Sendable, Equatable {
        fileprivate enum Layout: Sendable, Equatable {
            case multiline
            case compact
            case minimal
        }
        
        /// The preferred order of fields in the output.
        public let fieldOrder: [String]
        
        /// Whether to include all fields or only ordered ones.
        public let includeUnorderedFields: Bool
        
        /// The indentation string.
        public let indentation: String
        
        /// Whether to align equals signs.
        public let alignEquals: Bool

        /// Canonical field names used internally for case-insensitive ordering.
        fileprivate let normalizedFieldOrder: [String]

        /// The whitespace layout used by the built-in style.
        fileprivate let layout: Layout
        
        /// Creates a custom formatting style.
        public init(
            fieldOrder: [String] = Self.standardFieldOrder,
            includeUnorderedFields: Bool = true,
            indentation: String = "    ",
            alignEquals: Bool = false
        ) {
            self.init(
                fieldOrder: fieldOrder,
                includeUnorderedFields: includeUnorderedFields,
                indentation: indentation,
                alignEquals: alignEquals,
                layout: .multiline
            )
        }

        private init(
            fieldOrder: [String],
            includeUnorderedFields: Bool,
            indentation: String,
            alignEquals: Bool,
            layout: Layout
        ) {
            self.fieldOrder = fieldOrder
            self.includeUnorderedFields = includeUnorderedFields
            self.indentation = indentation
            self.alignEquals = alignEquals
            self.layout = layout

            var normalizedFieldOrder: [String] = []
            normalizedFieldOrder.reserveCapacity(fieldOrder.count)
            var seenFields: Set<String> = []
            seenFields.reserveCapacity(fieldOrder.count)

            for field in fieldOrder {
                let normalizedField = field.lowercased()
                if seenFields.insert(normalizedField).inserted {
                    normalizedFieldOrder.append(normalizedField)
                }
            }
            self.normalizedFieldOrder = normalizedFieldOrder
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
        
        /// A lossless single-line style with readable separators.
        public static let compact = FormattingStyle(
            fieldOrder: standardFieldOrder,
            includeUnorderedFields: true,
            indentation: "",
            alignEquals: false,
            layout: .compact
        )
        
        /// A lossless single-line style with no optional whitespace.
        public static let minimal = FormattingStyle(
            fieldOrder: standardFieldOrder,
            includeUnorderedFields: true,
            indentation: "",
            alignEquals: false,
            layout: .minimal
        )
        
        /// An aligned style with equal signs aligned.
        public static let aligned = FormattingStyle(alignEquals: true)
    }
    
    /// Returns the formatted BibTeX string.
    ///
    /// - Parameter style: The formatting style to use.
    /// - Returns: A properly formatted BibTeX string.
    public func formatted(style: FormattingStyle = .standard) -> String {
        let rawType = type.rawValue
        let usesParenthesizedEntry = citationKey.contains("{") || citationKey.contains("}")
        let openingDelimiter: Character = usesParenthesizedEntry ? "(" : "{"
        let fieldIndex = canonicalFieldIndex()
        var orderedFields: [(key: String, value: String)] = []
        orderedFields.reserveCapacity(fieldIndex.count)
        var emittedFieldNames: Set<String> = []
        emittedFieldNames.reserveCapacity(fieldIndex.count)
        var maximumKeyLength = 0

        for field in style.normalizedFieldOrder {
            if let match = fieldIndex[field] {
                orderedFields.append(match)
                emittedFieldNames.insert(field)
                maximumKeyLength = max(maximumKeyLength, match.key.count)
            }
        }

        if style.includeUnorderedFields {
            var remainingFields: [(canonicalKey: String, key: String, value: String)] = []
            remainingFields.reserveCapacity(fieldIndex.count - orderedFields.count)

            for (canonicalKey, field) in fieldIndex {
                guard !emittedFieldNames.contains(canonicalKey) else { continue }
                remainingFields.append((canonicalKey, field.key, field.value))
            }

            remainingFields.sort {
                $0.canonicalKey.lexicographicallyPrecedes($1.canonicalKey)
            }

            for field in remainingFields {
                orderedFields.append((field.key, field.value))
                emittedFieldNames.insert(field.canonicalKey)
                maximumKeyLength = max(maximumKeyLength, field.key.count)
            }
        }

        var output = ""
        output.append("@")
        output.append(contentsOf: rawType)
        output.append(openingDelimiter)
        output.append(contentsOf: citationKey)

        guard !orderedFields.isEmpty else {
            if usesParenthesizedEntry {
                output.append(",")
                output.append(")")
            } else {
                output.append("}")
            }
            return output
        }

        if style.layout != .multiline {
            let readable = style.layout == .compact
            output.append(contentsOf: readable ? ", " : ",")

            for index in orderedFields.indices {
                let field = orderedFields[index]
                output.append(contentsOf: field.key)
                output.append(contentsOf: readable ? " = {" : "={")
                output.append(contentsOf: field.value)
                output.append("}")
                if index != orderedFields.index(before: orderedFields.endIndex) {
                    output.append(contentsOf: readable ? ", " : ",")
                }
            }

            if usesParenthesizedEntry {
                output.append(")")
            } else {
                output.append("}")
            }
            return output
        }

        output.append(contentsOf: ",\n")

        for index in orderedFields.indices {
            let field = orderedFields[index]
            output.append(contentsOf: style.indentation)
            output.append(contentsOf: field.key)

            if style.alignEquals {
                let paddingCount = maximumKeyLength - field.key.count
                for _ in 0..<paddingCount {
                    output.append(" ")
                }
            }

            output.append(contentsOf: " = {")
            output.append(contentsOf: field.value)
            output.append("}")
            output.append(contentsOf: index == orderedFields.index(before: orderedFields.endIndex)
                ? "\n"
                : ",\n")
        }

        if usesParenthesizedEntry {
            output.append(")")
        } else {
            output.append("}")
        }
        return output
    }
}

// MARK: - Citation Formatting

extension BibTeXEntry {
    
    /// A lightweight citation-summary convention.
    ///
    /// These cases produce concise, Markdown-flavored display strings inspired
    /// by the named style families. They are not complete implementations of
    /// the corresponding publication manuals or a replacement for a CSL
    /// processor.
    public enum CitationStyle: String, Sendable, CaseIterable {
        case apa = "APA"
        case mla = "MLA"
        case chicago = "Chicago"
        case ieee = "IEEE"
        case harvard = "Harvard"
    }
    
    /// Returns a lightweight, Markdown-flavored citation summary.
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
        var citation = ""
        citation.reserveCapacity(128)

        if let authors = formatAuthorsAPA() {
            Self.appendCitationPart(authors, to: &citation)
        }

        if let year = citationField("year") {
            Self.appendCitationPart("(\(year)).", to: &citation)
        }

        if let title = citationField("title") {
            Self.appendCitationPart("\(title).", to: &citation)
        }

        if let journal = citationField("journal") {
            var journalPart = "*\(journal)*"
            if let volume = citationField("volume") {
                journalPart += ", *\(volume)*"
                if let number = citationField("number") {
                    journalPart += "(\(number))"
                }
            }
            if let pages = citationField("pages") {
                journalPart += ", \(pages)"
            }
            journalPart.append(".")
            Self.appendCitationPart(journalPart, to: &citation)
        }

        if let doi = citationField("doi") {
            Self.appendCitationPart(Self.doiReference(doi), to: &citation)
        }

        return citation
    }
    
    private func formatMLACitation() -> String {
        var citation = ""
        citation.reserveCapacity(128)

        if let authors = formatAuthorsAPA() {
            Self.appendCitationPart("\(authors).", to: &citation)
        }

        if let title = citationField("title") {
            Self.appendCitationPart("\"\(title).\"", to: &citation)
        }

        if let journal = citationField("journal") {
            Self.appendCitationPart("*\(journal)*,", to: &citation)
        }

        if let volume = citationField("volume") {
            Self.appendCitationPart("vol. \(volume),", to: &citation)
        }

        if let number = citationField("number") {
            Self.appendCitationPart("no. \(number),", to: &citation)
        }

        if let year = citationField("year") {
            Self.appendCitationPart("\(year),", to: &citation)
        }

        if let pages = citationField("pages") {
            Self.appendCitationPart("pp. \(pages).", to: &citation)
        }

        return citation
    }
    
    private func formatChicagoCitation() -> String {
        var citation = ""
        citation.reserveCapacity(128)

        if let authors = formatAuthorsAPA() {
            Self.appendCitationPart("\(authors).", to: &citation)
        }

        if let title = citationField("title") {
            Self.appendCitationPart("\"\(title).\"", to: &citation)
        }

        if let journal = citationField("journal") {
            var publication = "*\(journal)*"
            if let volume = citationField("volume") {
                publication.append(" ")
                publication.append(contentsOf: volume)
            }
            if let number = citationField("number") {
                publication.append(contentsOf: ", no. ")
                publication.append(contentsOf: number)
            }
            if let year = citationField("year") {
                publication.append(contentsOf: " (")
                publication.append(contentsOf: year)
                publication.append(")")
            }
            if let pages = citationField("pages") {
                publication.append(contentsOf: ": ")
                publication.append(contentsOf: pages)
            }
            publication.append(".")
            Self.appendCitationPart(publication, to: &citation)
        } else {
            if let year = citationField("year") {
                Self.appendCitationPart("(\(year)).", to: &citation)
            }
            if let pages = citationField("pages") {
                Self.appendCitationPart("\(pages).", to: &citation)
            }
        }

        return citation
    }
    
    private func formatIEEECitation() -> String {
        var citation = ""
        citation.reserveCapacity(128)

        let authorList = authors
        if !authorList.isEmpty {
            var formattedAuthors = ""
            for author in authorList {
                if !formattedAuthors.isEmpty {
                    formattedAuthors.append(contentsOf: ", ")
                }
                formattedAuthors.append(contentsOf: Self.formatIEEEAuthor(author))
            }
            Self.appendCitationPart(formattedAuthors, to: &citation)
        }

        if let title = citationField("title") {
            Self.appendCitationPart("\"\(title),\"", to: &citation)
        }

        if let journal = citationField("journal") {
            Self.appendCitationPart("*\(journal)*,", to: &citation)
        }

        if let volume = citationField("volume") {
            Self.appendCitationPart("vol. \(volume),", to: &citation)
        }

        if let number = citationField("number") {
            Self.appendCitationPart("no. \(number),", to: &citation)
        }

        if let pages = citationField("pages") {
            Self.appendCitationPart("pp. \(pages),", to: &citation)
        }

        if let year = citationField("year") {
            Self.appendCitationPart("\(year).", to: &citation)
        }

        return citation
    }
    
    private func formatHarvardCitation() -> String {
        var citation = ""
        citation.reserveCapacity(128)

        if let authors = formatAuthorsAPA() {
            Self.appendCitationPart(authors, to: &citation)
        }

        if let year = citationField("year") {
            Self.appendCitationPart("(\(year))", to: &citation)
        }

        if let title = citationField("title") {
            Self.appendCitationPart("'\(title)',", to: &citation)
        }

        if let journal = citationField("journal") {
            Self.appendCitationPart("*\(journal)*,", to: &citation)
        }

        if let volume = citationField("volume") {
            Self.appendCitationPart("vol. \(volume),", to: &citation)
        }

        if let number = citationField("number") {
            Self.appendCitationPart("no. \(number),", to: &citation)
        }

        if let pages = citationField("pages") {
            Self.appendCitationPart("pp. \(pages).", to: &citation)
        }

        return citation
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            type: try container.decode(BibTeXEntryType.self, forKey: .type),
            citationKey: try container.decode(String.self, forKey: .citationKey),
            fields: try container.decode([String: String].self, forKey: .fields),
            rawBibTeX: try container.decodeIfPresent(String.self, forKey: .rawBibTeX)
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(citationKey, forKey: .citationKey)
        try container.encode(fields, forKey: .fields)
        try container.encodeIfPresent(rawBibTeX, forKey: .rawBibTeX)
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
        switch (lhs.year, rhs.year) {
        case (let lhsYear?, let rhsYear?):
            if let decision = ascendingDecision(rhsYear, lhsYear) {
                return decision
            }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        default:
            break
        }

        let lhsAuthor = lhs.firstParsedAuthor() ?? ""
        let rhsAuthor = rhs.firstParsedAuthor() ?? ""
        if let decision = ascendingDecision(lhsAuthor, rhsAuthor) {
            return decision
        }

        let lhsTitle = lhs.title ?? ""
        let rhsTitle = rhs.title ?? ""
        if let decision = ascendingDecision(lhsTitle, rhsTitle) {
            return decision
        }

        if let decision = ascendingDecision(
            lhs.normalizedCitationKey,
            rhs.normalizedCitationKey
        ) {
            return decision
        }

        if let decision = ascendingDecision(
            lhs.type.sortingRank,
            rhs.type.sortingRank
        ) {
            return decision
        }

        let lhsTypeName = lhs.type.rawValue.lowercased()
        let rhsTypeName = rhs.type.rawValue.lowercased()
        if let decision = ascendingDecision(lhsTypeName, rhsTypeName) {
            return decision
        }

        let lhsFields = semanticFields(lhs.fields).sorted {
            $0.key.lexicographicallyPrecedes($1.key)
        }
        let rhsFields = semanticFields(rhs.fields).sorted {
            $0.key.lexicographicallyPrecedes($1.key)
        }

        var lhsIndex = lhsFields.startIndex
        var rhsIndex = rhsFields.startIndex
        while lhsIndex < lhsFields.endIndex && rhsIndex < rhsFields.endIndex {
            let lhsField = lhsFields[lhsIndex]
            let rhsField = rhsFields[rhsIndex]
            if let decision = ascendingDecision(lhsField.key, rhsField.key) {
                return decision
            }

            if let decision = ascendingDecision(lhsField.value, rhsField.value) {
                return decision
            }

            lhsIndex = lhsFields.index(after: lhsIndex)
            rhsIndex = rhsFields.index(after: rhsIndex)
        }

        if let decision = ascendingDecision(lhsFields.count, rhsFields.count) {
            return decision
        }
        return false
    }

    /// Produces an ordering decision without assuming the operands differ.
    ///
    /// Returning `nil` for equal values lets callers continue to their next
    /// deterministic tie-breaker.
    private static func ascendingDecision<Value: Comparable>(
        _ lhs: Value,
        _ rhs: Value
    ) -> Bool? {
        if lhs < rhs {
            return true
        }
        if rhs < lhs {
            return false
        }
        return nil
    }
}
