//
//  BibTeXEntryType.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// The type of a BibTeX entry.
///
/// BibTeX supports various entry types for different publication kinds.
/// Each type has required and optional fields that determine what
/// information should be included.
///
/// ## Standard Types
///
/// ```swift
/// let article = BibTeXEntryType.article    // Journal articles
/// let book = BibTeXEntryType.book          // Books
/// let inproceedings = BibTeXEntryType.inproceedings  // Conference papers
/// ```
///
/// ## Custom Types
///
/// For non-standard types, use the ``custom(_:)`` case:
///
/// ```swift
/// let patent = BibTeXEntryType.custom("patent")
/// ```
public enum BibTeXEntryType: Hashable, Sendable {
    
    // MARK: - Standard Types
    
    /// An article from a journal or magazine.
    case article
    
    /// A book with an explicit publisher.
    case book
    
    /// A work that is printed and bound, but without a named publisher.
    case booklet
    
    /// A part of a book, usually with its own title.
    case inbook
    
    /// A part of a book having its own title.
    case incollection
    
    /// An article in conference proceedings.
    case inproceedings
    
    /// A conference paper.
    ///
    /// This case uses the same field metadata as ``inproceedings`` but remains
    /// a distinct enum case.
    case conference
    
    /// Technical documentation.
    case manual
    
    /// A Master's thesis.
    case mastersthesis
    
    /// A Ph.D. thesis.
    case phdthesis
    
    /// Conference proceedings.
    case proceedings
    
    /// A report published by an institution.
    case techreport
    
    /// A document not formally published.
    case unpublished
    
    /// Anything that doesn't fit other types.
    case misc
    
    /// An online resource (BibLaTeX).
    case online
    
    /// Software or code (BibLaTeX).
    case software
    
    /// A dataset (BibLaTeX).
    case dataset
    
    /// A custom or unknown entry type.
    case custom(String)

    private enum HashDomain: Hashable {
        case standard
        case custom
    }

    // MARK: - Equality and Hashing

