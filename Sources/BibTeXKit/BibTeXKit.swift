//
//  BibTeXKit.swift
//  BibTeXKit
//
//  A Swift framework for parsing, formatting, and displaying BibTeX entries.
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// BibTeXKit is a Swift framework for working with BibTeX data.
///
/// BibTeXKit provides comprehensive tools for parsing, formatting, and
/// displaying BibTeX entries with beautiful syntax highlighting.
///
/// ## Overview
///
/// BibTeXKit offers:
/// - **Parsing**: Convert raw BibTeX strings into structured data
/// - **Formatting**: Generate properly formatted BibTeX output
/// - **Highlighting**: Beautiful syntax highlighting with customizable themes
/// - **Views**: SwiftUI views that work on all Apple platforms
///
/// ## Quick Start
///
/// ```swift
/// import BibTeXKit
///
/// // Parse a BibTeX string
/// let entry = try BibTeXParser.parse(bibtexString).first
///
/// // Display with syntax highlighting
/// BibTeXView(entry)
///     .bibTeXStyle(.compact)
///     .copyButtonHidden()
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
public enum BibTeXKit {
    
    /// The current version of BibTeXKit.
    public static let version = "1.0.0"
    
    /// The bundle identifier.
    public static let bundleIdentifier = "com.bibtexkit.framework"
}
