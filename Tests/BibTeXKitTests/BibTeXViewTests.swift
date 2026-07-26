//
//  BibTeXViewTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import SwiftUI
import Testing
@testable import BibTeXKit

@Suite("Given BibTeX SwiftUI content")
struct BibTeXViewTests {
    @Test("Given empty content, when line numbers are generated, then one line is reported")
    func emptyContentHasOneLineNumber() {
        #expect(BibTeXLineNumbers.text(for: "") == "1")
    }

    @Test("Given a trailing newline, when line numbers are generated, then the empty final line is retained")
    func trailingEmptyLineIsRetained() {
        #expect(BibTeXLineNumbers.text(for: "first\nsecond\n") == "1\n2\n3")
    }

    @Test("Given Windows and Unicode separators, when line numbers are generated, then every separator is recognized")
    func windowsAndUnicodeSeparatorsAreRecognized() {
        let source = "first\r\nsecond\u{2028}third\u{2029}fourth"

        #expect(BibTeXLineNumbers.text(for: source) == "1\n2\n3\n4")
    }

    @Test("Given one thousand lines, when line numbers are generated, then the complete sequence is returned")
    func largeDocumentHasACompleteLineNumberSequence() {
        let source = String(repeating: "entry\n", count: 1_000)
        let numbers = BibTeXLineNumbers.text(for: source)

        #expect(numbers.split(separator: "\n").count == 1_001)
        #expect(numbers.hasSuffix("\n1001"))
    }

    @MainActor
    @Test("Given metadata and line numbers, when the full view renders, then it produces an image")
    func fullViewRendersWithMetadataAndLineNumbers() {
        let bibtex = """
        @article{rendering,
          author = {Ada Lovelace},
          title = {Notes},
          year = {1843}
        }
        """
        let content = BibTeXView(bibtex: bibtex)
            .lineNumbers()
            .showMetadata()
            .frame(width: 420, height: 260)
        let renderer = ImageRenderer(content: content)

        #expect(renderer.cgImage != nil)
    }

    @MainActor
    @Test("Given short and long content, when rendered intrinsically, then longer content receives more height")
    func intrinsicHeightGrowsWithContent() throws {
        func renderedHeight(for bibtex: String) throws -> Int {
            let content = BibTeXView(
                bibtex: bibtex,
                configuration: .minimal
            )
            .frame(width: 400)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 1
            return try #require(renderer.cgImage).height
        }

        let shortHeight = try renderedHeight(
            for: "@article{short, title = {One line}}"
        )
        let longHeight = try renderedHeight(
            for: (1...30).map { "line \($0)" }.joined(separator: "\n")
        )

        #expect(longHeight > shortHeight)
        #expect(longHeight > 60)
    }

    @MainActor
    @Test("Given a maximum height, when long content renders, then the rendered image respects the cap")
    func maximumHeightCapsLongContent() throws {
        let bibtex = (1...30).map { "line \($0)" }.joined(separator: "\n")
        let content = BibTeXView(
            bibtex: bibtex,
            configuration: .minimal
        )
        .maxHeight(120)
        .frame(width: 400)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1

        let image = try #require(renderer.cgImage)
        #expect(image.height <= 120)
    }

    @Test(
        "Given regular and compact layouts, when line spacing is resolved, then only compact spacing is reduced"
    )
    func compactLayoutReducesLineSpacing() {
        #expect(BibTeXViewLayoutMetrics.lineSpacing(base: 10, isCompact: false) == 10)
        #expect(BibTeXViewLayoutMetrics.lineSpacing(base: 10, isCompact: true) == 8)
    }

    @Test(
        "Given regular and compact copy controls, when padding is resolved, then both native metrics are explicit"
    )
    func compactCopyControlUsesReducedPadding() {
        #expect(BibTeXViewLayoutMetrics.copyButtonPadding(isCompact: false) == 8)
        #expect(BibTeXViewLayoutMetrics.copyButtonPadding(isCompact: true) == 6)
    }