    /// Compares custom entry types using BibTeX's case-insensitive type
    /// semantics while keeping standard and explicitly custom cases distinct.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.custom(lhsValue), .custom(rhsValue)):
            lhsValue.lowercased() == rhsValue.lowercased()
        case (.custom, _), (_, .custom):
            false
        default:
            lhs.rawValue == rhs.rawValue
        }
    }

    /// Hashes custom entry types using the same case-insensitive identity used
    /// by ``==(_:_:)``.
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .custom(let value):
            hasher.combine(HashDomain.custom)
            hasher.combine(value.lowercased())
        default:
            hasher.combine(HashDomain.standard)
            hasher.combine(rawValue)
        }
    }
    
    // MARK: - Initialization
    
    /// Creates an entry type from a raw string.
    ///
    /// - Parameter rawValue: The BibTeX entry type string.
    public init(rawValue: String) {
        switch rawValue.lowercased() {
        case "article": self = .article
        case "book": self = .book
        case "booklet": self = .booklet
        case "inbook": self = .inbook
        case "incollection": self = .incollection
        case "inproceedings": self = .inproceedings
        case "conference": self = .conference
        case "manual": self = .manual
        case "mastersthesis": self = .mastersthesis
        case "phdthesis": self = .phdthesis
        case "proceedings": self = .proceedings
        case "techreport": self = .techreport
        case "unpublished": self = .unpublished
        case "misc": self = .misc
        case "online": self = .online
        case "software": self = .software
        case "dataset": self = .dataset
        default: self = .custom(rawValue)
        }
    }
    
    // MARK: - Properties
    
    /// The raw BibTeX string for this entry type.
    public var rawValue: String {
        switch self {
        case .article: return "article"
        case .book: return "book"
        case .booklet: return "booklet"
        case .inbook: return "inbook"
        case .incollection: return "incollection"
        case .inproceedings: return "inproceedings"
        case .conference: return "conference"
        case .manual: return "manual"
        case .mastersthesis: return "mastersthesis"
        case .phdthesis: return "phdthesis"
        case .proceedings: return "proceedings"
        case .techreport: return "techreport"
        case .unpublished: return "unpublished"
        case .misc: return "misc"
        case .online: return "online"
        case .software: return "software"
        case .dataset: return "dataset"
        case .custom(let value): return value
        }
    }
    
    /// A human-readable description of the entry type.
    public var localizedDescription: String {
        switch self {
        case .article: return "Journal article"
        case .book: return "Book"
        case .booklet: return "Booklet"
        case .inbook: return "Book section"
        case .incollection: return "Book chapter"
        case .inproceedings, .conference: return "Conference paper"
        case .manual: return "Manual"
        case .mastersthesis: return "Master's thesis"
        case .phdthesis: return "PhD thesis"
        case .proceedings: return "Proceedings"
        case .techreport: return "Technical report"
        case .unpublished: return "Unpublished"
        case .misc: return "Miscellaneous"
        case .online: return "Online resource"
        case .software: return "Software"
        case .dataset: return "Dataset"
        case .custom(let value): return value.capitalized
        }
    }
    
    /// The SF Symbol name for this entry type.
    public var symbolName: String {
        switch self {
        case .article: return "doc.text"
        case .book, .inbook: return "book"
        case .booklet: return "doc"
        case .incollection: return "books.vertical"
        case .inproceedings, .conference, .proceedings: return "person.3"
        case .manual: return "wrench.and.screwdriver"
        case .mastersthesis, .phdthesis: return "graduationcap"
        case .techreport: return "doc.badge.gearshape"
        case .unpublished: return "doc.badge.clock"
        case .misc: return "doc.questionmark"
        case .online: return "globe"
        case .software: return "chevron.left.forwardslash.chevron.right"
        case .dataset: return "tablecells"
        case .custom: return "doc"
        }
    }
    
    /// The required fields for this entry type.
    ///
    /// This set contains fields that are unconditionally required. See
    /// ``requiredFieldAlternatives`` for requirements where any one field in
    /// a group is sufficient.
    public var requiredFields: Set<String> {
        switch self {
        case .article:
            return FieldMetadata.articleRequired
        case .book:
            return FieldMetadata.bookRequired
        case .booklet:
            return FieldMetadata.bookletRequired
        case .inbook:
            return FieldMetadata.inbookRequired
        case .incollection:
            return FieldMetadata.incollectionRequired
        case .inproceedings, .conference:
            return FieldMetadata.inproceedingsRequired
        case .manual:
            return FieldMetadata.manualRequired
        case .mastersthesis, .phdthesis:
            return FieldMetadata.thesisRequired
        case .proceedings:
            return FieldMetadata.proceedingsRequired
        case .techreport:
            return FieldMetadata.techreportRequired
        case .unpublished:
            return FieldMetadata.unpublishedRequired
        case .misc, .online, .software, .dataset, .custom:
            return FieldMetadata.none
        }
    }

    /// Groups of interchangeable required fields.
    ///
    /// An entry satisfies a group when at least one non-empty field in that
    /// group is present. Standard BibTeX permits `author` or `editor` for a
    /// book, and additionally permits `chapter` or `pages` for an in-book
    /// entry.
    public var requiredFieldAlternatives: [Set<String>] {
        switch self {
        case .book:
            return FieldMetadata.bookRequiredAlternatives
        case .inbook:
            return FieldMetadata.inbookRequiredAlternatives
        default:
            return FieldMetadata.noAlternatives
        }
    }
    
    /// The optional fields for this entry type.
    ///
    /// Classic types include BibTeX's `key` fallback field. The special
    /// `crossref` inheritance directive is intentionally excluded because
    /// entry-local validation does not resolve relationships between entries.
    public var optionalFields: Set<String> {
        switch self {
        case .article:
            return FieldMetadata.articleOptional
        case .book:
            return FieldMetadata.bookOptional
        case .booklet:
            return FieldMetadata.bookletOptional
        case .inbook:
            return FieldMetadata.inbookOptional
        case .incollection:
            return FieldMetadata.incollectionOptional
        case .inproceedings, .conference:
            return FieldMetadata.inproceedingsOptional
        case .manual:
            return FieldMetadata.manualOptional
        case .mastersthesis, .phdthesis:
            return FieldMetadata.thesisOptional
        case .proceedings:
            return FieldMetadata.proceedingsOptional
        case .techreport:
            return FieldMetadata.techreportOptional
        case .unpublished:
            return FieldMetadata.unpublishedOptional
        case .misc:
            return FieldMetadata.miscOptional
        case .online:
            return FieldMetadata.onlineOptional
        case .software:
            return FieldMetadata.softwareOptional
        case .dataset:
            return FieldMetadata.datasetOptional
        case .custom:
            return FieldMetadata.none
        }
    }
    
    /// All known standard entry types.
    public static let allStandardTypes: [BibTeXEntryType] = {
        [.article, .book, .booklet, .inbook, .incollection, .inproceedings,
         .conference, .manual, .mastersthesis, .phdthesis, .proceedings,
         .techreport, .unpublished, .misc, .online, .software, .dataset]
    }()

    /// A stable discriminator used to provide deterministic entry ordering.
    internal var sortingRank: Int {
        switch self {
        case .article: 0
        case .book: 1
        case .booklet: 2
        case .inbook: 3
        case .incollection: 4
        case .inproceedings: 5
        case .conference: 6
        case .manual: 7
        case .mastersthesis: 8
        case .phdthesis: 9
        case .proceedings: 10
        case .techreport: 11
        case .unpublished: 12
        case .misc: 13
        case .online: 14
        case .software: 15
        case .dataset: 16
        case .custom: 17
        }
    }
}

