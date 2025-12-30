//
//  BibTeXTheme.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI

/// A theme for BibTeX syntax highlighting.
///
/// Conform to this protocol to create custom themes for `BibTeXView`.
///
/// ## Built-in Themes
///
/// BibTeXKit includes several built-in themes:
///
/// - ``DefaultLightTheme``: Clean light theme
/// - ``DefaultDarkTheme``: Clean dark theme
/// - ``XcodeLightTheme``: Xcode-inspired light theme
/// - ``XcodeDarkTheme``: Xcode-inspired dark theme
/// - ``MonokaiTheme``: Popular dark theme
/// - ``SolarizedLightTheme``: Solarized light
/// - ``SolarizedDarkTheme``: Solarized dark
///
/// ## Custom Themes
///
/// Create a custom theme by conforming to `BibTeXTheme`:
///
/// ```swift
/// struct MyTheme: BibTeXTheme {
///     var backgroundColor: Color { .black }
///     var textColor: Color { .white }
///     var entryTypeColor: Color { .red }
///     // ... implement all required colors
/// }
/// ```
///
/// Then use it with `BibTeXView`:
///
/// ```swift
/// BibTeXView(entry)
///     .theme(MyTheme())
/// ```
public protocol BibTeXTheme: Sendable {
    
    // MARK: - Name
    var name: String { get }
    
    // MARK: - Background
    
    /// The background color for the code block.
    var backgroundColor: Color { get }
    
    // MARK: - BibTeX Syntax Colors
    
    /// Color for entry types (@article, @book, etc.)
    var entryTypeColor: Color { get }
    
    /// Color for citation keys.
    var citationKeyColor: Color { get }
    
    /// Color for field names (author, title, etc.)
    var fieldNameColor: Color { get }
    
    /// Color for string values.
    var stringColor: Color { get }
    
    /// Color for numbers.
    var numberColor: Color { get }
    
    /// Color for braces and punctuation.
    var punctuationColor: Color { get }
    
    /// Color for operators (=, #).
    var operatorColor: Color { get }
    
    /// Color for comments (%).
    var commentColor: Color { get }
    
    /// Color for special directives (@preamble, @string).
    var specialColor: Color { get }
    
    /// Color for constants (month names, etc.)
    var constantColor: Color { get }
    
    // MARK: - LaTeX Colors
    
    /// Color for LaTeX commands.
    var commandColor: Color { get }
    
    /// Color for math mode content.
    var mathColor: Color { get }
    
    /// Color for LaTeX accents.
    var accentColor: Color { get }
    
    // MARK: - Text
    
    /// Default text color.
    var textColor: Color { get }
    
    // MARK: - UI Colors
    
    /// Color for line numbers (if shown).
    var lineNumberColor: Color { get }
    
    /// Color for selection highlight.
    var selectionColor: Color { get }
    
    /// Color for border
    var borderColor: Color { get }
    
    // MARK: - Font
    
    /// The font to use for code display.
    var font: Font { get }
    
    /// The font size.
    var fontSize: CGFloat { get }
}

// MARK: - Default Implementations

extension BibTeXTheme {
    
    /// Default environment color (same as command color).
    public var environmentColor: Color { commandColor }
    
    /// Default special character color (same as accent color).
    public var specialCharColor: Color { accentColor }
    
    /// Returns the color for a specific token type.
    public func color(for token: BibTeXToken) -> Color {
        switch token {
        case .entryType: return entryTypeColor
        case .citationKey: return citationKeyColor
        case .fieldName: return fieldNameColor
        case .string: return stringColor
        case .number: return numberColor
        case .operator: return operatorColor
        case .punctuation: return punctuationColor
        case .comment: return commentColor
        case .special: return specialColor
        case .constant: return constantColor
        case .command: return commandColor
        case .math: return mathColor
        case .environment: return commandColor
        case .accent: return accentColor
        case .specialChar: return accentColor
        case .whitespace, .text: return textColor
        }
    }
}

// MARK: - Default Light Theme

/// The default light theme.
public struct DefaultLightTheme: BibTeXTheme {
    public var name: String { "Default Light" }
    
    public init() {}
    
    public var backgroundColor: Color { Color(.systemBackground) }
    public var textColor: Color { Color(.label) }
    public var entryTypeColor: Color { Color(.systemBlue) }
    public var citationKeyColor: Color { Color(.systemOrange) }
    public var fieldNameColor: Color { Color(.systemGreen) }
    public var stringColor: Color { Color(.systemRed) }
    public var numberColor: Color { Color(.systemPurple) }
    public var punctuationColor: Color { Color(.secondaryLabel) }
    public var operatorColor: Color { Color(.label) }
    public var commentColor: Color { Color(.tertiaryLabel) }
    public var specialColor: Color { Color(.systemPink) }
    public var constantColor: Color { Color(.systemTeal) }
    public var commandColor: Color { Color(.systemIndigo) }
    public var mathColor: Color { Color(.systemPurple) }
    public var accentColor: Color { Color(.systemBrown) }
    public var borderColor: Color { Color.primary }
    public var lineNumberColor: Color { Color(.tertiaryLabel) }
    public var selectionColor: Color { Color(.systemBlue).opacity(0.2) }
    public var font: Font { .system(.body, design: .monospaced) }
    public var fontSize: CGFloat { 13 }
}

