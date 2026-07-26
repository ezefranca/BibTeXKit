//
//  BibTeXView.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// A SwiftUI view that displays BibTeX with syntax highlighting.
///
/// `BibTeXView` presents raw or parsed BibTeX with configurable themes,
/// line numbers, metadata, formatting, and copy behavior.
/// Raw input is highlighted exactly as supplied. A parsed entry is formatted
/// using ``BibTeXViewConfiguration/formattingStyle``.
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
/// BibTeXView(entry: entry)
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
    
    // MARK: - Initialization
    
    /// Creates a view that highlights raw BibTeX without reformatting it.
    ///
    /// The configuration's formatting style is ignored.
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
        adaptiveContent(isCompact: isCompactLayout)
        .frame(minHeight: configuration.renderedMinimumHeight)
        .frame(maxHeight: configuration.renderedMaximumHeight)
    }
    
    // MARK: - Adaptive Content
    
    @ViewBuilder
    private func adaptiveContent(isCompact: Bool) -> some View {
        let displayBibTeX = effectiveBibTeX
        let theme = configuration.theme(for: colorScheme)
        let lineSpacing = BibTeXViewLayoutMetrics.lineSpacing(
            base: configuration.renderedLineSpacing,
            isCompact: isCompact
        )
        
        contentContainer(
            bibtex: displayBibTeX,
            theme: theme,
            lineSpacing: lineSpacing,
            isCompact: isCompact
        )
        .overlay(alignment: copyButtonAlignment) {
            #if !os(watchOS) && !os(tvOS)
            if configuration.showCopyButton,
               configuration.copyButtonPosition != .inline {
                BibTeXCopyButton(
                    bibtex: displayBibTeX,
                    theme: theme,
                    style: configuration.copyButtonStyle,
                    isCompact: isCompact
                )
                .padding(8)
            }
            #endif
        }
    }
    
    @ViewBuilder
    private func contentContainer(
        bibtex: String,
        theme: any BibTeXTheme,
        lineSpacing: CGFloat,
        isCompact: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            #if !os(watchOS) && !os(tvOS)
            if configuration.showCopyButton,
               configuration.copyButtonPosition == .inline {
                HStack {
                    Spacer()
                    BibTeXCopyButton(
                        bibtex: bibtex,
                        theme: theme,
                        style: configuration.copyButtonStyle,
                        isCompact: isCompact
                    )
                }
                .padding(.horizontal, 8)
            }
            #endif

            if configuration.showMetadata, let entry = resolvedEntry {
                metadataHeader(for: entry, theme: theme)
                Divider()
                    .background(theme.borderColor.opacity(0.5))
            }
            
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    if configuration.showLineNumbers {
                        BibTeXLineNumbersView(
                            bibtex: bibtex,
                            font: theme.font,
                            color: theme.lineNumberColor,
                            lineSpacing: lineSpacing
                        )
                            .padding(.trailing, 8)
                    }
                    
                    BibTeXHighlightedContent(
                        bibtex: bibtex,
                        theme: theme,
                        lineSpacing: lineSpacing,
                        textSelectionEnabled: configuration.enableTextSelection
                    )
                }
                .padding(configuration.renderedContentPadding)
            }
        }
        .background(theme.backgroundColor)
        .compositingGroup()
        .clipShape(.rect(cornerRadius: configuration.renderedCornerRadius))
        .overlay(borderOverlay(theme: theme))
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
            
            Text(fieldCountDescription(entry.fields.count))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(configuration.renderedContentPadding)
    }
    
    // MARK: - Border Overlay
    
    @ViewBuilder
    private func borderOverlay(theme: any BibTeXTheme) -> some View {
        if configuration.showBorder {
            RoundedRectangle(
                cornerRadius: configuration.renderedCornerRadius,
                style: .continuous
            )
                .stroke(theme.borderColor, lineWidth: configuration.renderedBorderWidth)
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
    
    private var isCompactLayout: Bool {
        #if os(iOS) || os(tvOS)
        horizontalSizeClass == .compact
        #elseif os(watchOS)
        true
        #else
        false
        #endif
    }
    
    private func fieldCountDescription(_ count: Int) -> String {
        count == 1 ? "1 field" : "\(count) fields"
    }
}

// MARK: - Rendering Components

private struct BibTeXHighlightedContent: View {
    let bibtex: String
    let theme: any BibTeXTheme
    let lineSpacing: CGFloat
    let textSelectionEnabled: Bool

    @ViewBuilder
    var body: some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        if textSelectionEnabled {
            highlightedText.textSelection(.enabled)
        } else {
            highlightedText.textSelection(.disabled)
        }
        #else
        highlightedText
        #endif
    }

    private var highlightedText: some View {
        Text(BibTeXHighlighter(theme: theme).highlight(bibtex))
            .lineSpacing(lineSpacing)
            .fixedSize(horizontal: false, vertical: true)
            .tint(theme.selectionColor)
    }
}