// MARK: - Field Metadata

private extension BibTeXEntryType {
    /// Shared immutable sets avoid rebuilding hash tables for every validation.
    enum FieldMetadata {
        static let none: Set<String> = []

        static let articleRequired: Set<String> = ["author", "title", "journal", "year"]
        static let bookRequired: Set<String> = ["title", "publisher", "year"]
        static let bookletRequired: Set<String> = ["title"]
        static let inbookRequired: Set<String> = ["title", "publisher", "year"]
        static let incollectionRequired: Set<String> = ["author", "title", "booktitle", "publisher", "year"]
        static let inproceedingsRequired: Set<String> = ["author", "title", "booktitle", "year"]
        static let manualRequired: Set<String> = ["title"]
        static let thesisRequired: Set<String> = ["author", "title", "school", "year"]
        static let proceedingsRequired: Set<String> = ["title", "year"]
        static let techreportRequired: Set<String> = ["author", "title", "institution", "year"]
        static let unpublishedRequired: Set<String> = ["author", "title", "note"]

        static let noAlternatives: [Set<String>] = []
        static let bookRequiredAlternatives: [Set<String>] = [
            ["author", "editor"]
        ]
        static let inbookRequiredAlternatives: [Set<String>] = [
            ["author", "editor"],
            ["chapter", "pages"]
        ]

        static let articleOptional: Set<String> = [
            "volume", "number", "pages", "month", "doi", "url", "note",
            "abstract", "keywords", "key"
        ]
        static let bookOptional: Set<String> = [
            "volume", "number", "series", "address", "edition", "month",
            "doi", "url", "note", "abstract", "keywords", "key"
        ]
        static let bookletOptional: Set<String> = [
            "author", "howpublished", "address", "month", "year", "note", "key"
        ]
        static let inbookOptional: Set<String> = [
            "volume", "number", "series", "type", "address", "edition",
            "month", "note", "key"
        ]
        static let incollectionOptional: Set<String> = [
            "editor", "volume", "number", "series", "type", "chapter",
            "pages", "address", "edition", "month", "note", "key"
        ]
        static let inproceedingsOptional: Set<String> = [
            "editor", "volume", "number", "series", "pages", "address",
            "month", "organization", "publisher", "note", "key"
        ]
        static let manualOptional: Set<String> = [
            "author", "organization", "address", "edition", "month", "year",
            "note", "key"
        ]
        static let thesisOptional: Set<String> = [
            "type", "address", "month", "note", "key"
        ]
        static let proceedingsOptional: Set<String> = [
            "editor", "volume", "number", "series", "address", "month",
            "organization", "publisher", "note", "key"
        ]
        static let techreportOptional: Set<String> = [
            "type", "number", "address", "month", "note", "key"
        ]
        static let unpublishedOptional: Set<String> = [
            "month", "year", "key"
        ]
        static let miscOptional: Set<String> = [
            "author", "title", "howpublished", "month", "year", "note", "url",
            "key"
        ]
        static let onlineOptional: Set<String> = [
            "author", "title", "url", "urldate", "year", "month", "note"
        ]
        static let softwareOptional: Set<String> = [
            "author", "title", "url", "version", "year", "month", "note"
        ]
        static let datasetOptional: Set<String> = [
            "author", "title", "url", "year", "publisher", "version", "note"
        ]
    }
}

// MARK: - Codable

extension BibTeXEntryType: Codable {
    private enum CodingKeys: String, CodingKey {
        case custom
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let customValue = try container.decodeIfPresent(
            String.self,
            forKey: .custom
           ) {
            self = .custom(customValue)
            return
        }

        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self.init(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        if case .custom(let value) = self,
           case .custom = BibTeXEntryType(rawValue: value) {
            var container = encoder.singleValueContainer()
            try container.encode(value)
            return
        } else if case .custom(let value) = self {
            // A tagged representation preserves an explicitly custom case
            // whose spelling collides with a standard type. Legacy strings
            // continue to decode as their standard case.
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value, forKey: .custom)
            return
        }

        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - CustomStringConvertible

extension BibTeXEntryType: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
