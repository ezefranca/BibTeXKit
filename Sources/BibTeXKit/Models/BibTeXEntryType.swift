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
/// let dataset = BibTeXEntryType.custom("dataset")
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
    
    /// An article in conference proceedings (alias for inproceedings).
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
    public var requiredFields: Set<String> {
        switch self {
        case .article:
            return ["author", "title", "journal", "year"]
        case .book:
            return ["author", "title", "publisher", "year"]
        case .booklet:
            return ["title"]
        case .inbook:
            return ["author", "title", "chapter", "publisher", "year"]
        case .incollection:
            return ["author", "title", "booktitle", "publisher", "year"]
        case .inproceedings, .conference:
            return ["author", "title", "booktitle", "year"]
        case .manual:
            return ["title"]
        case .mastersthesis, .phdthesis:
            return ["author", "title", "school", "year"]
        case .proceedings:
            return ["title", "year"]
        case .techreport:
            return ["author", "title", "institution", "year"]
        case .unpublished:
            return ["author", "title", "note"]
        case .misc, .online, .software, .dataset, .custom:
            return []
        }
    }
    
    /// The optional fields for this entry type.
    public var optionalFields: Set<String> {
        switch self {
        case .article:
            return ["volume", "number", "pages", "month", "doi", "url", "note", "abstract", "keywords"]
        case .book:
            return ["volume", "number", "series", "address", "edition", "month", "doi", "url", "note", "abstract", "keywords", "editor"]
        case .booklet:
            return ["author", "howpublished", "address", "month", "year", "note"]
        case .inbook:
            return ["volume", "number", "series", "type", "address", "edition", "month", "pages", "note"]
        case .incollection:
            return ["editor", "volume", "number", "series", "type", "chapter", "pages", "address", "edition", "month", "note"]
        case .inproceedings, .conference:
            return ["editor", "volume", "number", "series", "pages", "address", "month", "organization", "publisher", "note"]
        case .manual:
            return ["author", "organization", "address", "edition", "month", "year", "note"]
        case .mastersthesis, .phdthesis:
            return ["type", "address", "month", "note"]
        case .proceedings:
            return ["editor", "volume", "number", "series", "address", "month", "organization", "publisher", "note"]
        case .techreport:
            return ["type", "number", "address", "month", "note"]
        case .unpublished:
            return ["month", "year"]
        case .misc:
            return ["author", "title", "howpublished", "month", "year", "note", "url"]
        case .online:
            return ["author", "title", "url", "urldate", "year", "month", "note"]
        case .software:
            return ["author", "title", "url", "version", "year", "month", "note"]
        case .dataset:
            return ["author", "title", "url", "year", "publisher", "version", "note"]
        case .custom:
            return []
        }
    }
    
    /// All known standard entry types.
    public static var allStandardTypes: [BibTeXEntryType] {
        [.article, .book, .booklet, .inbook, .incollection, .inproceedings,
         .conference, .manual, .mastersthesis, .phdthesis, .proceedings,
         .techreport, .unpublished, .misc, .online, .software, .dataset]
    }
}

// MARK: - Codable

extension BibTeXEntryType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self.init(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
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
