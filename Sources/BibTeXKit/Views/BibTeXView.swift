//
//  BibTeXView.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// A SwiftUI view that displays BibTeX with syntax highlighting.
///
/// `BibTeXView` is a highly customizable, responsive view designed
/// to display BibTeX entries beautifully on any Apple platform.
///
/// ## Basic Usage
///
/// ```swift
/// BibTeXView(bibtex: myBibTeXString)
/// ```
///
/// ## With Entry
///
/// ```swift
/// if let entry = try? BibTeXParser.parse(bibtex).first {
///     BibTeXView(entry: entry)
/// }
/// ```
///
/// ## Customization
///
/// ```swift
/// BibTeXView(bibtex: myBibTeXString)
///     .bibTeXTheme(MonokaiTheme())
///     .lineNumbers(true)
///     .copyButtonHidden()
///     .formattingStyle(.aligned)
/// ```
public struct BibTeXView: View {
    
    // MARK: - Properties
    
    private let bibtex: String
    private let entry: BibTeXEntry?
    private var configuration: BibTeXViewConfiguration
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var copyFeedback = false
    @State private var contentSize: CGSize = .zero
    
    // MARK: - Initialization
    
    /// Creates a view displaying raw BibTeX.
    ///
    /// - Parameters:
    ///   - bibtex: The BibTeX string to display.
    ///   - configuration: Optional configuration.
    public init(bibtex: String, configuration: BibTeXViewConfiguration = BibTeXViewConfiguration()) {
        self.bibtex = bibtex
        self.entry = nil
        self.configuration = configuration
    }
    
    /// Creates a view displaying a parsed entry.
    ///
    /// - Parameters:
    ///   - entry: The entry to display.
    ///   - configuration: Optional configuration.
    public init(entry: BibTeXEntry, configuration: BibTeXViewConfiguration = BibTeXViewConfiguration()) {
        self.entry = entry
        self.bibtex = entry.formatted(style: configuration.formattingStyle)
        self.configuration = configuration
    }
    
    // MARK: - Body
    
    public var body: some View {
        GeometryReader { geometry in
            adaptiveContent(for: geometry.size)
        }
        .frame(minHeight: configuration.minHeight ?? 60)
        .frame(maxHeight: configuration.maxHeight)
    }
    
    // MARK: - Adaptive Content
    
    @ViewBuilder
    private func adaptiveContent(for size: CGSize) -> some View {
        let isCompact = isCompactLayout(for: size)
        
        ZStack(alignment: copyButtonAlignment) {
            // Main content
            contentContainer(isCompact: isCompact)
            
            // Copy button overlay
            if configuration.showCopyButton {
                copyButtonOverlay(isCompact: isCompact)
            }
        }
    }
    
