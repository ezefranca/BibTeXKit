//
//  BibTeXToken.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// A token recognized by the BibTeX tokenizer.
///
/// These tokens represent the syntactic elements of BibTeX and LaTeX
/// that can be styled independently in syntax highlighting.
public enum BibTeXToken: String, Sendable, CaseIterable, Hashable {
    
    // MARK: - BibTeX Structure Tokens
    
    /// Entry type declaration (@article, @book, etc.)
    case entryType
    
    /// The citation key
    case citationKey
    
    /// Field name (author, title, year, etc.)
    case fieldName
    
    /// String value in quotes or braces
    case string
    
    /// Numeric value
    case number
    
    /// Operator (=, #)
    case `operator`
    
    /// Punctuation ({, }, (, ), ,)
    case punctuation
    
    /// Comment (% to end of line)
    case comment
    
    /// Special directives (@preamble, @string, @comment)
    case special
    
    /// String constant reference (e.g., jan, feb for months)
    case constant
    
    // MARK: - LaTeX Tokens
    
    /// LaTeX command (\command)
    case command
    
    /// LaTeX math mode ($...$)
    case math
    
    /// LaTeX environment (\begin{...} ... \end{...})
    case environment
    
    /// LaTeX accent commands (\'e, \"{o}, etc.)
    case accent
    
    /// LaTeX special characters (\&, \%, etc.)
    case specialChar
    
    // MARK: - Generic Tokens
    
    /// Whitespace
    case whitespace
    
    /// Plain text (default)
    case text
    
    // MARK: - Properties
    
    /// A human-readable description of the token type.
    public var description: String {
        switch self {
        case .entryType: return "Entry Type"
        case .citationKey: return "Citation Key"
        case .fieldName: return "Field Name"
        case .string: return "String Value"
        case .number: return "Number"
        case .operator: return "Operator"
        case .punctuation: return "Punctuation"
        case .comment: return "Comment"
        case .special: return "Special Directive"
        case .constant: return "Constant"
        case .command: return "LaTeX Command"
        case .math: return "Math Mode"
        case .environment: return "Environment"
        case .accent: return "Accent"
        case .specialChar: return "Special Character"
        case .whitespace: return "Whitespace"
        case .text: return "Text"
        }
    }
}

/// A positioned token with its text and location.
public struct BibTeXTokenInfo: Sendable, Equatable {
    
    /// The token type.
    public let token: BibTeXToken
    
    /// The text content.
    public let text: String
    
    /// The range in the original string.
    public let range: Range<String.Index>
    
    /// Creates a new token info.
    public init(token: BibTeXToken, text: String, range: Range<String.Index>) {
        self.token = token
        self.text = text
        self.range = range
    }
}