    #if !os(watchOS) && !os(tvOS)
    @MainActor
    @Test("Given an inline copy button, when rendered, then it participates in vertical layout")
    func inlineCopyButtonParticipatesInLayout() throws {
        func renderedHeight(
            at position: BibTeXViewConfiguration.CopyButtonPosition
        ) throws -> Int {
            let content = BibTeXView(bibtex: "@misc{inline}")
                .copyButtonPosition(position)
                .frame(width: 400)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 1
            return try #require(renderer.cgImage).height
        }

        #expect(
            try renderedHeight(at: .inline)
                > renderedHeight(at: .topTrailing)
        )
    }

    @MainActor
    @Test(
        "Given every copy-button position, when the view renders, then each alignment remains a valid native layout",
        arguments: [
            BibTeXViewConfiguration.CopyButtonPosition.topLeading,
            .topTrailing,
            .bottomLeading,
            .bottomTrailing,
            .inline,
        ]
    )
    func everyCopyButtonPositionRenders(
        _ position: BibTeXViewConfiguration.CopyButtonPosition
    ) {
        let content = BibTeXView(bibtex: "@misc{position}")
            .copyButtonPosition(position)
            .frame(width: 320, height: 160)

        #expect(ImageRenderer(content: content).cgImage != nil)
    }

    @MainActor
    @Test(
        "Given an isolated platform pasteboard, when system clipboard writing succeeds or fails, then both outcomes are explicit"
    )
    func systemClipboardAdapterUsesInjectedPasteboard() throws {
        let pasteboard = PlatformPasteboardSpy()
        let clipboard = BibTeXSystemClipboard(pasteboard: pasteboard)

        try clipboard.write("@misc{accepted}")

        #expect(pasteboard.clearCount == 1)
        #expect(pasteboard.attemptedValues == ["@misc{accepted}"])

        pasteboard.acceptsWrites = false
        #expect(throws: BibTeXSystemClipboard.WriteError.self) {
            try clipboard.write("@misc{rejected}")
        }
        #expect(pasteboard.clearCount == 2)
        #expect(
            pasteboard.attemptedValues
                == ["@misc{accepted}", "@misc{rejected}"]
        )
    }

    @MainActor
    @Test(
        "Given the default continuous clock with zero duration, when copying succeeds, then feedback resets without an elapsed-time dependency"
    )
    func defaultClockResetsZeroDurationFeedback() async {
        let clipboard = ClipboardWriterSpy()
        let feedback = BibTeXCopyFeedback(
            feedbackDuration: .zero,
            clipboardWriter: { try clipboard.write($0) }
        )

        #expect(feedback.copy("@misc{clock}"))
        await feedback.waitForPendingReset()

        #expect(!feedback.isCopied)
        #expect(clipboard.attemptedValues == ["@misc{clock}"])
    }

    @MainActor
    @Test(
        "Given copied feedback and every presentation, when the native button renders and acts, then success content and injected copying are used"
    )
    func copiedButtonPresentationsRenderAndAct() async {
        let styles: [BibTeXViewConfiguration.CopyButtonStyle] = [
            .iconOnly,
            .labeled,
            .compact,
        ]

        for (index, style) in styles.enumerated() {
            let clipboard = ClipboardWriterSpy()
            let sleeper = ControlledSleeper()
            let feedback = makeFeedback(
                clipboard: clipboard,
                sleeper: sleeper
            )
            let source = "@misc{button\(index)}"
            let button = BibTeXCopyButton(
                bibtex: source,
                theme: DefaultLightTheme(),
                style: style,
                isCompact: index.isMultiple(of: 2),
                feedback: feedback
            )

            button.copyToClipboard()
            await sleeper.waitForRequestCount(1)

            #expect(feedback.isCopied)
            #expect(
                ImageRenderer(
                    content: button.frame(width: 180, height: 80)
                ).cgImage != nil
            )
            #expect(clipboard.attemptedValues == [source])

            feedback.cancel()
            await sleeper.waitForCancellationCount(1)
        }
    }

    @MainActor
    @Test(
        "Given injected clipboard and sleep operations, when copying succeeds, then feedback appears and resets without real side effects"
    )
    func successfulCopyWritesAndResetsDeterministically() async throws {
        let clipboard = ClipboardWriterSpy()
        let sleeper = ControlledSleeper()
        let feedback = makeFeedback(clipboard: clipboard, sleeper: sleeper)

        #expect(feedback.copy("@misc{success}"))
        await sleeper.waitForRequestCount(1)

        #expect(feedback.isCopied)
        #expect(clipboard.attemptedValues == ["@misc{success}"])
        #expect(await sleeper.requestedDurations() == [.seconds(42)])

        let didResume = await sleeper.succeed(request: 0)
        try #require(didResume)
        await feedback.waitForPendingReset()

        #expect(!feedback.isCopied)
    }

    @MainActor
    @Test(
        "Given active feedback, when another copy replaces it, then the previous reset is cancelled and only the replacement resets state"
    )
    func replacementCopyCancelsPreviousReset() async throws {
        let clipboard = ClipboardWriterSpy()
        let sleeper = ControlledSleeper()
        let feedback = makeFeedback(clipboard: clipboard, sleeper: sleeper)

        #expect(feedback.copy("@misc{first}"))
        await sleeper.waitForRequestCount(1)
        #expect(feedback.copy("@misc{replacement}"))
        await sleeper.waitForRequestCount(2)
        await sleeper.waitForCancellationCount(1)

        #expect(feedback.isCopied)
        #expect(clipboard.attemptedValues == ["@misc{first}", "@misc{replacement}"])

        let didResume = await sleeper.succeed(request: 1)
        try #require(didResume)
        await feedback.waitForPendingReset()

        #expect(!feedback.isCopied)
        #expect(await sleeper.pendingRequestCount() == 0)
    }

    @MainActor
    @Test(
        "Given active feedback, when cancellation is requested, then state resets and the pending operation is cancelled"
    )
    func explicitCancellationClearsFeedback() async {
        let clipboard = ClipboardWriterSpy()
        let sleeper = ControlledSleeper()
        let feedback = makeFeedback(clipboard: clipboard, sleeper: sleeper)

        #expect(feedback.copy("@misc{cancelled}"))
        await sleeper.waitForRequestCount(1)

        feedback.cancel()
        await sleeper.waitForCancellationCount(1)

        #expect(!feedback.isCopied)
        #expect(await sleeper.pendingRequestCount() == 0)
    }

    @MainActor
    @Test(
        "Given a clipboard write error, when copying is attempted, then feedback remains idle and no reset is scheduled"
    )
    func clipboardFailureDoesNotReportSuccess() async {
        let clipboard = ClipboardWriterSpy(rejectsWrites: true)
        let sleeper = ControlledSleeper()
        let feedback = makeFeedback(clipboard: clipboard, sleeper: sleeper)

        #expect(!feedback.copy("@misc{rejected}"))

        #expect(!feedback.isCopied)
        #expect(clipboard.attemptedValues == ["@misc{rejected}"])
        #expect(await sleeper.requestCount() == 0)
    }

    @MainActor
    @Test(
        "Given active feedback, when the injected sleep operation fails, then feedback still returns to its idle state"
    )
    func sleeperFailureStillResetsFeedback() async throws {
        let clipboard = ClipboardWriterSpy()
        let sleeper = ControlledSleeper()
        let feedback = makeFeedback(clipboard: clipboard, sleeper: sleeper)

        #expect(feedback.copy("@misc{sleep-error}"))
        await sleeper.waitForRequestCount(1)

        let didResume = await sleeper.fail(request: 0)
        try #require(didResume)
        await feedback.waitForPendingReset()

        #expect(!feedback.isCopied)
    }

    @MainActor
    private func makeFeedback(
        clipboard: ClipboardWriterSpy,
        sleeper: ControlledSleeper
    ) -> BibTeXCopyFeedback {
        BibTeXCopyFeedback(
            feedbackDuration: .seconds(42),
            clipboardWriter: { try clipboard.write($0) },
            sleeper: { try await sleeper.sleep(for: $0) }
        )
    }
    #endif
}

