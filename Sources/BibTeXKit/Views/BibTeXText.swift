//
//  BibTeXText.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI

/// A simple inline text view for displaying BibTeX with syntax highlighting.
///
/// `BibTeXText` is a lightweight alternative to `BibTeXView` for inline
/// display without additional UI chrome like borders or copy buttons.
///
/// ## Usage
///
/// ```swift
/// BibTeXText(bibtex: myBibTeXString)
///     .font(.system(.body, design: .monospaced))
/// ```
///
/// For richer UI with copy buttons and metadata, use ``BibTeXView``.
public struct BibTeXText: View {
    
    // MARK: - Properties
    
    private let bibtex: String
    private let theme: (any BibTeXTheme)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initialization
    
    /// Creates a BibTeX text view.
    ///
    /// - Parameters:
    ///   - bibtex: The BibTeX string to display.
    ///   - theme: Optional explicit theme.
    public init(bibtex: String, theme: (any BibTeXTheme)? = nil) {
        self.bibtex = bibtex
        self.theme = theme
    }
    
    /// Creates a BibTeX text view from an entry.
    ///
    /// - Parameters:
    ///   - entry: The entry to display.
    ///   - style: The formatting style.
    ///   - theme: Optional explicit theme.
    public init(
        entry: BibTeXEntry,
        style: BibTeXEntry.FormattingStyle = .standard,
        theme: (any BibTeXTheme)? = nil
    ) {
        self.bibtex = entry.formatted(style: style)
        self.theme = theme
    }
    
    // MARK: - Body
    
    public var body: some View {
        let effectiveTheme = theme ?? (colorScheme == .dark ? DefaultDarkTheme() : DefaultLightTheme())
        let highlighter = BibTeXHighlighter(theme: effectiveTheme)
        
        Text(highlighter.highlight(bibtex))
            .textSelection(.enabled)
    }
}

// MARK: - View Modifiers

extension BibTeXText {
    
    /// Sets an explicit theme for highlighting.
    public func bibTeXTheme(_ theme: any BibTeXTheme) -> BibTeXText {
        BibTeXText(bibtex: bibtex, theme: theme)
    }
}

// MARK: - Preview

#if DEBUG
struct BibTeXText_Previews: PreviewProvider {
    static let sampleBibTeX = """
    @article{sample2024,
        author = {John Doe},
        title = {Sample Paper},
        year = {2024}
    }
    """
    
    static var previews: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Inline BibTeX:")
                .font(.headline)
            
            BibTeXText(bibtex: sampleBibTeX)
            
            Divider()
            
            Text("With Monokai theme:")
                .font(.headline)
            
            BibTeXText(bibtex: sampleBibTeX)
                .bibTeXTheme(MonokaiTheme())
        }
        .padding()
    }
}
#endif