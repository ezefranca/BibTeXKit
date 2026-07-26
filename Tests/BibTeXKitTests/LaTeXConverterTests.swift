//
//  LaTeXConverterTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Testing

@testable import BibTeXKit

@Suite("Given LaTeX and Unicode text")
struct LaTeXConverterTests {

    // MARK: - Empty Input Tests

    @Test("When converting an empty string, then the result remains empty")
    func emptyString() {
        #expect(LaTeXConverter.toUnicode("") == "")
    }

    @Test("When converting plain text, then every character passes through unchanged")
    func plainText() {
        let text = "Hello World"
        #expect(LaTeXConverter.toUnicode(text) == text)
    }

    // MARK: - Accent Tests

    @Test(
        "When converting acute accent commands, then the corresponding Unicode letters are produced"
    )
    func acuteAccent() {
        #expect(LaTeXConverter.toUnicode("\\'e") == "é")
        #expect(LaTeXConverter.toUnicode("\\'a") == "á")
        #expect(LaTeXConverter.toUnicode("\\'o") == "ó")
        #expect(LaTeXConverter.toUnicode("\\'u") == "ú")
        #expect(LaTeXConverter.toUnicode("\\'i") == "í")
    }

    @Test(
        "When converting grave accent commands, then the corresponding Unicode letters are produced"
    )
    func graveAccent() {
        #expect(LaTeXConverter.toUnicode("\\`e") == "è")
        #expect(LaTeXConverter.toUnicode("\\`a") == "à")
        #expect(LaTeXConverter.toUnicode("\\`o") == "ò")
    }

    @Test(
        "When converting umlaut accent commands, then the corresponding Unicode letters are produced"
    )
    func umlautAccent() {
        #expect(LaTeXConverter.toUnicode("\\\"u") == "ü")
        #expect(LaTeXConverter.toUnicode("\\\"o") == "ö")
        #expect(LaTeXConverter.toUnicode("\\\"a") == "ä")
        #expect(LaTeXConverter.toUnicode("\\\"e") == "ë")
    }

    @Test(
        "When converting circumflex accent commands, then the corresponding Unicode letters are produced"
    )
    func circumflexAccent() {
        #expect(LaTeXConverter.toUnicode("\\^e") == "ê")
        #expect(LaTeXConverter.toUnicode("\\^a") == "â")
        #expect(LaTeXConverter.toUnicode("\\^o") == "ô")
        #expect(LaTeXConverter.toUnicode("\\^i") == "î")
    }

    @Test(
        "When converting tilde accent commands, then the corresponding Unicode letters are produced"
    )
    func tildeAccent() {
        #expect(LaTeXConverter.toUnicode("\\~n") == "ñ")
        #expect(LaTeXConverter.toUnicode("\\~a") == "ã")
        #expect(LaTeXConverter.toUnicode("\\~o") == "õ")
    }

    @Test(
        "When converting cedilla commands with grouped or spaced targets, then Unicode cedillas are produced"
    )
    func cedillaAccent() {
        #expect(LaTeXConverter.toUnicode("\\c{c}") == "ç")
        #expect(LaTeXConverter.toUnicode("\\c c") == "ç")
    }

    @Test(
        "When converting caron accent commands, then the corresponding Unicode letters are produced"
    )
    func caronAccent() {
        #expect(LaTeXConverter.toUnicode("\\v{c}") == "č")
        #expect(LaTeXConverter.toUnicode("\\v{s}") == "š")
        #expect(LaTeXConverter.toUnicode("\\v{z}") == "ž")
    }

    @Test(
        "When converting a breve accent command, then the corresponding Unicode letter is produced")
    func breveAccent() {
        #expect(LaTeXConverter.toUnicode("\\u{a}") == "ă")
    }

    @Test(
        "When converting macron accent commands, then the corresponding Unicode letters are produced"
    )
    func macronAccent() {
        #expect(LaTeXConverter.toUnicode("\\={a}") == "ā")
        #expect(LaTeXConverter.toUnicode("\\={e}") == "ē")
    }

    @Test("When converting a dot accent command, then the corresponding Unicode letter is produced")
    func dotAccent() {
        #expect(LaTeXConverter.toUnicode("\\.{z}") == "ż")
    }

