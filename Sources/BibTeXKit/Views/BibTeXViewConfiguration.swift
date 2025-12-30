//
//  BibTeXViewConfiguration.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI

/// Configuration options for `BibTeXView`.
///
/// Use this struct to customize every aspect of how BibTeX is displayed.
public struct BibTeXViewConfiguration: Sendable {
    
    // MARK: - Display Options
    
    /// Whether to show line numbers.
    public var showLineNumbers: Bool
    
    /// Whether to show the copy button.
    public var showCopyButton: Bool
    
    /// Whether to show entry metadata (type, key info).
    public var showMetadata: Bool
    
    /// Whether to enable text selection.
    public var enableTextSelection: Bool
    
    /// The formatting style for the BibTeX.
    public var formattingStyle: BibTeXEntry.FormattingStyle
    
    /// Maximum height before scrolling (nil for unbounded).
    public var maxHeight: CGFloat?
    
    /// Minimum height (nil for content-based).
    public var minHeight: CGFloat?
    
    // MARK: - Theme Options
    
    /// Whether to automatically adapt to system color scheme.
    public var adaptToColorScheme: Bool
    
    /// Light theme to use when `adaptToColorScheme` is true.
    public var lightTheme: any BibTeXTheme
    
    /// Dark theme to use when `adaptToColorScheme` is true.
    public var darkTheme: any BibTeXTheme
    
    /// Explicit theme (overrides adaptive theming).
    public var explicitTheme: (any BibTeXTheme)?
    
    // MARK: - Sizing Options
    
    /// Padding around the content.
    public var contentPadding: EdgeInsets
    
    /// Corner radius for the container.
    public var cornerRadius: CGFloat
    
    /// Line spacing multiplier.
    public var lineSpacing: CGFloat
    
    /// Whether to show a border.
    public var showBorder: Bool
    
    /// Border width when `showBorder` is true.
    public var borderWidth: CGFloat
    
    // MARK: - Copy Button Options
    
    /// Position of the copy button.
    public var copyButtonPosition: CopyButtonPosition
    
    /// Style of the copy button.
    public var copyButtonStyle: CopyButtonStyle
    
    // MARK: - Initialization
    
    /// Creates a new configuration with default values.
    public init(
        showLineNumbers: Bool = false,
        showCopyButton: Bool = true,
        showMetadata: Bool = false,
        enableTextSelection: Bool = true,
        formattingStyle: BibTeXEntry.FormattingStyle = .standard,
        maxHeight: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        adaptToColorScheme: Bool = true,
        lightTheme: any BibTeXTheme = DefaultLightTheme(),
        darkTheme: any BibTeXTheme = DefaultDarkTheme(),
        explicitTheme: (any BibTeXTheme)? = nil,
        contentPadding: EdgeInsets = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
        cornerRadius: CGFloat = 8,
        lineSpacing: CGFloat = 1.2,
        showBorder: Bool = true,
        borderWidth: CGFloat = 1,
        copyButtonPosition: CopyButtonPosition = .topTrailing,
        copyButtonStyle: CopyButtonStyle = .iconOnly
    ) {
        self.showLineNumbers = showLineNumbers
        self.showCopyButton = showCopyButton
        self.showMetadata = showMetadata
        self.enableTextSelection = enableTextSelection
        self.formattingStyle = formattingStyle
        self.maxHeight = maxHeight
        self.minHeight = minHeight
        self.adaptToColorScheme = adaptToColorScheme
        self.lightTheme = lightTheme
        self.darkTheme = darkTheme
        self.explicitTheme = explicitTheme
        self.contentPadding = contentPadding
        self.cornerRadius = cornerRadius
        self.lineSpacing = lineSpacing
        self.showBorder = showBorder
        self.borderWidth = borderWidth
        self.copyButtonPosition = copyButtonPosition
        self.copyButtonStyle = copyButtonStyle
    }
    
    // MARK: - Presets
    
    /// A minimal configuration with just the content.
    public static var minimal: BibTeXViewConfiguration {
        BibTeXViewConfiguration(
            showLineNumbers: false,
            showCopyButton: false,
            showMetadata: false,
            contentPadding: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
            cornerRadius: 4,
            showBorder: false
        )
    }
    
    /// A compact configuration for tight spaces.
    public static var compact: BibTeXViewConfiguration {
        BibTeXViewConfiguration(
            showLineNumbers: false,
            showCopyButton: true,
            showMetadata: false,
            formattingStyle: .compact,
            contentPadding: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
            cornerRadius: 6,
            copyButtonPosition: .topTrailing,
            copyButtonStyle: .iconOnly
        )
    }
    
    /// A full-featured configuration with all options.
    public static var full: BibTeXViewConfiguration {
        BibTeXViewConfiguration(
            showLineNumbers: true,
            showCopyButton: true,
            showMetadata: true,
            formattingStyle: .aligned,
            contentPadding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
            cornerRadius: 12
        )
    }
    
    /// A configuration optimized for mobile devices.
    public static var mobile: BibTeXViewConfiguration {
        BibTeXViewConfiguration(
            showLineNumbers: false,
            showCopyButton: true,
            showMetadata: false,
            formattingStyle: .compact,
            contentPadding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
            cornerRadius: 8,
            copyButtonPosition: .topTrailing,
            copyButtonStyle: .iconOnly
        )
    }
    
    // MARK: - Nested Types
    
    /// Position of the copy button.
    public enum CopyButtonPosition: Sendable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
        case inline
    }
    
    /// Style of the copy button.
    public enum CopyButtonStyle: Sendable {
        case iconOnly
        case labeled
        case compact
    }
}

// MARK: - Theme Resolution

extension BibTeXViewConfiguration {
    
    /// Returns the appropriate theme for the given color scheme.
    public func theme(for colorScheme: ColorScheme) -> any BibTeXTheme {
        if let explicit = explicitTheme {
            return explicit
        }
        return colorScheme == .dark ? darkTheme : lightTheme
    }
}