#if !os(watchOS) && !os(tvOS)
private enum BibTeXViewTestError: Error {
    case clipboardRejected
    case sleepFailed
}

@MainActor
private final class PlatformPasteboardSpy: BibTeXPlatformPasteboard {
    var acceptsWrites = true
    private(set) var clearCount = 0
    private(set) var attemptedValues: [String] = []

    #if os(macOS)
    @discardableResult
    func clearContents() -> Int {
        clearCount += 1
        return 0
    }

    func setString(
        _ string: String,
        forType dataType: NSPasteboard.PasteboardType
    ) -> Bool {
        attemptedValues.append(string)
        return acceptsWrites && dataType == .string
    }
    #else
    var string: String? {
        didSet {
            clearCount += 1
            if let string {
                attemptedValues.append(string)
            }
        }
    }
    #endif
}

@MainActor
private final class ClipboardWriterSpy {
    private(set) var attemptedValues: [String] = []
    private let rejectsWrites: Bool

    init(rejectsWrites: Bool = false) {
        self.rejectsWrites = rejectsWrites
    }

    func write(_ value: String) throws {
        attemptedValues.append(value)
        if rejectsWrites {
            throw BibTeXViewTestError.clipboardRejected
        }
    }
}

private actor ControlledSleeper {
    private struct CountWaiter {
        let minimumCount: Int
        let continuation: CheckedContinuation<Void, Never>
    }

    private var durations: [Duration] = []
    private var pendingRequests: [Int: CheckedContinuation<Void, any Error>] = [:]
    private var cancellationCount = 0
    private var requestWaiters: [CountWaiter] = []
    private var cancellationWaiters: [CountWaiter] = []

    func sleep(for duration: Duration) async throws {
        let request = durations.count
        durations.append(duration)
        resumeSatisfiedRequestWaiters()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, any Error>) in
                if Task.isCancelled {
                    cancellationCount += 1
                    continuation.resume(throwing: CancellationError())
                    resumeSatisfiedCancellationWaiters()
                } else {
                    pendingRequests[request] = continuation
                }
            }
        } onCancel: {
            Task {
                await self.cancel(request: request)
            }
        }
    }

    func waitForRequestCount(_ minimumCount: Int) async {
        guard durations.count < minimumCount else {
            return
        }

        await withCheckedContinuation { continuation in
            requestWaiters.append(
                CountWaiter(
                    minimumCount: minimumCount,
                    continuation: continuation
                )
            )
        }
    }

    func waitForCancellationCount(_ minimumCount: Int) async {
        guard cancellationCount < minimumCount else {
            return
        }

        await withCheckedContinuation { continuation in
            cancellationWaiters.append(
                CountWaiter(
                    minimumCount: minimumCount,
                    continuation: continuation
                )
            )
        }
    }

    func requestedDurations() -> [Duration] {
        durations
    }

    func requestCount() -> Int {
        durations.count
    }

    func pendingRequestCount() -> Int {
        pendingRequests.count
    }

    func succeed(request: Int) -> Bool {
        guard let continuation = pendingRequests.removeValue(forKey: request) else {
            return false
        }
        continuation.resume()
        return true
    }

    func fail(request: Int) -> Bool {
        guard let continuation = pendingRequests.removeValue(forKey: request) else {
            return false
        }
        continuation.resume(throwing: BibTeXViewTestError.sleepFailed)
        return true
    }

    private func cancel(request: Int) {
        guard let continuation = pendingRequests.removeValue(forKey: request) else {
            return
        }
        cancellationCount += 1
        continuation.resume(throwing: CancellationError())
        resumeSatisfiedCancellationWaiters()
    }

    private func resumeSatisfiedRequestWaiters() {
        requestWaiters = resumeSatisfiedWaiters(
            requestWaiters,
            actualCount: durations.count
        )
    }

    private func resumeSatisfiedCancellationWaiters() {
        cancellationWaiters = resumeSatisfiedWaiters(
            cancellationWaiters,
            actualCount: cancellationCount
        )
    }

    private func resumeSatisfiedWaiters(
        _ waiters: [CountWaiter],
        actualCount: Int
    ) -> [CountWaiter] {
        var pending: [CountWaiter] = []
        pending.reserveCapacity(waiters.count)

        for waiter in waiters {
            if actualCount >= waiter.minimumCount {
                waiter.continuation.resume()
            } else {
                pending.append(waiter)
            }
        }
        return pending
    }
}
#endif