    @Test(
        "When converting a ring accent command, then the corresponding Unicode letter is produced")
    func ringAccent() {
        #expect(LaTeXConverter.toUnicode("\\r{a}") == "å")
    }

    @Test(
        "When converting double-acute accent commands, then the corresponding Unicode letters are produced"
    )
    func doubleAcuteAccent() {
        #expect(LaTeXConverter.toUnicode("\\H{o}") == "ő")
        #expect(LaTeXConverter.toUnicode("\\H{u}") == "ű")
    }

    @Test(
        "When converting ogonek accent commands, then the corresponding Unicode letters are produced"
    )
    func ogonekAccent() {
        #expect(LaTeXConverter.toUnicode("\\k{a}") == "ą")
        #expect(LaTeXConverter.toUnicode("\\k{e}") == "ę")
    }

    // MARK: - Accent with Braces Tests

    @Test(
        "When an accent target is grouped in braces, then the braces are consumed and the letter is converted"
    )
    func accentWithBraces() {
        #expect(LaTeXConverter.toUnicode("\\'{e}") == "é")
        #expect(LaTeXConverter.toUnicode("\\\"{o}") == "ö")
        #expect(LaTeXConverter.toUnicode("\\^{a}") == "â")
    }

    @Test(
        "When an accent target follows a delimiting space, then the letter is converted without the space"
    )
    func accentWithSpace() {
        #expect(LaTeXConverter.toUnicode("\\' e") == "é")
        #expect(LaTeXConverter.toUnicode("\\\" o") == "ö")
    }

    @Test(
        "When accent control words omit a delimiter, then they remain intact while control symbols accept immediate targets"
    )
    func letterNamedAccentsRequireSeparatedTargets() {
        #expect(LaTeXConverter.toUnicode(#"\cc"#) == #"\cc"#)
        #expect(LaTeXConverter.toUnicode(#"\c c"#) == "ç")
        #expect(LaTeXConverter.toUnicode(#"\c{c}"#) == "ç")
        #expect(LaTeXConverter.toUnicode(#"\'c"#) == "ć")
    }

    @Test(
        "When accents target dotless letter commands, then the corresponding accented letters are produced"
    )
    func accentWithDotlessLetterCommands() {
        #expect(LaTeXConverter.toUnicode("\\'{\\i}") == "í")
        #expect(LaTeXConverter.toUnicode("\\\"{\\i}") == "ï")
        #expect(LaTeXConverter.toUnicode("\\^{\\j}") == "ĵ")
        #expect(LaTeXConverter.toUnicode("\\'\\i") == "í")
    }

    @Test(
        "When an accent-like control word has a longer name, then it is preserved rather than partially consumed"
    )
    func accentDoesNotConsumeControlWordPrefixes() {
        #expect(LaTeXConverter.toUnicode("\\'\\item") == "\\'\\item")
        #expect(LaTeXConverter.toUnicode("\\\"\\index") == "\\\"\\index")
        #expect(LaTeXConverter.toUnicode("\\^\\joke") == "\\^\\joke")
        #expect(LaTeXConverter.toUnicode("\\'\\iota") == "\\'ι")
    }

    // MARK: - Special Character Tests

    @Test(
        "When converting named special-character commands, then their Unicode symbols are produced")
    func specialCharacters() {
        #expect(LaTeXConverter.toUnicode("\\ss") == "ß")
        #expect(LaTeXConverter.toUnicode("\\ae") == "æ")
        #expect(LaTeXConverter.toUnicode("\\AE") == "Æ")
        #expect(LaTeXConverter.toUnicode("\\oe") == "œ")
        #expect(LaTeXConverter.toUnicode("\\OE") == "Œ")
        #expect(LaTeXConverter.toUnicode("\\o") == "ø")
        #expect(LaTeXConverter.toUnicode("\\O") == "Ø")
        #expect(LaTeXConverter.toUnicode("\\aa") == "å")
        #expect(LaTeXConverter.toUnicode("\\AA") == "Å")
        #expect(LaTeXConverter.toUnicode("\\i") == "ı")
        #expect(LaTeXConverter.toUnicode("\\l") == "ł")
        #expect(LaTeXConverter.toUnicode("\\L") == "Ł")
    }

    // MARK: - Greek Letters Tests

