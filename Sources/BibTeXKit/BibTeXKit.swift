//
//  BibTeXKit.swift
//  BibTeXKit
//
//  A Swift framework for parsing, formatting, and displaying BibTeX entries.
//
//  Copyright © 2025. MIT License.
//

/// Release metadata for the BibTeXKit framework.
///
/// Most clients never need this namespace; import `BibTeXKit` and use its
/// parser, model, highlighting, and SwiftUI APIs directly.
///
/// ## Framework Overview
///
/// BibTeXKit offers:
/// - **Parsing**: Convert raw BibTeX strings into structured data
/// - **Formatting**: Generate properly formatted BibTeX output
/// - **Highlighting**: Apply syntax highlighting with configurable themes
/// - **Views**: Present BibTeX in SwiftUI across the supported platforms
///
/// ## Quick Start
///
/// ```swift
/// import BibTeXKit
///
/// let entries = try BibTeXParser.parse(bibtexString)
/// if let entry = entries.first {
///     BibTeXView(entry: entry)
///         .formattingStyle(.compact)
///         .copyButtonHidden()
/// }
/// ```
///
/// ## Topics
///
/// ### Parsing
/// - ``BibTeXParser``
/// - ``BibTeXEntry``
///
/// ### Display
/// - ``BibTeXView``
/// - ``BibTeXText``
///
/// ### Theming
/// - ``BibTeXTheme``
/// - ``BibTeXHighlighter``
public enum BibTeXKitMetadata {

    /// The current version of BibTeXKit.
    public static let version = "1.1.0"
}
