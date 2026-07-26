//
//  TokenizerMutationSurvivorTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Testing

@testable import BibTeXKit

@Suite("Given mutation-sensitive tokenizer boundaries")
struct TokenizerMutationSurvivorTests {
    private let tokenizer = BibTeXTokenizer()

    @Test(
        "Given a key without a separating comma, when the following assignment is tokenized, then citation-key state does not leak"
    )
    func citationKeyStateDoesNotLeakIntoFollowingAssignment() {
        let source = "@misc{k title = value}"

        let tokens = tokenizer.tokenize(source)

        expectToken("k", as: [.citationKey], in: tokens)
        expectToken("title", as: [.fieldName], in: tokens)
        expectToken("value", as: [.constant], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given a nested parenthesis in a parenthesized entry, when it closes, then the enclosing entry remains active"
    )
    func nestedParenthesisPreservesEnclosingEntryState() {
        let source = "@misc(k,(x),title=value)"

        let tokens = tokenizer.tokenize(source)

        expectToken("title", as: [.fieldName], in: tokens)
        expectToken("value", as: [.constant], in: tokens)
        expectToken("(", as: [.punctuation, .punctuation], in: tokens)
        expectToken(")", as: [.punctuation, .punctuation], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given parentheses and a comma inside a braced value, when tokenized, then each remains string content"
    )
    func structuralCharactersInsideBracedValueRemainStrings() {
        let source = "@misc(k,title={a(b)c,d},year=2024)"

        let tokens = tokenizer.tokenize(source)

        expectToken("(", as: [.punctuation, .string], in: tokens)
        expectToken(")", as: [.string, .punctuation], in: tokens)
        expectToken(",", as: [.punctuation, .string, .punctuation], in: tokens)
        expectToken("year", as: [.fieldName], in: tokens)
        expectToken("2024", as: [.number], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given nested braces in a field value, when the inner group closes, then outer text and later fields retain their states"
    )
    func nestedBracesPreserveFieldAndEntryDepth() {
        let source = "@misc{k,title={{inner} outer},year=2024}"

        let tokens = tokenizer.tokenize(source)

        expectToken("inner", as: [.string], in: tokens)
        expectToken("outer", as: [.string], in: tokens)
        expectToken("year", as: [.fieldName], in: tokens)
        expectToken("2024", as: [.number], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given assignment and concatenation symbols outside an entry, when tokenized, then they remain plain text"
    )
    func standaloneOperatorsRemainText() {
        let source = "= #"

        let tokens = tokenizer.tokenize(source)

        expectToken("=", as: [.text], in: tokens)
        expectToken("#", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given two bare constants joined by concatenation, when tokenized, then both operands are constants"
    )
    func concatenationEstablishesRightHandValueState() {
        let source = "@misc{k,note=left # right}"

        let tokens = tokenizer.tokenize(source)

        expectToken("left", as: [.constant], in: tokens)
        expectToken("#", as: [.operator], in: tokens)
        expectToken("right", as: [.constant], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given adjacent malformed bare values, when tokenized, then completed values do not retain right-hand-side state"
    )
    func completedBareValuesClearRightHandValueState() {
        let source = "@misc{k,note=left right,year=2024 suffix,title=\"q\" trailing}"

        let tokens = tokenizer.tokenize(source)

        expectToken("left", as: [.constant], in: tokens)
        expectToken("right", as: [.text], in: tokens)
        expectToken("2024", as: [.number], in: tokens)
        expectToken("suffix", as: [.text], in: tokens)
        expectToken("trailing", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given an unexpected quoted segment before an assignment, when tokenized, then the following name remains a field name"
    )
    func unexpectedQuotedSegmentDoesNotEstablishRightHandValueState() {
        let source = "@misc{k,\"q\" trailing=value}"

        let tokens = tokenizer.tokenize(source)

        expectToken("\"q\"", as: [.string], in: tokens)
        expectToken("trailing", as: [.fieldName], in: tokens)
        expectToken("value", as: [.constant], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given unmatched grouping inside top-level math, when math closes, then following prose remains plain text"
    )
    func topLevelMathCannotLeakBracedFieldState() {
        let source = "$x{y$ tail"

        let tokens = tokenizer.tokenize(source)

        expectToken("$x{y$", as: [.math], in: tokens)
        expectToken("tail", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given digits inside braces and a top-level word, when tokenized, then their exact semantic token kinds are retained"
    )
    func bracedDigitsAndTopLevelWordsHaveExactTokenKinds() {
        let source = "@misc{k,year={123}} plain"

        let tokens = tokenizer.tokenize(source)

        expectToken("123", as: [.string], in: tokens)
        expectToken("plain", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given a stray closing brace inside a quoted value, when tokenized, then quoted state cannot become negative"
    )
    func strayQuotedBraceCannotTrapFollowingText() {
        let source = "@misc{k,title=\"a}b\",year=2024}"

        let tokens = tokenizer.tokenize(source)

        expectToken("}", as: [.punctuation, .punctuation], in: tokens)
        expectToken("b", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given an unterminated quoted value ending in a backslash, when tokenized, then end-of-input is never subscripted"
    )
    func trailingBackslashInQuotedValueIsSafe() {
        let source = #"@misc{k,title="x\"#

        let tokens = tokenizer.tokenize(source)

        expectToken("\\", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given a top-level quoted string with nested braces, when tokenized, then the complete quoted segment is one string token"
    )
    func fallbackQuotedScannerHonorsNestedBracesAndClosingQuote() {
        let source = "\"a{b}c\" tail"

        let tokens = tokenizer.tokenize(source)

        expectToken("\"a{b}c\"", as: [.string], in: tokens)
        expectToken("tail", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given a stray closing brace in a top-level quoted string, when tokenized, then scanning stops before the brace"
    )
    func fallbackQuotedScannerStopsAtStrayClosingBrace() {
        let source = "\"a}b\" tail"

        let tokens = tokenizer.tokenize(source)

        expectToken("\"a", as: [.string], in: tokens)
        expectToken("}", as: [.punctuation], in: tokens)
        expectToken("b", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given an environment command at end-of-input, when tokenized, then absent group lookahead remains safe",
        arguments: [#"\begin"#, #"\end"#]
    )
    func bareEnvironmentCommandAtEndOfInputIsSafe(_ source: String) {
        let tokens = tokenizer.tokenize(source)

        expectToken(source, as: [.environment], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given top-level math whose first character escapes a dollar, when tokenized, then the escaped dollar cannot close math"
    )
    func topLevelMathHonorsLeadingEscapeState() {
        let source = #"$\$ tail"#

        let tokens = tokenizer.tokenize(source)

        expectToken(source, as: [.math], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given braced math openers at end-of-input, when tokenized, then all lookahead boundaries remain safe",
        arguments: [
            #"@misc{k,title={$"#,
            #"@misc{k,title={$$x$"#,
        ]
    )
    func bracedMathEndOfInputIsSafe(_ source: String) {
        let tokens = tokenizer.tokenize(source)

        #expect(tokens.last?.token == .math)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given braced math whose first character escapes a dollar, when tokenized, then the tail remains inside math"
    )
    func bracedMathHonorsLeadingEscapeState() {
        let source = #"@misc{k,title={$\$ tail}}"#

        let tokens = tokenizer.tokenize(source)

        expectToken(#"$\$ tail"#, as: [.math], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given nested braces and trailing text in braced math, when tokenized, then math and entry depth remain independent"
    )
    func bracedMathPreservesNestedEntryDepth() {
        let source = "@misc{k,title={${x}$ tail},year=2024}"

        let tokens = tokenizer.tokenize(source)

        expectToken("${x}$", as: [.math], in: tokens)
        expectToken("tail", as: [.string], in: tokens)
        expectToken("year", as: [.fieldName], in: tokens)
        expectToken("2024", as: [.number], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given a nested opening brace immediately followed by a dollar in braced math, when tokenized, then the dollar closes math"
    )
    func bracedMathClearsEscapeStateAtOpeningBrace() {
        let source = "@misc{k,title={${$ tail}}}"

        let tokens = tokenizer.tokenize(source)

        expectToken("${$", as: [.math], in: tokens)
        expectToken("tail", as: [.string], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given an escaped character before a braced-math closer, when tokenized, then escape state clears before the dollar"
    )
    func bracedMathClearsEscapeStateAfterEscapedCharacter() {
        let source = #"@misc{k,title={$\x$ tail}}"#

        let tokens = tokenizer.tokenize(source)

        expectToken(#"$\x$"#, as: [.math], in: tokens)
        expectToken("tail", as: [.string], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given display math followed by braced-value text, when tokenized, then the closing pair ends only the math token"
    )
    func bracedDisplayMathDoesNotSwallowTrailingText() {
        let source = "@misc{k,title={$$x$$ tail}}"

        let tokens = tokenizer.tokenize(source)

        expectToken("$$x$$", as: [.math], in: tokens)
        expectToken("tail", as: [.string], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given quoted math openers at end-of-input, when tokenized, then all lookahead boundaries remain safe",
        arguments: [
            #"@misc{k,title="$"#,
            #"@misc{k,title="$$x$"#,
        ]
    )
    func quotedMathEndOfInputIsSafe(_ source: String) {
        let tokens = tokenizer.tokenize(source)

        #expect(tokens.last?.token == .math)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given quoted math whose first character escapes a dollar, when tokenized, then the tail remains inside math"
    )
    func quotedMathHonorsLeadingEscapeState() {
        let source = #"@misc{k,title="$\$ tail"}"#

        let tokens = tokenizer.tokenize(source)

        expectToken(#"$\$ tail"#, as: [.math], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given an opening brace inside quoted math, when tokenized, then the brace remains a quoted-value boundary"
    )
    func quotedMathStopsBeforeOpeningBrace() {
        let source = #"@misc{k,title="$x{tail"}"#

        let tokens = tokenizer.tokenize(source)

        expectToken("$x", as: [.math], in: tokens)
        expectToken("{", as: [.punctuation, .punctuation], in: tokens)
        expectToken("tail", as: [.string], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given an escaped character before a quoted-math closer, when tokenized, then escape state clears before the dollar"
    )
    func quotedMathClearsEscapeStateAfterEscapedCharacter() {
        let source = #"@misc{k,title="$x\y$ tail"}"#

        let tokens = tokenizer.tokenize(source)

        expectToken(#"$x\y$"#, as: [.math], in: tokens)
        expectToken(" tail", as: [.string], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given display math followed by quoted-value text, when tokenized, then the closing pair ends only the math token"
    )
    func quotedDisplayMathDoesNotSwallowTrailingText() {
        let source = #"@misc{k,title="$$x$$ tail"}"#

        let tokens = tokenizer.tokenize(source)

        expectToken("$$x$$", as: [.math], in: tokens)
        expectToken(" tail", as: [.string], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given Unicode and unknown three-letter words, when tokenized, then neither is mistaken for a month constant"
    )
    func nonMonthWordsRemainText() {
        let source = "é foo"

        let tokens = tokenizer.tokenize(source)

        expectToken("é", as: [.text], in: tokens)
        expectToken("foo", as: [.text], in: tokens)
        expectLossless(tokens, source: source)
    }

    @Test(
        "Given a control scalar in a field-name candidate, when tokenized, then it cannot become part of a field name"
    )
    func controlScalarCannotEnterFieldName() {
        let source = "@misc{k,\u{0001}=value}"

        let tokens = tokenizer.tokenize(source)

        #expect(tokens.allSatisfy { token in
            token.token != .fieldName || !token.text.contains("\u{0001}")
        })
        expectToken("value", as: [.constant], in: tokens)
        expectLossless(tokens, source: source)
    }

    private func expectToken(
        _ text: String,
        as expectedKinds: [BibTeXToken],
        in tokens: [BibTeXTokenInfo],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            tokens.filter { $0.text == text }.map(\.token) == expectedKinds,
            "Expected \(text.debugDescription) to have token kinds \(expectedKinds)",
            sourceLocation: sourceLocation
        )
    }

    private func expectLossless(
        _ tokens: [BibTeXTokenInfo],
        source: String,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            tokens.map(\.text).joined() == source,
            "Token text must reconstruct the exact source",
            sourceLocation: sourceLocation
        )
    }
}