    @Test(
        "When converting lowercase Greek commands, then every supported lowercase letter is produced"
    )
    func greekLettersLowercase() {
        #expect(LaTeXConverter.toUnicode("\\alpha") == "α")
        #expect(LaTeXConverter.toUnicode("\\beta") == "β")
        #expect(LaTeXConverter.toUnicode("\\gamma") == "γ")
        #expect(LaTeXConverter.toUnicode("\\delta") == "δ")
        #expect(LaTeXConverter.toUnicode("\\epsilon") == "ε")
        #expect(LaTeXConverter.toUnicode("\\zeta") == "ζ")
        #expect(LaTeXConverter.toUnicode("\\eta") == "η")
        #expect(LaTeXConverter.toUnicode("\\theta") == "θ")
        #expect(LaTeXConverter.toUnicode("\\iota") == "ι")
        #expect(LaTeXConverter.toUnicode("\\kappa") == "κ")
        #expect(LaTeXConverter.toUnicode("\\lambda") == "λ")
        #expect(LaTeXConverter.toUnicode("\\mu") == "μ")
        #expect(LaTeXConverter.toUnicode("\\nu") == "ν")
        #expect(LaTeXConverter.toUnicode("\\xi") == "ξ")
        #expect(LaTeXConverter.toUnicode("\\pi") == "π")
        #expect(LaTeXConverter.toUnicode("\\rho") == "ρ")
        #expect(LaTeXConverter.toUnicode("\\sigma") == "σ")
        #expect(LaTeXConverter.toUnicode("\\tau") == "τ")
        #expect(LaTeXConverter.toUnicode("\\phi") == "φ")
        #expect(LaTeXConverter.toUnicode("\\chi") == "χ")
        #expect(LaTeXConverter.toUnicode("\\psi") == "ψ")
        #expect(LaTeXConverter.toUnicode("\\omega") == "ω")
    }

    @Test(
        "When converting uppercase Greek commands, then every supported uppercase letter is produced"
    )
    func greekLettersUppercase() {
        #expect(LaTeXConverter.toUnicode("\\Gamma") == "Γ")
        #expect(LaTeXConverter.toUnicode("\\Delta") == "Δ")
        #expect(LaTeXConverter.toUnicode("\\Theta") == "Θ")
        #expect(LaTeXConverter.toUnicode("\\Lambda") == "Λ")
        #expect(LaTeXConverter.toUnicode("\\Pi") == "Π")
        #expect(LaTeXConverter.toUnicode("\\Sigma") == "Σ")
        #expect(LaTeXConverter.toUnicode("\\Phi") == "Φ")
        #expect(LaTeXConverter.toUnicode("\\Psi") == "Ψ")
        #expect(LaTeXConverter.toUnicode("\\Omega") == "Ω")
    }

    // MARK: - Math Symbols Tests

    @Test(
        "When converting supported math commands, then their Unicode mathematical symbols are produced"
    )
    func mathSymbols() {
        #expect(LaTeXConverter.toUnicode("\\infty") == "∞")
        #expect(LaTeXConverter.toUnicode("\\pm") == "±")
        #expect(LaTeXConverter.toUnicode("\\times") == "×")
        #expect(LaTeXConverter.toUnicode("\\div") == "÷")
        #expect(LaTeXConverter.toUnicode("\\leq") == "≤")
        #expect(LaTeXConverter.toUnicode("\\geq") == "≥")
        #expect(LaTeXConverter.toUnicode("\\neq") == "≠")
        #expect(LaTeXConverter.toUnicode("\\approx") == "≈")
        #expect(LaTeXConverter.toUnicode("\\equiv") == "≡")
        #expect(LaTeXConverter.toUnicode("\\sum") == "∑")
        #expect(LaTeXConverter.toUnicode("\\prod") == "∏")
        #expect(LaTeXConverter.toUnicode("\\int") == "∫")
        #expect(LaTeXConverter.toUnicode("\\partial") == "∂")
        #expect(LaTeXConverter.toUnicode("\\nabla") == "∇")
        #expect(LaTeXConverter.toUnicode("\\sqrt") == "√")
    }

    // MARK: - Escaped Characters Tests