// MARK: - Default Dark Theme

/// The default dark theme.
public struct DefaultDarkTheme: BibTeXTheme {
    public var name: String { "Default Dark" }
    
    public init() {}
    
    public var backgroundColor: Color { Color(red: 0.11, green: 0.11, blue: 0.12) }
    public var textColor: Color { Color(white: 0.9) }
    public var entryTypeColor: Color { Color(red: 0.35, green: 0.68, blue: 0.93) }
    public var citationKeyColor: Color { Color(red: 0.99, green: 0.78, blue: 0.47) }
    public var fieldNameColor: Color { Color(red: 0.54, green: 0.82, blue: 0.55) }
    public var stringColor: Color { Color(red: 0.99, green: 0.54, blue: 0.52) }
    public var numberColor: Color { Color(red: 0.83, green: 0.68, blue: 0.98) }
    public var punctuationColor: Color { Color(white: 0.7) }
    public var operatorColor: Color { Color(white: 0.9) }
    public var commentColor: Color { Color(white: 0.5) }
    public var specialColor: Color { Color(red: 0.99, green: 0.47, blue: 0.68) }
    public var constantColor: Color { Color(red: 0.40, green: 0.85, blue: 0.82) }
    public var commandColor: Color { Color(red: 0.73, green: 0.58, blue: 0.98) }
    public var mathColor: Color { Color(red: 0.83, green: 0.68, blue: 0.98) }
    public var accentColor: Color { Color(red: 0.85, green: 0.65, blue: 0.45) }
    public var borderColor: Color { Color.primary }
    public var lineNumberColor: Color { Color(white: 0.4) }
    public var selectionColor: Color { Color(.systemBlue).opacity(0.3) }
    public var font: Font { .system(.body, design: .monospaced) }
    public var fontSize: CGFloat { 13 }
}

// MARK: - Xcode Light Theme

/// An Xcode-inspired light theme.
public struct XcodeLightTheme: BibTeXTheme {
    public var name: String { "Xcode Light" }
    
    public init() {}
    
    public var backgroundColor: Color { .white }
    public var textColor: Color { .black }
    public var entryTypeColor: Color { Color(red: 0.61, green: 0.14, blue: 0.58) } // Purple
    public var citationKeyColor: Color { Color(red: 0.11, green: 0.00, blue: 0.81) } // Blue
    public var fieldNameColor: Color { Color(red: 0.26, green: 0.42, blue: 0.35) } // Green
    public var stringColor: Color { Color(red: 0.77, green: 0.10, blue: 0.09) } // Red
    public var numberColor: Color { Color(red: 0.11, green: 0.00, blue: 0.81) } // Blue
    public var punctuationColor: Color { .black }
    public var operatorColor: Color { .black }
    public var commentColor: Color { Color(red: 0.42, green: 0.47, blue: 0.44) } // Gray
    public var specialColor: Color { Color(red: 0.61, green: 0.14, blue: 0.58) }
    public var constantColor: Color { Color(red: 0.11, green: 0.00, blue: 0.81) }
    public var commandColor: Color { Color(red: 0.61, green: 0.14, blue: 0.58) }
    public var mathColor: Color { Color(red: 0.11, green: 0.00, blue: 0.81) }
    public var accentColor: Color { Color(red: 0.61, green: 0.14, blue: 0.58) }
    public var borderColor: Color { Color.primary }
    public var lineNumberColor: Color { Color(red: 0.67, green: 0.70, blue: 0.69) }
    public var selectionColor: Color { Color(red: 0.70, green: 0.84, blue: 1.0) }
    public var font: Font { .system(size: 13, design: .monospaced) }
    public var fontSize: CGFloat { 13 }
}

// MARK: - Xcode Dark Theme

/// An Xcode-inspired dark theme.
public struct XcodeDarkTheme: BibTeXTheme {
    public var name: String { "Xcode Dark" }
    
    public init() {}
    