    @ViewBuilder
    private func contentContainer(isCompact: Bool) -> some View {
        let theme = configuration.theme(for: colorScheme)
        
        VStack(alignment: .leading, spacing: 0) {
            // Metadata header
            if configuration.showMetadata, let entry = resolvedEntry {
                metadataHeader(for: entry, theme: theme)
                Divider()
                    .background(theme.borderColor.opacity(0.5))
            }
            
            // BibTeX content
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    if configuration.showLineNumbers {
                        lineNumbersView(theme: theme)
                            .padding(.trailing, 8)
                    }
                    
                    // Highlighted content
                    highlightedContent(theme: theme, isCompact: isCompact)
                }
                .padding(configuration.contentPadding)
            }
        }
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        .overlay(borderOverlay(theme: theme))
    }
    
    // MARK: - Highlighted Content
    
    @ViewBuilder
    private func highlightedContent(theme: any BibTeXTheme, isCompact: Bool) -> some View {
        let highlighter = BibTeXHighlighter(theme: theme)
        let displayBibtex = effectiveBibTeX
        let attributed = highlighter.highlight(displayBibtex)
        
        if configuration.enableTextSelection {
            Text(attributed)
                .lineSpacing(lineSpacingValue(isCompact: isCompact))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(attributed)
                .lineSpacing(lineSpacingValue(isCompact: isCompact))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Line Numbers
    
    @ViewBuilder
    private func lineNumbersView(theme: any BibTeXTheme) -> some View {
        let lines = effectiveBibTeX.components(separatedBy: .newlines)
        
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                Text("\(index + 1)")
                    .font(theme.font)
                    .foregroundStyle(theme.lineNumberColor)
                    .lineSpacing(configuration.lineSpacing)
            }
        }
        .frame(minWidth: 30, alignment: .trailing)
        .padding(.trailing, 8)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(theme.lineNumberColor.opacity(0.3))
                .frame(width: 1)
        }
    }
    
    // MARK: - Metadata Header
    
    @ViewBuilder
    private func metadataHeader(for entry: BibTeXEntry, theme: any BibTeXTheme) -> some View {
        HStack(spacing: 8) {
            // Entry type badge
            Label {
                Text(entry.type.rawValue)
                    .font(.caption.weight(.semibold))
            } icon: {
                Image(systemName: entry.type.symbolName)
            }
            .foregroundStyle(theme.color(for: .entryType))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.color(for: .entryType).opacity(0.1))
            .clipShape(Capsule())
            
            // Citation key
            Text(entry.citationKey)
                .font(.caption.monospaced())
                .foregroundStyle(theme.color(for: .citationKey))
            
            Spacer()
            
            // Field count
            Text("\(entry.fields.count) fields")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(configuration.contentPadding)
    }
    
    // MARK: - Copy Button
    
    @ViewBuilder
    private func copyButtonOverlay(isCompact: Bool) -> some View {
        Button(action: copyToClipboard) {
            copyButtonContent(isCompact: isCompact)
        }
        .buttonStyle(.plain)
        .padding(8)
        .accessibilityLabel("Copy BibTeX")
    }
    
    @ViewBuilder
    private func copyButtonContent(isCompact: Bool) -> some View {
        let theme = configuration.theme(for: colorScheme)
        
        Group {
            switch configuration.copyButtonStyle {
            case .iconOnly:
                Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                    .font(.system(size: isCompact ? 14 : 16))
            case .labeled:
                Label(
                    copyFeedback ? "Copied" : "Copy",
                    systemImage: copyFeedback ? "checkmark" : "doc.on.doc"
                )
                .font(.caption)
            case .compact:
                Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12))
            }
        }
        .foregroundStyle(copyFeedback ? .green : theme.color(for: .special))
        .padding(isCompact ? 6 : 8)
        .background {
            if configuration.copyButtonStyle != .compact {
                Circle()
                    .fill(theme.backgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: copyFeedback)
    }
    
    // MARK: - Border Overlay
    
    @ViewBuilder
    private func borderOverlay(theme: any BibTeXTheme) -> some View {
        if configuration.showBorder {
            RoundedRectangle(cornerRadius: configuration.cornerRadius)
                .stroke(theme.borderColor, lineWidth: configuration.borderWidth)
        }
    }
    
    // MARK: - Helpers
    
    private var effectiveBibTeX: String {
        if let entry = entry {
            return entry.formatted(style: configuration.formattingStyle)
        }
        return bibtex
    }
    
    private var resolvedEntry: BibTeXEntry? {
        if let entry = entry {
            return entry
        }
        return try? BibTeXParser.parse(bibtex).first
    }
    
    private var copyButtonAlignment: Alignment {
        switch configuration.copyButtonPosition {
        case .topLeading: return .topLeading
        case .topTrailing: return .topTrailing
        case .bottomLeading: return .bottomLeading
        case .bottomTrailing: return .bottomTrailing
        case .inline: return .topTrailing
        }
    }
    
    private func isCompactLayout(for size: CGSize) -> Bool {
        #if os(iOS) || os(tvOS)
        return horizontalSizeClass == .compact || size.width < 400
        #elseif os(watchOS)
        return true
        #else
        return size.width < 400
        #endif
    }
    
    private func lineSpacingValue(isCompact: Bool) -> CGFloat {
        let base = configuration.lineSpacing
        return isCompact ? base * 0.8 : base
    }
    
    private func copyToClipboard() {
        let textToCopy = effectiveBibTeX
        
        #if os(iOS) || os(tvOS) || os(visionOS)
        UIPasteboard.general.string = textToCopy
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToCopy, forType: .string)
        #elseif os(watchOS)
        // watchOS doesn't have clipboard API
        #endif
        
        withAnimation {
            copyFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                copyFeedback = false
            }
        }
    }
}

// MARK: - View Modifiers

extension BibTeXView {
    