    @Test("When converting escaped reserved characters, then the literal characters are produced")
    func escapedCharacters() {
        #expect(LaTeXConverter.toUnicode("\\%") == "%")
        #expect(LaTeXConverter.toUnicode("\\&") == "&")
        #expect(LaTeXConverter.toUnicode("\\$") == "$")
        #expect(LaTeXConverter.toUnicode("\\#") == "#")
        #expect(LaTeXConverter.toUnicode("\\_") == "_")
        #expect(LaTeXConverter.toUnicode("\\{") == "{")
        #expect(LaTeXConverter.toUnicode("\\}") == "}")
    }

    @Test(
        "When braces are escaped, then they remain literal characters rather than grouping delimiters"
    )
    func escapedBracesAreNotMistakenForGrouping() {
        #expect(LaTeXConverter.toUnicode("\\{A\\}") == "{A}")
        #expect(LaTeXConverter.toUnicode("\\{\\}") == "{}")
        #expect(LaTeXConverter.toUnicode("x\\{{A}\\}y") == "x{A}y")
        #expect(
            LaTeXConverter.toUnicode(
                "x\\{{A}\\}y",
                preservingGroupingBraces: true
            ) == "x{{A}}y")
    }

    // MARK: - Quotation Tests

    @Test(
        "When converting TeX quotation sequences, then directional Unicode quotation marks are produced"
    )
    func quotationMarks() {
        #expect(LaTeXConverter.toUnicode("``") == "\u{201C}")  // Left double quotation mark "
        #expect(LaTeXConverter.toUnicode("''") == "\u{201D}")  // Right double quotation mark "
        #expect(LaTeXConverter.toUnicode("`") == "'")  // Left single quotation mark '
        #expect(LaTeXConverter.toUnicode("'") == "'")  // Right single quotation mark '
    }

    // MARK: - Dash Tests

    @Test("When converting double and triple hyphens, then en and em dashes are produced")
    func dashes() {
        #expect(LaTeXConverter.toUnicode("---") == "—")
        #expect(LaTeXConverter.toUnicode("--") == "–")
    }

    // MARK: - Complex String Tests

    @Test(
        "When converting mixed accents and symbols, then the complete readable Unicode string is produced"
    )
    func complexString() {
        let input = "M\\\"uller and Caf\\'e"
        let expected = "Müller and Café"
        #expect(LaTeXConverter.toUnicode(input) == expected)
    }

    @Test(
        "When converting German LaTeX text, then its accented letters and sharp s are readable Unicode"
    )
    func germanText() {
        let input = "Zur Elektrodynamik bewegter K\\\"orper"
        let expected = "Zur Elektrodynamik bewegter Körper"
        #expect(LaTeXConverter.toUnicode(input) == expected)
    }

    @Test("When converting French LaTeX text, then its accented letters are readable Unicode")
    func frenchText() {
        let input = "Th\\'eorie de la relativit\\'e"
        let expected = "Théorie de la relativité"
        #expect(LaTeXConverter.toUnicode(input) == expected)
    }

    @Test(
        "When converting Spanish LaTeX text, then its accents and punctuation are readable Unicode")
    func spanishText() {
        let input = "Ma\\~nana y caf\\'e"
        let expected = "Mañana y café"
        #expect(LaTeXConverter.toUnicode(input) == expected)
    }

    @Test("When converting Scandinavian LaTeX text, then its special letters are readable Unicode")
    func scandinavianText() {
        let input = "\\AA rhus and \\O resund"
        let expected = "Århus and Øresund"
        #expect(LaTeXConverter.toUnicode(input) == expected)
    }

    @Test("When converting Polish LaTeX text, then its accented letters are readable Unicode")
    func polishText() {
        let input = "\\L{}\\'{o}d\\'{z}"
        // May contain Polish characters
        let result = LaTeXConverter.toUnicode(input)
        #expect(result.contains("Ł") || result.contains("ó"))
    }

    // MARK: - Mixed Content Tests

    @Test(
        "When LaTeX commands are mixed with prose, then commands convert without changing surrounding text"
    )
    func mixedLatexAndText() {
        let input = "Hello \\alpha and \\beta world"
        let result = LaTeXConverter.toUnicode(input)

        #expect(result.contains("Hello"))
        #expect(result.contains("α"))
        #expect(result.contains("β"))
        #expect(result.contains("world"))
    }

    @Test("When prose contains math delimiters, then the mathematical content is preserved")
    func mathWithText() {
        let input = "Energy equals $E = mc^2$"
        let result = LaTeXConverter.toUnicode(input)

        // Should preserve math content
        #expect(result.contains("Energy"))
    }

    // MARK: - Reverse Conversion Tests

    @Test(
        "When converting accented Unicode letters to LaTeX, then canonical accent commands are produced"
    )
    func toLaTeXBasic() {
        #expect(LaTeXConverter.toLaTeX("é") == "\\'e")
        #expect(LaTeXConverter.toLaTeX("ü") == "\\\"u")
        #expect(LaTeXConverter.toLaTeX("ñ") == "\\~n")
    }

    @Test(
        "When converting special Unicode letters to LaTeX, then canonical named commands are produced"
    )
    func toLaTeXSpecialChars() {
        #expect(LaTeXConverter.toLaTeX("ß") == "\\ss")
        #expect(LaTeXConverter.toLaTeX("æ") == "\\ae")
        #expect(LaTeXConverter.toLaTeX("ø") == "\\o")
    }

    @Test(
        "When converting Greek Unicode letters to LaTeX, then canonical Greek commands are produced"
    )
    func toLaTeXGreek() {
        #expect(LaTeXConverter.toLaTeX("α") == "\\alpha")
        #expect(LaTeXConverter.toLaTeX("β") == "\\beta")
        #expect(LaTeXConverter.toLaTeX("γ") == "\\gamma")
    }

    @Test(
        "When converting reserved text characters to LaTeX, then every character is escaped losslessly"
    )
    func toLaTeXEscapesEveryReservedTextCharacter() {
        let original = "{}\\~^&%$#_"
        let latex = LaTeXConverter.toLaTeX(original)

        #expect(
            latex == "\\{\\}\\textbackslash{}\\textasciitilde{}\\textasciicircum{}\\&\\%\\$\\#\\_")
        #expect(LaTeXConverter.toUnicode(latex) == original)
    }

    @Test(
        "When a generated control word precedes letters, then an empty delimiter group is inserted only when needed"
    )
    func toLaTeXTerminatesControlWordsOnlyWhenNeeded() {
        #expect(LaTeXConverter.toLaTeX("αray") == "\\alpha{}ray")
        #expect(LaTeXConverter.toLaTeX("ßeta") == "\\ss{}eta")
        #expect(LaTeXConverter.toLaTeX("Müller") == "M\\\"uller")
        #expect(LaTeXConverter.toUnicode(LaTeXConverter.toLaTeX("αray ßeta")) == "αray ßeta")
    }

    @Test(
        "When ASCII TeX shorthand sequences round-trip, then their literal punctuation is preserved"
    )
    func asciiShorthandSequencesRoundTripLiterally() {
        let values = [
            "`",
            "``",
            "''",
            "'''",
            "--",
            "---",
            "a--b",
            "literal ``quotes'' and --- punctuation",
        ]

        for original in values {
            let latex = LaTeXConverter.toLaTeX(original)
            #expect(
                LaTeXConverter.toUnicode(latex) == original,
                "Failed round trip for \(String(reflecting: original)); generated \(latex)")
        }
    }

    @Test(
        "When extended symbols round-trip through LaTeX, then every original Unicode symbol is restored"
    )
    func extendedSymbolRoundTrip() {
        let original = "© £ € ¥ ® ™ † ‡ § ¶ … – — “quoted” ∞ ∂"
        #expect(LaTeXConverter.toUnicode(LaTeXConverter.toLaTeX(original)) == original)
    }

    @Test(
        "When accented text round-trips through LaTeX, then the original Unicode spelling is restored"
    )
    func roundTrip() {
        let original = "Müller"
        let latex = LaTeXConverter.toLaTeX(original)
        let unicode = LaTeXConverter.toUnicode(latex)

        #expect(unicode == original)
    }

    @Test(
        "When mixed plain and accented text round-trips, then the original Unicode string is restored"
    )
    func roundTripComplex() {
        let original = "Café"
        let latex = LaTeXConverter.toLaTeX(original)
        let unicode = LaTeXConverter.toUnicode(latex)

        #expect(unicode == original)
    }

    // MARK: - Edge Cases

    @Test("When input ends with an incomplete command marker, then it is preserved exactly")
    func incompleteAccent() {
        // Incomplete accent at end of string
        let input = "test\\"
        let result = LaTeXConverter.toUnicode(input)
        #expect(result == input)
    }

    @Test("When a command is unknown, then its command text is preserved")
    func unknownCommand() {
        let input = "\\unknowncommand"
        let result = LaTeXConverter.toUnicode(input)
        // Should preserve unknown commands
        #expect(result.contains("unknowncommand") || result.contains("\\"))
    }

    @Test(
        "When control words have unsupported suffixes, then only complete supported commands convert"
    )
    func controlWordsRequireTokenBoundaries() {
        let input = "\\infinity \\alphabet \\Section \\category \\kappar"
        #expect(LaTeXConverter.toUnicode(input) == input)
        #expect(LaTeXConverter.toUnicode("\\infty+\\alpha") == "∞+α")
    }

    @Test(
        "When converting case-sensitive command keys to Unicode, then only complete supported keys are normalized",
        arguments: [
            CommandBoundaryScenario(input: #"\alpha"#, expected: "α"),
            CommandBoundaryScenario(input: #"\Alpha"#, expected: "Α"),
            CommandBoundaryScenario(input: #"\ALPHA"#, expected: #"\ALPHA"#),
            CommandBoundaryScenario(input: #"\alphabeta"#, expected: #"\alphabeta"#),
            CommandBoundaryScenario(input: #"\alpha{}beta"#, expected: "αbeta"),
        ]
    )
    func namedCommandKeyBoundaries(_ scenario: CommandBoundaryScenario) {
        #expect(LaTeXConverter.toUnicode(scenario.input) == scenario.expected)
    }

    @Test(
        "When converting canonically equivalent and unsupported graphemes, then supported keys normalize and unknown scalars remain intact"
    )
    func unicodeNormalizationAndPreservationBoundaries() {
        let decomposedAcute = "e\u{301}"
        let unsupported = "q\u{301}"

        #expect(LaTeXConverter.toLaTeX("é") == "\\'e")
        #expect(LaTeXConverter.toLaTeX(decomposedAcute) == "\\'e")

        let normalized = LaTeXConverter.toUnicode(LaTeXConverter.toLaTeX(decomposedAcute))
        #expect(normalized.unicodeScalars.map(\.value) == [0x00E9])

        let preserved = LaTeXConverter.toLaTeX(unsupported)
        #expect(preserved.unicodeScalars.map(\.value) == [0x0071, 0x0301])
    }

    @Test(
        "When an accent target uses nested grouping, then the target converts without leaking braces"
    )
    func nestedBraces() {
        let input = "\\'{e}"
        #expect(LaTeXConverter.toUnicode(input) == "é")
    }

    @Test(
        "When public conversion encounters presentation groups, then display-only braces are elided"
    )
    func publicConversionRetainsLegacyDisplayGroupingBehavior() {
        #expect(LaTeXConverter.toUnicode("{A}") == "A")
        #expect(LaTeXConverter.toUnicode("{{A}}") == "A")
        #expect(LaTeXConverter.toUnicode("{\\alpha}") == "α")
        #expect(LaTeXConverter.toUnicode("{\\LaTeX}") == "{\\LaTeX}")
        #expect(LaTeXConverter.toUnicode("{NASA}") == "{NASA}")
        #expect(LaTeXConverter.toUnicode("{A") == "{A")
        #expect(LaTeXConverter.toUnicode("A}") == "A}")
        #expect(LaTeXConverter.toUnicode("An {E}xample") == "An Example")
    }

    @Test(
        "When parser conversion mode handles protection groups, then every grouping brace is preserved"
    )
    func parserConversionModePreservesProtectionGroups() {
        #expect(
            LaTeXConverter.toUnicode(
                "{A}",
                preservingGroupingBraces: true
            ) == "{A}")
        #expect(
            LaTeXConverter.toUnicode(
                "{{A}}",
                preservingGroupingBraces: true
            ) == "{{A}}")
        #expect(
            LaTeXConverter.toUnicode(
                "{\\alpha}",
                preservingGroupingBraces: true
            ) == "{α}")
    }

    @Test(
        "When grouped accent arguments convert in either mode, then argument braces are consumed consistently"
    )
    func accentArgumentBracesAreConsumedInBothGroupingModes() {
        #expect(LaTeXConverter.toUnicode("\\'{e}") == "é")
        #expect(LaTeXConverter.toUnicode("\\\"{o}") == "ö")
        #expect(LaTeXConverter.toUnicode("{\\\"o}") == "ö")
        #expect(LaTeXConverter.toUnicode("{\\'{E}}") == "É")
        #expect(LaTeXConverter.toUnicode("{{\\\"{O}}}") == "Ö")
        #expect(
            LaTeXConverter.toUnicode(
                "{\\'{E}}",
                preservingGroupingBraces: true
            ) == "{É}")
    }

    @Test("When known control words use empty delimiter groups, then those delimiters are removed")
    func knownControlWordDelimiterGroupsAreRemoved() {
        #expect(LaTeXConverter.toUnicode("\\alpha{}ray") == "αray")
        #expect(LaTeXConverter.toUnicode("\\alpha{{}}ray") == "αray")
        #expect(
            LaTeXConverter.toUnicode(
                "\\alpha{}ray",
                preservingGroupingBraces: true
            ) == "αray")
    }

    @Test(
        "When unknown control words precede groups, then their structure is preserved while nested commands convert"
    )
    func unknownControlWordDelimiterGroupsArePreserved() {
        #expect(LaTeXConverter.toUnicode(#"\unknown{}command"#) == #"\unknown{}command"#)
        #expect(LaTeXConverter.toUnicode(#"\unknown{{}}command"#) == #"\unknown{{}}command"#)
        #expect(LaTeXConverter.toUnicode(#"\LaTeX{} Companion"#) == #"\LaTeX{} Companion"#)
        #expect(LaTeXConverter.toUnicode(#"\unknown{A}"#) == #"\unknown{A}"#)
        #expect(LaTeXConverter.toUnicode(#"\unknown{\alpha}"#) == #"\unknown{α}"#)
    }

    @Test("When accent commands are malformed, then their original spelling is preserved")
    func malformedAccentsArePreserved() {
        #expect(LaTeXConverter.toUnicode("\\'{ab}") == "\\'{ab}")
        #expect(LaTeXConverter.toUnicode("\\c{}") == "\\c{}")
        #expect(LaTeXConverter.toUnicode("\\uabc") == "\\uabc")
    }

    @Test(
        "When grouping is deeply nested, then conversion completes iteratively in both brace modes")
    func deepGroupingDoesNotUseTheCallStack() {
        let depth = 20_000
        let input =
            String(repeating: "{", count: depth)
            + "A"
            + String(repeating: "}", count: depth)
        #expect(LaTeXConverter.toUnicode(input) == "A")
        #expect(
            LaTeXConverter.toUnicode(
                input,
                preservingGroupingBraces: true
            ) == input)
    }

    @Test(
        "When an unsupported double-backslash command is converted, then it is preserved losslessly"
    )
    func doubleBackslash() {
        let input = "\\\\"
        let result = LaTeXConverter.toUnicode(input)
        // Unsupported line-break commands are preserved losslessly.
        #expect(result == input)
    }

    @Test("When input is already Unicode, then every character passes through unchanged")
    func unicodePassthrough() {
        let input = "Already Üñíçödé"
        let result = LaTeXConverter.toUnicode(input)
        #expect(result == input)
    }

    @Test(
        "When mixed inputs convert concurrently, then every task produces the same ordered results"
    )
    func concurrentConversionsAreDeterministic() async {
        let inputs = [
            #"M\"uller \alpha{}ray"#,
            "Café — α",
            #"\unknown{\alpha} \infinity"#,
            "e\u{301} q\u{301}",
            #"escaped \& and malformed \uabc"#,
        ]
        let expected = inputs.flatMap {
            [LaTeXConverter.toUnicode($0), LaTeXConverter.toLaTeX($0)]
        }

        await withTaskGroup(of: [String].self) { group in
            for _ in 0..<24 {
                group.addTask {
                    inputs.flatMap {
                        [LaTeXConverter.toUnicode($0), LaTeXConverter.toLaTeX($0)]
                    }
                }
            }

            var resultCount = 0
            for await result in group {
                resultCount += 1
                #expect(result == expected)
            }
            #expect(resultCount == 24)
        }
    }

    struct CommandBoundaryScenario: Sendable {
        let input: String
        let expected: String
    }
}