    public var backgroundColor: Color { Color(red: 0.12, green: 0.12, blue: 0.14) }
    public var textColor: Color { .white }
    public var entryTypeColor: Color { Color(red: 0.99, green: 0.42, blue: 0.62) } // Pink
    public var citationKeyColor: Color { Color(red: 0.35, green: 0.76, blue: 0.93) } // Cyan
    public var fieldNameColor: Color { Color(red: 0.54, green: 0.82, blue: 0.47) } // Green
    public var stringColor: Color { Color(red: 0.99, green: 0.51, blue: 0.40) } // Orange
    public var numberColor: Color { Color(red: 0.82, green: 0.79, blue: 0.54) } // Yellow
    public var punctuationColor: Color { .white }
    public var operatorColor: Color { .white }
    public var commentColor: Color { Color(red: 0.42, green: 0.54, blue: 0.44) }
    public var specialColor: Color { Color(red: 0.99, green: 0.42, blue: 0.62) }
    public var constantColor: Color { Color(red: 0.82, green: 0.79, blue: 0.54) }
    public var commandColor: Color { Color(red: 0.99, green: 0.42, blue: 0.62) }
    public var mathColor: Color { Color(red: 0.82, green: 0.79, blue: 0.54) }
    public var accentColor: Color { Color(red: 0.99, green: 0.42, blue: 0.62) }
    public var borderColor: Color { Color.primary }
    public var lineNumberColor: Color { Color(red: 0.45, green: 0.50, blue: 0.54) }
    public var selectionColor: Color { Color(red: 0.24, green: 0.34, blue: 0.49) }
    public var font: Font { .system(size: 13, design: .monospaced) }
    public var fontSize: CGFloat { 13 }
}

// MARK: - Monokai Theme

/// A Monokai-inspired dark theme.
public struct MonokaiTheme: BibTeXTheme {
    public var name: String { "Monokai" }
    
    public init() {}
    
    public var backgroundColor: Color { Color(red: 0.15, green: 0.16, blue: 0.13) }
    public var textColor: Color { Color(red: 0.97, green: 0.97, blue: 0.95) }
    public var entryTypeColor: Color { Color(red: 0.98, green: 0.15, blue: 0.45) } // Red/Pink
    public var citationKeyColor: Color { Color(red: 0.90, green: 0.86, blue: 0.45) } // Yellow
    public var fieldNameColor: Color { Color(red: 0.40, green: 0.85, blue: 0.94) } // Cyan
    public var stringColor: Color { Color(red: 0.90, green: 0.86, blue: 0.45) } // Yellow
    public var numberColor: Color { Color(red: 0.68, green: 0.51, blue: 1.00) } // Purple
    public var punctuationColor: Color { Color(red: 0.97, green: 0.97, blue: 0.95) }
    public var operatorColor: Color { Color(red: 0.98, green: 0.15, blue: 0.45) }
    public var commentColor: Color { Color(red: 0.46, green: 0.44, blue: 0.37) }
    public var specialColor: Color { Color(red: 0.68, green: 0.51, blue: 1.00) }
    public var constantColor: Color { Color(red: 0.68, green: 0.51, blue: 1.00) }
    public var commandColor: Color { Color(red: 0.65, green: 0.89, blue: 0.18) } // Green
    public var mathColor: Color { Color(red: 0.68, green: 0.51, blue: 1.00) }
    public var accentColor: Color { Color(red: 0.98, green: 0.15, blue: 0.45) }
    public var borderColor: Color { Color.primary }
    public var lineNumberColor: Color { Color(red: 0.46, green: 0.44, blue: 0.37) }
    public var selectionColor: Color { Color(red: 0.28, green: 0.29, blue: 0.24) }
    public var font: Font { .system(size: 13, design: .monospaced) }
    public var fontSize: CGFloat { 13 }
}

// MARK: - Solarized Light Theme

/// A Solarized Light theme.
public struct SolarizedLightTheme: BibTeXTheme {
    public var name: String { "Solarized Light" }
    
    public init() {}
    
    public var backgroundColor: Color { Color(red: 0.99, green: 0.96, blue: 0.89) }
    public var textColor: Color { Color(red: 0.40, green: 0.48, blue: 0.51) }
    public var entryTypeColor: Color { Color(red: 0.15, green: 0.55, blue: 0.82) } // Blue
    public var citationKeyColor: Color { Color(red: 0.80, green: 0.29, blue: 0.09) } // Orange
    public var fieldNameColor: Color { Color(red: 0.52, green: 0.60, blue: 0.00) } // Green
    public var stringColor: Color { Color(red: 0.16, green: 0.63, blue: 0.60) } // Cyan
    public var numberColor: Color { Color(red: 0.71, green: 0.54, blue: 0.00) } // Yellow
    public var punctuationColor: Color { Color(red: 0.40, green: 0.48, blue: 0.51) }
    public var operatorColor: Color { Color(red: 0.58, green: 0.07, blue: 0.55) } // Magenta
    public var commentColor: Color { Color(red: 0.58, green: 0.63, blue: 0.63) }
    public var specialColor: Color { Color(red: 0.83, green: 0.21, blue: 0.51) } // Magenta
    public var constantColor: Color { Color(red: 0.71, green: 0.54, blue: 0.00) }
    public var commandColor: Color { Color(red: 0.42, green: 0.44, blue: 0.77) } // Violet
    public var mathColor: Color { Color(red: 0.71, green: 0.54, blue: 0.00) }
    public var accentColor: Color { Color(red: 0.83, green: 0.21, blue: 0.51) }
    public var borderColor: Color { Color.primary }
    public var lineNumberColor: Color { Color(red: 0.58, green: 0.63, blue: 0.63) }
    public var selectionColor: Color { Color(red: 0.93, green: 0.91, blue: 0.84) }
    public var font: Font { .system(size: 13, design: .monospaced) }
    public var fontSize: CGFloat { 13 }
}