    /// Sets the theme for syntax highlighting.
    public func bibTeXTheme(_ theme: any BibTeXTheme) -> Self {
        var copy = self
        copy.configuration.explicitTheme = theme
        return copy
    }
    
    /// Enables or disables line numbers.
    public func lineNumbers(_ enabled: Bool = true) -> Self {
        var copy = self
        copy.configuration.showLineNumbers = enabled
        return copy
    }
    
    /// Hides the copy button.
    public func copyButtonHidden(_ hidden: Bool = true) -> Self {
        var copy = self
        copy.configuration.showCopyButton = !hidden
        return copy
    }
    
    /// Sets the copy button position.
    public func copyButtonPosition(_ position: BibTeXViewConfiguration.CopyButtonPosition) -> Self {
        var copy = self
        copy.configuration.copyButtonPosition = position
        return copy
    }
    
    /// Sets the copy button style.
    public func copyButtonStyle(_ style: BibTeXViewConfiguration.CopyButtonStyle) -> Self {
        var copy = self
        copy.configuration.copyButtonStyle = style
        return copy
    }
    
    /// Shows or hides entry metadata.
    public func showMetadata(_ show: Bool = true) -> Self {
        var copy = self
        copy.configuration.showMetadata = show
        return copy
    }
    
    /// Sets the BibTeX formatting style.
    public func formattingStyle(_ style: BibTeXEntry.FormattingStyle) -> Self {
        var copy = self
        copy.configuration.formattingStyle = style
        return copy
    }
    
    /// Sets the maximum height before scrolling.
    public func maxHeight(_ height: CGFloat?) -> Self {
        var copy = self
        copy.configuration.maxHeight = height
        return copy
    }
    
    /// Sets the minimum height.
    public func minHeight(_ height: CGFloat?) -> Self {
        var copy = self
        copy.configuration.minHeight = height
        return copy
    }
    
    /// Sets the corner radius.
    public func cornerRadius(_ radius: CGFloat) -> Self {
        var copy = self
        copy.configuration.cornerRadius = radius
        return copy
    }
    
    /// Shows or hides the border.
    public func bordered(_ bordered: Bool = true) -> Self {
        var copy = self
        copy.configuration.showBorder = bordered
        return copy
    }
    
    /// Enables or disables text selection.
    public func textSelection(_ enabled: Bool) -> Self {
        var copy = self
        copy.configuration.enableTextSelection = enabled
        return copy
    }
    
    /// Sets content padding.
    public func contentPadding(_ padding: EdgeInsets) -> Self {
        var copy = self
        copy.configuration.contentPadding = padding
        return copy
    }
    
    /// Sets content padding with uniform value.
    public func contentPadding(_ value: CGFloat) -> Self {
        var copy = self
        copy.configuration.contentPadding = EdgeInsets(
            top: value, leading: value, bottom: value, trailing: value
        )
        return copy
    }
    
    /// Applies a preset configuration.
    public func preset(_ preset: BibTeXViewConfiguration) -> Self {
        var copy = self
        copy.configuration = preset
        return copy
    }
}

// MARK: - Preview

#if DEBUG
struct BibTeXView_Previews: PreviewProvider {
    static let sampleBibTeX = """
    @article{einstein1905,
        author = {Albert Einstein},
        title = {Zur Elektrodynamik bewegter K\\"orper},
        journal = {Annalen der Physik},
        volume = {17},
        pages = {891--921},
        year = {1905},
        doi = {10.1002/andp.19053221004}
    }
    """
    
    static var previews: some View {
        Group {
            // Default
            BibTeXView(bibtex: sampleBibTeX)
                .frame(height: 300)
                .padding()
                .previewDisplayName("Default")
            
            // With line numbers
            BibTeXView(bibtex: sampleBibTeX)
                .lineNumbers()
                .showMetadata()
                .frame(height: 350)
                .padding()
                .previewDisplayName("With Line Numbers")
            
            // Compact
            BibTeXView(bibtex: sampleBibTeX)
                .preset(.compact)
                .frame(height: 200)
                .padding()
                .previewDisplayName("Compact")
            
            // Dark theme
            BibTeXView(bibtex: sampleBibTeX)
                .bibTeXTheme(MonokaiTheme())
                .lineNumbers()
                .frame(height: 300)
                .padding()
                .preferredColorScheme(.dark)
                .previewDisplayName("Monokai Dark")
        }
    }
}
#endif