private struct BibTeXLineNumbersView: View {
    let bibtex: String
    let font: Font
    let color: Color
    let lineSpacing: CGFloat

    var body: some View {
        Text(BibTeXLineNumbers.text(for: bibtex))
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(.trailing)
            .fixedSize()
            .frame(minWidth: 30, alignment: .trailing)
            .padding(.trailing, 8)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(width: 1)
            }
            .accessibilityHidden(true)
    }
}

enum BibTeXLineNumbers {
    static func text(for bibtex: String) -> String {
        var lineCount = 1
        for character in bibtex where character.isNewline {
            if lineCount < Int.max {
                lineCount += 1
            }
        }

        var result = String()
        let (charactersPerLine, characterCountOverflowed) =
            String(lineCount).count.addingReportingOverflow(1)
        let (estimatedCapacity, capacityOverflowed) =
            lineCount.multipliedReportingOverflow(by: charactersPerLine)
        if !characterCountOverflowed, !capacityOverflowed {
            result.reserveCapacity(estimatedCapacity)
        }

        for number in 1...lineCount {
            if number > 1 {
                result.append("\n")
            }
            result.append(String(number))
        }
        return result
    }
}

enum BibTeXViewLayoutMetrics {
    static func lineSpacing(base: CGFloat, isCompact: Bool) -> CGFloat {
        isCompact ? base * 0.8 : base
    }

    static func copyButtonPadding(isCompact: Bool) -> CGFloat {
        isCompact ? 6 : 8
    }
}

#if !os(watchOS) && !os(tvOS)
@MainActor
protocol BibTeXPlatformPasteboard: AnyObject {
    #if os(macOS)
    @discardableResult
    func clearContents() -> Int
    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool
    #else
    var string: String? { get set }
    #endif
}

#if os(macOS)
extension NSPasteboard: BibTeXPlatformPasteboard {}
#else
extension UIPasteboard: BibTeXPlatformPasteboard {}
#endif

@MainActor
struct BibTeXSystemClipboard {
    enum WriteError: Error {
        case rejected
    }

    private let pasteboard: any BibTeXPlatformPasteboard

    init(
        pasteboard: any BibTeXPlatformPasteboard = {
            #if os(macOS)
            NSPasteboard.general
            #else
            UIPasteboard.general
            #endif
        }()
    ) {
        self.pasteboard = pasteboard
    }

    func write(_ bibtex: String) throws {
        #if os(macOS)
        pasteboard.clearContents()
        guard pasteboard.setString(bibtex, forType: .string) else {
            throw WriteError.rejected
        }
        #else
        pasteboard.string = bibtex
        #endif
    }
}

@MainActor
@Observable
final class BibTeXCopyFeedback {
    typealias ClipboardWriter = @MainActor @Sendable (String) throws -> Void
    typealias Sleeper = @Sendable (Duration) async throws -> Void

    private final class ResetToken {}

    private(set) var isCopied = false

    private let feedbackDuration: Duration
    private let clipboardWriter: ClipboardWriter
    private let sleeper: Sleeper

    @ObservationIgnored
    private var feedbackResetTask: Task<Void, Never>?

    @ObservationIgnored
    private var resetToken: ResetToken?

    init(
        feedbackDuration: Duration = .seconds(1.5),
        clipboardWriter: @escaping ClipboardWriter = BibTeXSystemClipboard().write,
        sleeper: @escaping Sleeper = BibTeXCopyFeedback.sleep
    ) {
        self.feedbackDuration = feedbackDuration
        self.clipboardWriter = clipboardWriter
        self.sleeper = sleeper
    }

    deinit {
        feedbackResetTask?.cancel()
    }