// MARK: - Solarized Dark Theme

/// A Solarized Dark theme.
public struct SolarizedDarkTheme: BibTeXTheme {
 
    public var name: String { "Solarized Dark" }
    
    public init() {}
    
    public var backgroundColor: Color { Color(red: 0.00, green: 0.17, blue: 0.21) }
    public var textColor: Color { Color(red: 0.51, green: 0.58, blue: 0.59) }
    public var entryTypeColor: Color { Color(red: 0.15, green: 0.55, blue: 0.82) }
    public var citationKeyColor: Color { Color(red: 0.80, green: 0.29, blue: 0.09) }
    public var fieldNameColor: Color { Color(red: 0.52, green: 0.60, blue: 0.00) }
    public var stringColor: Color { Color(red: 0.16, green: 0.63, blue: 0.60) }
    public var numberColor: Color { Color(red: 0.71, green: 0.54, blue: 0.00) }
    public var punctuationColor: Color { Color(red: 0.51, green: 0.58, blue: 0.59) }
    public var operatorColor: Color { Color(red: 0.58, green: 0.07, blue: 0.55) }
    public var commentColor: Color { Color(red: 0.40, green: 0.48, blue: 0.51) }
    public var specialColor: Color { Color(red: 0.83, green: 0.21, blue: 0.51) }
    public var constantColor: Color { Color(red: 0.71, green: 0.54, blue: 0.00) }
    public var commandColor: Color { Color(red: 0.42, green: 0.44, blue: 0.77) }
    public var mathColor: Color { Color(red: 0.71, green: 0.54, blue: 0.00) }
    public var accentColor: Color { Color(red: 0.83, green: 0.21, blue: 0.51) }
    public var borderColor: Color { Color.primary }
    public var lineNumberColor: Color { Color(red: 0.40, green: 0.48, blue: 0.51) }
    public var selectionColor: Color { Color(red: 0.03, green: 0.21, blue: 0.26) }
    public var font: Font { .system(size: 13, design: .monospaced) }
    public var fontSize: CGFloat { 13 }
}

// MARK: - Adaptive Theme

/// A theme that automatically adapts to light/dark mode.
public struct AdaptiveTheme: BibTeXTheme {
    public var name: String { current.name }
    
    private let lightTheme: any BibTeXTheme
    private let darkTheme: any BibTeXTheme
    
    @Environment(\.colorScheme) private var colorScheme
    
    /// Creates an adaptive theme.
    ///
    /// - Parameters:
    ///   - light: The theme to use in light mode.
    ///   - dark: The theme to use in dark mode.
    public init(
        light: any BibTeXTheme = DefaultLightTheme(),
        dark: any BibTeXTheme = DefaultDarkTheme()
    ) {
        self.lightTheme = light
        self.darkTheme = dark
    }
    
    private var current: any BibTeXTheme {
        colorScheme == .dark ? darkTheme : lightTheme
    }
    
    public var backgroundColor: Color { current.backgroundColor }
    public var textColor: Color { current.textColor }
    public var entryTypeColor: Color { current.entryTypeColor }
    public var citationKeyColor: Color { current.citationKeyColor }
    public var fieldNameColor: Color { current.fieldNameColor }
    public var stringColor: Color { current.stringColor }
    public var numberColor: Color { current.numberColor }
    public var punctuationColor: Color { current.punctuationColor }
    public var operatorColor: Color { current.operatorColor }
    public var commentColor: Color { current.commentColor }
    public var specialColor: Color { current.specialColor }
    public var constantColor: Color { current.constantColor }
    public var commandColor: Color { current.commandColor }
    public var mathColor: Color { current.mathColor }
    public var accentColor: Color { current.accentColor }
    public var borderColor: Color { current.borderColor }
    public var lineNumberColor: Color { current.lineNumberColor }
    public var selectionColor: Color { current.selectionColor }
    public var font: Font { current.font }
    public var fontSize: CGFloat { current.fontSize }
}
