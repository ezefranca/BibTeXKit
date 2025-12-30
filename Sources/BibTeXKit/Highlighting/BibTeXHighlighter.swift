//
//  BibTeXHighlighter.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI

/// A syntax highlighter for BibTeX content.
///
/// `BibTeXHighlighter` converts BibTeX strings into styled `AttributedString`
/// suitable for display in SwiftUI views.
///
/// ## Usage
///
/// ```swift
/// let highlighter = BibTeXHighlighter(theme: MonokaiTheme())
/// let styled = highlighter.highlight(bibtexString)
///
/// Text(styled)
///     .textSelection(.enabled)
/// ```
///
/// ## Thread Safety
///
/// `BibTeXHighlighter` is fully thread-safe and can be used
/// from any thread or actor context.
public struct BibTeXHighlighter: Sendable {
    
    // MARK: - Properties
    
    /// The theme used for highlighting.
    public let theme: any BibTeXTheme
    
    /// The tokenizer instance.
    private let tokenizer = BibTeXTokenizer()
    
    // MARK: - Initialization
    
    /// Creates a new highlighter with a theme.
    ///
    /// - Parameter theme: The theme to use.
    public init(theme: any BibTeXTheme = DefaultLightTheme()) {
        self.theme = theme
    }
    
    /// Creates a highlighter that adapts to the color scheme.
    ///
    /// - Parameter colorScheme: The current color scheme.
    public init(colorScheme: ColorScheme) {
        self.theme = colorScheme == .dark ? DefaultDarkTheme() : DefaultLightTheme()
    }
    
    // MARK: - Public Methods
    
    /// Highlights a BibTeX string.
    ///
    /// - Parameter bibtex: The BibTeX string to highlight.
    /// - Returns: An `AttributedString` with syntax highlighting.
    public func highlight(_ bibtex: String) -> AttributedString {
        guard !bibtex.isEmpty else { return AttributedString() }
        
        let tokens = tokenizer.tokenize(bibtex)
        var result = AttributedString()
        
        for tokenInfo in tokens {
            var attributed = AttributedString(tokenInfo.text)
            attributed.font = theme.font
            attributed.foregroundColor = theme.color(for: tokenInfo.token)
            
            // Apply additional styling
            switch tokenInfo.token {
            case .entryType, .special:
                attributed.font = theme.font.bold()
            case .comment:
                attributed.font = theme.font.italic()
            default:
                break
            }
            
            result.append(attributed)
        }
        
        return result
    }
    
    /// Highlights a BibTeX entry.
    ///
    /// - Parameters:
    ///   - entry: The entry to highlight.
    ///   - style: The formatting style.
    /// - Returns: An `AttributedString` with syntax highlighting.
    public func highlight(
        entry: BibTeXEntry,
        style: BibTeXEntry.FormattingStyle = .standard
    ) -> AttributedString {
        highlight(entry.formatted(style: style))
    }
}

// MARK: - BibTeXEntry Extension

extension BibTeXEntry {
    
    /// Returns the formatted BibTeX with syntax highlighting.
    ///
    /// - Parameters:
    ///   - theme: The theme to use.
    ///   - style: The formatting style.
    /// - Returns: An `AttributedString` with syntax highlighting.
    public func highlighted(
        theme: any BibTeXTheme = DefaultLightTheme(),
        style: FormattingStyle = .standard
    ) -> AttributedString {
        let highlighter = BibTeXHighlighter(theme: theme)
        return highlighter.highlight(entry: self, style: style)
    }
    
    /// Returns the formatted BibTeX with syntax highlighting for a color scheme.
    ///
    /// - Parameters:
    ///   - colorScheme: The color scheme.
    ///   - style: The formatting style.
    /// - Returns: An `AttributedString` with syntax highlighting.
    public func highlighted(
        colorScheme: ColorScheme,
        style: FormattingStyle = .standard
    ) -> AttributedString {
        let highlighter = BibTeXHighlighter(colorScheme: colorScheme)
        return highlighter.highlight(entry: self, style: style)
    }
}