    @discardableResult
    func copy(_ bibtex: String) -> Bool {
        do {
            try clipboardWriter(bibtex)
        } catch {
            cancel()
            return false
        }

        feedbackResetTask?.cancel()

        let token = ResetToken()
        let duration = feedbackDuration
        let sleeper = sleeper
        resetToken = token
        isCopied = true

        feedbackResetTask = Task { [weak self] in
            do {
                try await sleeper(duration)
            } catch {
                // Cancellation belongs to a replacement or disappearance.
                // Other sleeper failures still clear feedback below.
            }

            guard let self, self.resetToken === token else {
                return
            }

            self.feedbackResetTask = nil
            self.resetToken = nil
            self.isCopied = false
        }
        return true
    }

    func cancel() {
        feedbackResetTask?.cancel()
        feedbackResetTask = nil
        resetToken = nil
        isCopied = false
    }

    func waitForPendingReset() async {
        let task = feedbackResetTask
        await task?.value
    }

    private static func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}

struct BibTeXCopyButton: View {
    let bibtex: String
    let theme: any BibTeXTheme
    let style: BibTeXViewConfiguration.CopyButtonStyle
    let isCompact: Bool

    @State private var feedback: BibTeXCopyFeedback

    init(
        bibtex: String,
        theme: any BibTeXTheme,
        style: BibTeXViewConfiguration.CopyButtonStyle,
        isCompact: Bool,
        feedback: BibTeXCopyFeedback = BibTeXCopyFeedback()
    ) {
        self.bibtex = bibtex
        self.theme = theme
        self.style = style
        self.isCompact = isCompact
        self._feedback = State(initialValue: feedback)
    }

    var body: some View {
        Button(action: copyToClipboard) {
            label
                .foregroundStyle(feedback.isCopied ? .green : theme.color(for: .special))
                .padding(BibTeXViewLayoutMetrics.copyButtonPadding(isCompact: isCompact))
                .frame(minWidth: 44, minHeight: 44)
                .background {
                    if style != .compact {
                        if style == .labeled {
                            Capsule()
                                .fill(theme.backgroundColor)
                                .shadow(
                                    color: .black.opacity(0.1),
                                    radius: 2,
                                    y: 1
                                )
                        } else {
                            Circle()
                                .fill(theme.backgroundColor)
                                .shadow(
                                    color: .black.opacity(0.1),
                                    radius: 2,
                                    y: 1
                                )
                        }
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(feedback.isCopied ? "BibTeX copied" : "Copy BibTeX")
        .accessibilityHint("Copies this entry to the clipboard")
        .animation(.easeInOut(duration: 0.2), value: feedback.isCopied)
        .onDisappear {
            feedback.cancel()
        }
    }

    func copyToClipboard() {
        feedback.copy(bibtex)
    }

    @ViewBuilder
    private var label: some View {
        switch style {
        case .iconOnly:
            Image(systemName: feedback.isCopied ? "checkmark" : "doc.on.doc")
                .font(isCompact ? .caption : .body)
        case .labeled:
            Label(
                feedback.isCopied ? "Copied" : "Copy",
                systemImage: feedback.isCopied ? "checkmark" : "doc.on.doc"
            )
            .font(.caption)
        case .compact:
            Image(systemName: feedback.isCopied ? "checkmark" : "doc.on.doc")
                .font(.caption2)
        }
    }
}
#endif

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
    
    /// Sets the formatting style for a view created from a parsed entry.
    ///
    /// Raw input supplied to ``init(bibtex:configuration:)`` is unchanged.
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
    
    /// Replaces the view's entire configuration with a preset.
    ///
    /// Modifiers applied before this call are discarded.
    public func preset(_ preset: BibTeXViewConfiguration) -> Self {
        var copy = self
        copy.configuration = preset
        return copy
    }
}

// MARK: - Preview

#if DEBUG
private let bibTeXViewPreviewSample = """
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

#Preview("Default") {
    BibTeXView(bibtex: bibTeXViewPreviewSample)
        .frame(height: 300)
        .padding()
}

#Preview("With line numbers") {
    BibTeXView(bibtex: bibTeXViewPreviewSample)
        .lineNumbers()
        .showMetadata()
        .frame(height: 350)
        .padding()
}

#Preview("Compact") {
    BibTeXView(bibtex: bibTeXViewPreviewSample)
        .preset(.compact)
        .frame(height: 200)
        .padding()
}

#Preview("Monokai dark") {
    BibTeXView(bibtex: bibTeXViewPreviewSample)
        .bibTeXTheme(MonokaiTheme())
        .lineNumbers()
        .frame(height: 300)
        .padding()
        .preferredColorScheme(.dark)
}
#endif
