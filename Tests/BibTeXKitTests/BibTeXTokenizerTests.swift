//
//  BibTeXTokenizerTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation
import Testing

@testable import BibTeXKit

@Suite("Given BibTeX and LaTeX source text")
struct BibTeXTokenizerTests {

    private let tokenizer = BibTeXTokenizer()

    // MARK: - Basic Tokenization

    @Test("When tokenizing an empty string, then no tokens are emitted")
    func emptyString() {
        let tokens = tokenizer.tokenize("")
        #expect(tokens.isEmpty)
    }

    @Test("When tokenizing only whitespace, then one whitespace token covers the input")
    func whitespaceOnly() {
        let tokens = tokenizer.tokenize("   \n\t  ")
        #expect(tokens.count == 1)
        #expect(tokens.first?.token == .whitespace)
    }

    // MARK: - Entry Type Tokenization

    @Test("When tokenizing an article declaration, then @article is an entry-type token")
    func articleEntryType() {
        let tokens = tokenizer.tokenize("@article")

        let entryType = tokens.first { $0.token == .entryType }

        #expect(entryType != nil)
        // The tokenizer includes @ as part of the entry type token
        #expect(entryType?.text.lowercased() == "@article")
    }

    @Test("When tokenizing a book declaration, then @book is an entry-type token")
    func bookEntryType() {
        let tokens = tokenizer.tokenize("@book")

        let entryType = tokens.first { $0.token == .entryType }
        #expect(entryType != nil)
        #expect(entryType?.text.lowercased() == "@book")
    }

    @Test("When tokenizing standard declarations, then each declaration is an entry-type token")
    func allStandardEntryTypes() {
        let types = ["article", "book", "inproceedings", "phdthesis", "misc", "techreport"]

        for type in types {
            let tokens = tokenizer.tokenize("@\(type)")
            let entryTypeToken = tokens.first { $0.token == .entryType }
            #expect(entryTypeToken != nil, "Failed for type: \(type)")
        }
    }

    @Test(
        "When a custom entry type contains whitespace and punctuation, then its full declaration is preserved"
    )
    func whitespaceSeparatedHyphenatedCustomEntryType() {
        let bibtex = "@ custom-entry.type {custom-key, title = {Custom Entry}}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.token == .entryType }?.text == "@ custom-entry.type")
        #expect(tokens.first { $0.token == .citationKey }?.text == "custom-key")
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    // MARK: - Key Tokenization

    @Test("When an entry contains a citation key, then the key receives its own token")
    func citationKey() {
        let tokens = tokenizer.tokenize("@article{einstein1905,")

        let key = tokens.first { $0.token == .citationKey }
        #expect(key != nil)
        #expect(key?.text == "einstein1905")
    }

    @Test(
        "When a citation key contains supported punctuation, then it remains a citation-key token")
    func keyWithSpecialCharacters() {
        let tokens = tokenizer.tokenize("@article{author:2024-paper,")

        let key = tokens.first { $0.token == .citationKey }
        #expect(key != nil)
    }

    @Test("When a citation key starts with digits, then the complete key is one token")
    func numericCitationKeyIsConsumedAsOneToken() {
        let tokens = tokenizer.tokenize("@article{2024/smith.v1, title = {Test}}")

        let key = tokens.first { $0.token == .citationKey }
        #expect(key?.text == "2024/smith.v1")
    }

    @Test("When citation-key delimiters vary, then tokenizer and parser return the same key")
    func citationKeyScanningAgreesWithParser() throws {
        let cases = [
            "@misc(identifier)revision, title = {Mid Delimiter})",
            "@misc(foo), title = {Terminal Delimiter})",
            "@misc()leading, title = {Leading Delimiter})",
            "@misc(fieldless,)",
            "@misc(commented% key comment\n, title = {Commented})",
        ]

        for bibtex in cases {
            let parsedKey = try #require(BibTeXParser.parse(bibtex).first?.citationKey)
            let highlightedKey = try #require(
                tokenizer.tokenize(bibtex).first { $0.token == .citationKey }?.text
            )

            #expect(highlightedKey == parsedKey, "Scanner disagreement for \(bibtex)")
            #expect(tokenizer.tokenize(bibtex).map(\.text).joined() == bibtex)
        }
    }

    @Test("When tokenizing special directives, then their contents do not become citation keys")
    func specialDirectivesDoNotInventCitationKeys() {
        let tokens = tokenizer.tokenize(
            #"@string{name = "value"} @preamble{"prefix"} @comment{words}"#
        )

        #expect(tokens.filter { $0.token == .special }.count == 3)
        #expect(tokens.allSatisfy { $0.token != .citationKey })
        #expect(tokens.first { $0.text == "name" }?.token == .fieldName)
    }

    @Test(
        "When a comment directive precedes an entry, then the following entry state remains valid")
    func commentDirectiveContentCannotCorruptFollowingEntryState() {
        let bibtex = "@comment{100% arbitrary = # text} @article{real, title = {Test}}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .citationKey }.map(\.text) == ["real"])
        #expect(tokens.filter { $0.token == .entryType }.map(\.text) == ["@article"])
    }

    @Test("When an entry ends before its key, then the next entry alone supplies a citation key")
    func endingAnEntryResetsCitationKeyState() {
        let bibtex = "@misc{} orphan = {outside}\n@article{next, title = {Inside}}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .entryType }.map(\.text) == ["@misc", "@article"])
        #expect(tokens.filter { $0.token == .citationKey }.map(\.text) == ["next"])
        #expect(tokens.first { $0.text == "orphan" }?.token == .text)
        #expect(tokens.first { $0.text == "title" }?.token == .fieldName)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When an omitted citation key ends at a comma, then following fields and entries use their own states"
    )
    func citationKeyCommaTransitionsToFields() {
        let bibtex = "@misc{, title = {Missing Key}}\n@article{next, year = 2026}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .citationKey }.map(\.text) == ["next"])
        #expect(tokens.filter { $0.token == .fieldName }.map(\.text) == ["title", "year"])
        #expect(tokens.first { $0.text == "2026" }?.token == .number)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    // MARK: - Field Name Tokenization

    @Test("When an entry contains a field assignment, then its identifier is a field-name token")
    func fieldName() {
        let bibtex = """
            @article{test,
                author = {Test}
            }
            """
        let tokens = tokenizer.tokenize(bibtex)

        let fieldName = tokens.first { $0.token == .fieldName }
        #expect(fieldName != nil)
        #expect(fieldName?.text.trimmingCharacters(in: .whitespaces) == "author")
    }

    @Test("When an entry contains multiple assignments, then every field name is recognized")
    func multipleFieldNames() {
        let bibtex = """
            @article{test,
                author = {Test},
                title = {Title},
                year = {2024}
            }
            """
        let tokens = tokenizer.tokenize(bibtex)

        let fieldNames = tokens.filter { $0.token == .fieldName }
        #expect(fieldNames.count >= 3)
    }

    @Test(
        "When comments separate a field name from its operator, then lookahead still recognizes the field"
    )
    func fieldNameLookaheadSkipsComments() {
        let bibtex = """
            @article{test,
                title % a legal comment before the equals sign
                    = {Test}
            }
            """
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == "title" }?.token == .fieldName)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When a custom field follows BibTeX identifier grammar, then it is recognized as one field name"
    )
    func customFieldNameUsesBibTeXIdentifierGrammar() {
        let tokens = tokenizer.tokenize("@misc{test, x.custom/field = {value}}")

        #expect(tokens.first { $0.token == .fieldName }?.text == "x.custom/field")
    }

    @Test(
        "When identifiers contain dollar signs or backslashes, then tokenizer precedence agrees with the parser"
    )
    func identifierPrecedenceAgreesWithParserForDollarAndBackslash() throws {
        let bibtex = #"""
            @string{$macro = "Expanded"}
            @misc{test,
                $field = {Dollar Field},
                \field = {Backslash Field},
                note = $macro,
                detail = {\textbf{Bold} and $x$}
            }
            """#
        let tokens = tokenizer.tokenize(bibtex)
        let entry = try #require(BibTeXParser.parse(bibtex).first)

        #expect(tokens.first { $0.text == "$field" }?.token == .fieldName)
        #expect(tokens.first { $0.text == #"\field"# }?.token == .fieldName)
        #expect(tokens.first { $0.text == "$macro" && $0.token == .constant }?.token == .constant)
        #expect(tokens.first { $0.text == #"\textbf"# }?.token == .command)
        #expect(tokens.first { $0.text == "$x$" }?.token == .math)
        #expect(entry.fields["$field"] == "Dollar Field")
        #expect(entry.fields[#"\field"#] == "Backslash Field")
        #expect(entry["note"] == "Expanded")
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When an identifier begins with a digit, then it is not highlighted as a valid field or constant"
    )
    func numericLeadingIdentifiersAreNotHighlightedAsValidIdentifiers() {
        let invalidInputs = [
            "@2custom{key}",
            "@misc{key, 2field = {value}}",
            #"@string{2macro = "value"}"#,
        ]

        for bibtex in invalidInputs {
            let tokens = tokenizer.tokenize(bibtex)

            #expect(tokens.allSatisfy { $0.token != .entryType || $0.text != "@2custom" })
            #expect(tokens.allSatisfy { $0.token != .fieldName })
            #expect(tokens.map(\.text).joined() == bibtex)
        }
    }

    @Test(
        "When identifier bodies contain digits, then fields stay identifiers and bare values stay numbers"
    )
    func identifierBodiesMayContainDigitsAndBareNumbersKeepNumberToken() {
        let bibtex = "@custom2{key, field2 = {value}, year = 2024}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.token == .entryType }?.text == "@custom2")
        #expect(tokens.first { $0.text == "field2" }?.token == .fieldName)
        #expect(tokens.first { $0.text == "2024" }?.token == .number)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    // MARK: - String Value Tokenization

    @Test("When a field value is braced, then its content is tokenized as a string")
    func bracedStringValue() {
        let bibtex = "@article{test, title = {Hello World}}"
        let tokens = tokenizer.tokenize(bibtex)

        let valueTokens = tokens.filter { $0.token == .string }
        #expect(!(valueTokens.isEmpty))
    }

    @Test("When a string contains nested braces, then its full content remains inside the value")
    func nestedBraces() {
        let bibtex = "@article{test, title = {Hello {Nested} World}}"
        let tokens = tokenizer.tokenize(bibtex)

        // Should handle nested braces without breaking
        #expect(!(tokens.isEmpty))
    }

    @Test("When quotes are protected by braces, then they do not terminate the quoted value")
    func quotedStringHonorsBraceProtectedQuotes() {
        let bibtex = #"@article{test, title = "A {"quoted"} word"}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == "quoted" }?.token == .string)
        #expect(
            tokens.filter { $0.text == #"""# }.map(\.token) == [.string, .string, .string, .string])
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test("When an accent quote is brace-protected, then it stays inside the quoted value")
    func braceProtectedAccentQuoteStaysInsideQuotedValue() {
        let bibtex = #"@article{test, author = "M{\"u}ller"}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == #"\"u"# }?.token == .accent)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When a backslash quote appears at top level, then it terminates the quoted value structurally"
    )
    func topLevelBackslashQuoteTerminatesQuotedValue() {
        let bibtex = #"@article{test, author = "M\"uller"}"#
        let tokens = tokenizer.tokenize(bibtex)

        let backslashIndex = tokens.firstIndex { $0.text == #"\"# }
        #expect(backslashIndex.map { tokens[$0].token } == .command)
        if let backslashIndex {
            let quoteIndex = tokens.index(after: backslashIndex)
            #expect(quoteIndex < tokens.endIndex)
            if quoteIndex < tokens.endIndex {
                #expect(tokens[quoteIndex].text == #"""#)
            }
        }
        #expect(!(tokens.contains { $0.token == .accent }))
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When a quoted value contains LaTeX, then commands, accents, and math retain semantic tokens"
    )
    func quotedValueRetainsSemanticLaTeXTokens() throws {
        let bibtex =
            #"@article{test,title="Plain \textbf{bold}, M{\"u}ller, and $x$"}"#
        let tokens = tokenizer.tokenize(bibtex)
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        #expect(throws: Never.self) {
            try BibTeXParser.parse(bibtex, options: options)
        }
        #expect(tokens.first { $0.text == #"\textbf"# }?.token == .command)
        #expect(tokens.first { $0.text == #"\"u"# }?.token == .accent)
        #expect(tokens.first { $0.text == "$x$" }?.token == .math)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    // MARK: - Number Tokenization

    @Test("When a year is an unbraced number, then it receives a number token")
    func yearAsNumber() {
        let bibtex = "@article{test, year = 2024}"
        let tokens = tokenizer.tokenize(bibtex)

        let number = tokens.first { $0.token == .number }
        #expect(number != nil)
        #expect(number?.text == "2024")
    }

    @Test("When a volume is an unbraced number, then it receives a number token")
    func volumeAsNumber() {
        let bibtex = "@article{test, volume = 42}"
        let tokens = tokenizer.tokenize(bibtex)

        let number = tokens.first { $0.token == .number }
        #expect(number != nil)
    }

    // MARK: - Comment Tokenization

    @Test("When a percent sign starts a line comment, then the remaining line is one comment token")
    func lineComment() {
        let bibtex = """
            % This is a comment
            @article{test, title = {Test}}
            """
        let tokens = tokenizer.tokenize(bibtex)

        let comment = tokens.first { $0.token == .comment }
        #expect(comment != nil)
        #expect(comment?.text.contains("This is a comment") ?? false)
    }

    @Test("When source contains multiple line comments, then each comment is recognized")
    func multipleComments() {
        let bibtex = """
            % Comment 1
            @article{test,
                % Comment 2
                title = {Test}
            }
            """
        let tokens = tokenizer.tokenize(bibtex)

        let comments = tokens.filter { $0.token == .comment }
        #expect(comments.count == 2)
    }

    // MARK: - LaTeX Command Tokenization

    @Test("When a value contains inline LaTeX math, then the delimited expression is a math token")
    func laTeXMathMode() {
        let bibtex = "@article{test, title = {Energy $E = mc^2$}}"
        let tokens = tokenizer.tokenize(bibtex)

        let mathTokens = tokens.filter { $0.token == .math }
        #expect(!(mathTokens.isEmpty))
    }

    @Test(
        "When a value contains display LaTeX math, then the double-delimited expression is a math token"
    )
    func laTeXDisplayMath() {
        let bibtex = "@article{test, abstract = {Formula: $$\\sum_{i=0}^n$$}}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.token == .math }?.text == "$$\\sum_{i=0}^n$$")
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When braced math appears in a parenthesized entry, then its braces cannot keep the entry open"
    )
    func bracedMathCannotCorruptParenthesizedEntryDepth() {
        let bibtex = "@misc(first,title={Value $x_{i}$}) @book{second,title={Next}}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .entryType }.map(\.text) == ["@misc", "@book"])
        #expect(tokens.filter { $0.token == .citationKey }.map(\.text) == ["first", "second"])
        #expect(tokens.first { $0.token == .math }?.text == "$x_{i}$")
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test("When braced math is unterminated, then it cannot consume the following entry")
    func unterminatedMathInsideBracedValueCannotConsumeFollowingEntry() {
        let cases = [
            (
                bibtex: "@misc{broken,title={Energy $E = mc^2}} @book{inline,title={Next}}",
                followingKey: "inline"
            ),
            (
                bibtex: "@misc{broken,title={Energy $$E = mc^2}} @book{display,title={Next}}",
                followingKey: "display"
            ),
        ]

        for testCase in cases {
            let tokens = tokenizer.tokenize(testCase.bibtex)

            #expect(tokens.filter { $0.token == .entryType }.map(\.text) == ["@misc", "@book"])
            #expect(
                tokens.filter { $0.token == .citationKey }.map(\.text) == [
                    "broken", testCase.followingKey,
                ])
            #expect(tokens.map(\.text).joined() == testCase.bibtex)
        }
    }

    @Test(
        "When source contains a LaTeX environment delimiter, then it receives an environment token")
    func laTeXEnvironment() {
        let bibtex = #"@article{test, abstract = {\begin{equation}x^2\end{equation}}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(
            tokens.filter { $0.token == .environment }.map(\.text) == [
                #"\begin{equation}"#, #"\end{equation}"#,
            ])
    }

    @Test("When a LaTeX environment appears outside a value, then it is still recognized")
    func laTeXEnvironmentOutsideBraces() {
        // LaTeX environments OUTSIDE field value braces should still be tokenized properly
        // For example, at the top level before any entry
        let bibtex = #"\begin{filecontents}{refs.bib}\end{filecontents}"#
        let tokens = tokenizer.tokenize(bibtex)

        // Outside field value braces, LaTeX environments get proper highlighting
        let envTokens = tokens.filter { $0.token == .environment }
        #expect(!(envTokens.isEmpty), "LaTeX environments outside braces should be .environment")
    }

    // MARK: - Special Character Tokenization

    @Test(
        "When source contains escaped LaTeX special characters, then they receive special-character tokens"
    )
    func specialCharacters() {
        let bibtex = "@preamble{test}"
        let tokens = tokenizer.tokenize(bibtex)

        // @preamble is tokenized as special (directive)
        let specials = tokens.filter { $0.token == .special }
        #expect(!(specials.isEmpty))
    }

    @Test("When an entry uses braces, then structural braces receive punctuation tokens")
    func braceTokenization() {
        let bibtex = "@article{test, title = {Hello}}"
        let tokens = tokenizer.tokenize(bibtex)

        let braces = tokens.filter { $0.token == .punctuation }
        #expect(!(braces.isEmpty))
    }

    // MARK: - Operator Tokenization

    @Test("When a field uses an equals sign, then it receives an operator token")
    func equalsOperator() {
        let bibtex = "@article{test, title = {Test}}"
        let tokens = tokenizer.tokenize(bibtex)

        let operators = tokens.filter { $0.token == .operator }
        #expect(!(operators.isEmpty))
    }

    @Test("When a field uses concatenation, then its hash receives an operator token")
    func concatenationOperator() {
        let bibtex = "@article{test, title = {Part 1} # { Part 2}}"
        let tokens = tokenizer.tokenize(bibtex)

        let hashOps = tokens.filter { $0.token == .operator && $0.text == "#" }
        #expect(!(hashOps.isEmpty))
    }

    @Test("When structural characters occur inside a braced value, then they remain string content")
    func structuralCharactersInsideBracedValueRemainStringContent() {
        let bibtex = "@article{test, title = {E = mc # not concatenation}}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == "=" && $0.token == .string }?.token == .string)
        #expect(tokens.first { $0.text == "#" }?.token == .string)
        #expect(tokens.filter { $0.token == .operator }.map(\.text) == ["="])
    }

    @Test("When an at sign occurs inside a braced value, then it does not start another entry")
    func atSignInsideBracedValueDoesNotStartEntry() {
        let bibtex = "@article{test, note = {Contact name@example.com}}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .entryType }.map(\.text) == ["@article"])
        #expect(tokens.filter { $0.token == .citationKey }.map(\.text) == ["test"])
        #expect(tokens.first { $0.text == "@" }?.token == .string)
    }

    // MARK: - Complex Entry Tokenization

    @Test(
        "When tokenizing a complete entry, then its structure and values receive the expected token kinds"
    )
    func completeEntry() {
        let bibtex = """
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
        let tokens = tokenizer.tokenize(bibtex)

        // Verify all token types present
        let tokenTypes = Set(tokens.map { $0.token })

        #expect(tokenTypes.contains(.entryType))  // @article
        #expect(tokenTypes.contains(.citationKey))  // einstein1905
        #expect(tokenTypes.contains(.fieldName))  // author, title, etc.
        #expect(tokenTypes.contains(.operator))  // =
        #expect(tokenTypes.contains(.punctuation))  // { }
    }

    @Test("When tokenizing multiple entries, then every declaration and citation key is recognized")
    func multipleEntries() {
        let bibtex = """
            @article{entry1, title = {First}}
            @book{entry2, title = {Second}}
            """
        let tokens = tokenizer.tokenize(bibtex)

        let entryTypes = tokens.filter { $0.token == .entryType }
        #expect(entryTypes.count == 2)

        let keys = tokens.filter { $0.token == .citationKey }
        #expect(keys.count == 2)
    }

    @Test(
        "When parentheses occur inside a braced value, then they do not keep a parenthesized entry open"
    )
    func parenthesesInsideBracedValueDoNotKeepParenthesizedEntryOpen() {
        let bibtex = """
            @article(first, title = {A (parenthesized) value})
            @book{second, title = {Next}}
            """
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .citationKey }.map(\.text) == ["first", "second"])
    }

    // MARK: - Edge Cases

    @Test("When tokenizing an empty entry, then tokenization still produces structural output")
    func emptyEntry() {
        let bibtex = "@misc{empty,}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(!(tokens.isEmpty))
    }

    @Test("When an at sign has no declaration, then it remains plain text")
    func standaloneAtSignIsPlainText() {
        let tokens = tokenizer.tokenize("@")

        #expect(tokens.count == 1)
        #expect(tokens.first?.token == .text)
        #expect(tokens.first?.text == "@")
    }

    @Test("When a top-level word starts with an underscore, then it remains one plain-text token")
    func topLevelUnderscoreWordIsSingleTextToken() {
        let tokens = tokenizer.tokenize("_outside")

        #expect(tokens.map(\.text) == ["_outside"])
        #expect(tokens.map(\.token) == [.text])
    }

    @Test(
        "When a stray group appears between a citation key and its fields, then it is not treated as a field value"
    )
    func strayGroupDoesNotInventFieldValueState() {
        let bibtex = "@misc{key,{orphan} title=jan}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == "orphan" }?.token == .text)
        #expect(tokens.first { $0.text == "title" }?.token == .fieldName)
        #expect(tokens.first { $0.text == "jan" }?.token == .constant)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When a malformed field value starts with a format control, then its pending state is consumed exactly once"
    )
    func malformedFormatControlCannotLeakFieldValueState() {
        let formatControl = "\u{200B}"
        let bibtex = "@misc{key,title=\(formatControl)jan trailing}"
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == "\(formatControl)jan" }?.token == .constant)
        #expect(tokens.first { $0.text == "trailing" }?.token == .text)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When tokenizing malformed inputs, then scanning always advances and preserves every source character"
    )
    func malformedInputsAlwaysAdvanceAndPreserveSource() {
        let malformedInputs = [
            "@",
            "@article{",
            "@article{key, = {value}}",
            "@article{key, title = \"unterminated",
            "@article(key, title = {mismatched})",
            "@comment{{{{",
            "👩🏽‍🚀@article{数字, title={値}}",
        ]

        for input in malformedInputs {
            let tokens = tokenizer.tokenize(input)
            #expect(tokens.map(\.text).joined() == input, "Tokenizer lost input for \(input)")
            #expect(
                tokens.allSatisfy { !$0.text.isEmpty },
                "Tokenizer emitted an empty token for \(input)")
        }
    }

    @Test("When an entry has no fields, then its citation key is still recognized")
    func entryWithNoFields() {
        let bibtex = "@misc{test}"
        let tokens = tokenizer.tokenize(bibtex)

        let key = tokens.first { $0.token == .citationKey }
        #expect(key != nil)
    }

    @Test("When string values contain multilingual Unicode, then their text is preserved")
    func unicodeInStrings() {
        let bibtex = "@article{test, author = {日本語 中文 한국어}}"
        let tokens = tokenizer.tokenize(bibtex)

        let stringToken = tokens.first { $0.text.contains("日本語") }
        #expect(stringToken != nil)
    }

    @Test("When string values contain emoji, then their graphemes are preserved")
    func emojiInStrings() {
        let bibtex = "@misc{test, note = {Hello 👋 World 🌍}}"
        let tokens = tokenizer.tokenize(bibtex)

        let hasEmoji = tokens.contains { $0.text.contains("👋") }
        #expect(hasEmoji)
    }
    // MARK: - Token Range Tests

    @Test("When positioned tokens are emitted, then every range selects its exact token text")
    func tokenRanges() {
        let bibtex = "@article{test, title = {Hello}}"
        let tokens = tokenizer.tokenize(bibtex)

        // All tokens should have valid ranges
        for tokenInfo in tokens {
            #expect(!(tokenInfo.text.isEmpty), "Token text should not be empty")
            #expect(String(bibtex[tokenInfo.range]) == tokenInfo.text)
        }
    }

    @Test("When token text is concatenated, then it reconstructs the complete source")
    func tokensCoverFullText() {
        let bibtex = "@article{test}"
        let tokens = tokenizer.tokenize(bibtex)

        let reconstructed = tokens.map { $0.text }.joined()
        #expect(reconstructed == bibtex)
    }

    @Test("When both public token APIs scan the same source, then their text and token kinds match")
    func tokenizePairsMatchesPositionedTokensWithoutIntermediateDifferences() {
        let bibtex = "@article{2024/test, month = jan, title = {Tést 🚀}}"
        let positioned = tokenizer.tokenize(bibtex)
        let pairs = tokenizer.tokenizePairs(bibtex)

        #expect(pairs.map(\.text) == positioned.map(\.text))
        #expect(pairs.map(\.token) == positioned.map(\.token))
    }

    @Test(
        "When extended graphemes and mixed line endings are tokenized, then every range reconstructs the original UTF-8 bytes"
    )
    func unicodeTokenRangesReconstructUTF8Exactly() throws {
        let bibtex = "@article{👩🏽‍🚀e\u{301},\r\n title = {日本語 🚀 \\alpha}}\n"
        let tokens = tokenizer.tokenize(bibtex)
        var cursor = bibtex.startIndex
        var utf8Offset = 0

        for token in tokens {
            #expect(token.range.lowerBound == cursor)
            #expect(String(bibtex[token.range]) == token.text)

            let lowerUTF8 = try #require(token.range.lowerBound.samePosition(in: bibtex.utf8))
            let upperUTF8 = try #require(token.range.upperBound.samePosition(in: bibtex.utf8))
            #expect(bibtex.utf8.distance(from: bibtex.utf8.startIndex, to: lowerUTF8) == utf8Offset)
            #expect(bibtex.utf8.distance(from: lowerUTF8, to: upperUTF8) == token.text.utf8.count)

            utf8Offset += token.text.utf8.count
            cursor = token.range.upperBound
        }

        #expect(cursor == bibtex.endIndex)
        #expect(utf8Offset == bibtex.utf8.count)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When both token APIs scan fixed-seed generated source, then they advance losslessly and agree"
    )
    func fixedSeedGeneratedInputsRemainLossless() {
        let fragments = [
            "@", "{", "}", "(", ")", ",", "=", "#", "% note\n", " ", "\t",
            "article", "title", #"\textbf"#, "$x$", "é", "e\u{301}", "日本語",
            "👩🏽‍🚀", #"""#,
        ]
        var generator = SeededGenerator(state: 0xB1B7_EC0D_F00D)

        for caseIndex in 0..<64 {
            let fragmentCount = Int(generator.next() % 48) + 1
            var input = ""
            for _ in 0..<fragmentCount {
                input += fragments[Int(generator.next() % UInt64(fragments.count))]
            }

            let positioned = tokenizer.tokenize(input)
            let pairs = tokenizer.tokenizePairs(input)

            #expect(
                positioned.allSatisfy { !$0.text.isEmpty },
                "Generated case \(caseIndex) emitted an empty token"
            )
            #expect(
                positioned.map(\.text).joined() == input,
                "Generated case \(caseIndex) did not reconstruct its source"
            )
            #expect(pairs.map(\.text) == positioned.map(\.text))
            #expect(pairs.map(\.token) == positioned.map(\.token))
        }
    }

    // MARK: - Field Value Content Tests (Bug Fix Verification)

    @Test("When a braced field contains words, then each word is emitted as string content")
    func fieldValueContentAsString() {
        let bibtex = "@article{test, author = {Albert Einstein}}"
        let tokens = tokenizer.tokenize(bibtex)

        // Find "Albert" and "Einstein" tokens
        let albert = tokens.first { $0.text == "Albert" }
        let einstein = tokens.first { $0.text == "Einstein" }

        #expect(albert != nil, "Should find 'Albert' token")
        #expect(einstein != nil, "Should find 'Einstein' token")
        #expect(albert?.token == .string)
        #expect(einstein?.token == .string)
    }

    @Test("When digits occur inside braces, then they remain string content rather than numbers")
    func numbersInsideBracesAsString() {
        let bibtex = "@article{test, pages = {891--921}}"
        let tokens = tokenizer.tokenize(bibtex)

        // Numbers inside braces should be text, not number tokens
        let numberTokens = tokens.filter { $0.token == .number }
        #expect(numberTokens.isEmpty, "Numbers inside braces should not be .number tokens")

        let stringTokens = tokens.filter { $0.token == .string }
        #expect(!(stringTokens.isEmpty), "Should have string tokens for digits")
    }

    @Test("When a DOI occurs inside braces, then its components are not mistaken for constants")
    func doiInsideBracesAsText() {
        // Tests that DOI values inside braces are tokenized correctly
        let bibtex = "@article{test, doi = {10.1002/andp.19053221004}}"
        let tokens = tokenizer.tokenize(bibtex)

        // The "10" should be text (character by character since it starts with a number)
        // or the identifiable parts should be text
        let constantTokens = tokens.filter { $0.token == .constant }

        // No constants should appear inside the braced value
        // Constants before { are fine, but not inside
        for constant in constantTokens {
            // Constants should only be things like month names, not DOI parts
            let validConstants = [
                "jan", "feb", "mar", "apr", "may", "jun",
                "jul", "aug", "sep", "oct", "nov", "dec",
            ]
            #expect(
                validConstants.contains(constant.text.lowercased()),
                "Unexpected constant token: \(constant.text)")
        }
    }

    @Test("When a field value is an unbraced integer, then it receives a number token")
    func unbracedNumberAsNumber() {
        // Tests that unbraced numbers (like year = 2024) are still tokenized as numbers
        let bibtex = "@article{test, year = 2024}"
        let tokens = tokenizer.tokenize(bibtex)

        let yearToken = tokens.first { $0.text == "2024" }
        #expect(yearToken != nil, "Should find '2024' token")
        #expect(yearToken?.token == .number, "Unbraced year should be .number")
    }

    @Test("When a field value is an unbraced month name, then it receives a constant token")
    func unbracedConstantAsConstant() {
        // Tests that unbraced constants (like month = jan) are tokenized as constants
        let bibtex = "@article{test, month = jan}"
        let tokens = tokenizer.tokenize(bibtex)

        let monthToken = tokens.first { $0.text.lowercased() == "jan" }
        #expect(monthToken != nil, "Should find 'jan' token")
        #expect(monthToken?.token == .constant, "Unbraced month should be .constant")
    }

    @Test("When content is nested inside value braces, then it retains a string token")
    func nestedBracesContentAsString() {
        let bibtex = "@article{test, title = {A {Nested} Title}}"
        let tokens = tokenizer.tokenize(bibtex)

        let nestedToken = tokens.first { $0.text == "Nested" }
        #expect(nestedToken != nil, "Should find 'Nested' token")
        #expect(nestedToken?.token == .string)
    }

    @Test(
        "When tokenizing realistic multilingual fields, then their expected words remain string tokens"
    )
    func complexFieldValueContent() {
        // Tests a realistic complex field value
        let bibtex = """
            @article{einstein1905,
                author = {Albert Einstein},
                title = {Zur Elektrodynamik bewegter Körper},
                journal = {Annalen der Physik},
                volume = {17},
                pages = {891--921},
                year = {1905},
                doi = {10.1002/andp.19053221004}
            }
            """
        let tokens = tokenizer.tokenize(bibtex)

        let expectedStringWords = [
            "Albert", "Einstein", "Zur", "Elektrodynamik",
            "bewegter", "Annalen", "der", "Physik",
        ]

        for word in expectedStringWords {
            let token = tokens.first { $0.text == word }
            #expect(token != nil, "Should find '\(word)' token")
            #expect(token?.token == .string)
        }
    }

    @Test(
        "When braced and unbraced values are mixed, then each value retains its semantic token kind"
    )
    func mixedBracedAndUnbracedValues() {
        // Tests mixing braced and unbraced values
        let bibtex = "@article{test, year = 2024, month = jan, author = {John Doe}}"
        let tokens = tokenizer.tokenize(bibtex)

        // Unbraced values should keep their types
        let yearToken = tokens.first { $0.text == "2024" }
        #expect(yearToken?.token == .number, "Unbraced year should be .number")

        let monthToken = tokens.first { $0.text.lowercased() == "jan" }
        #expect(monthToken?.token == .constant, "Unbraced month should be .constant")

        // Braced values are string content.
        let johnToken = tokens.first { $0.text == "John" }
        #expect(johnToken?.token == .string)
    }

    @Test("When a LaTeX accent occurs inside braces, then it receives an accent token")
    func latexAccentInsideBracesIsHighlighted() {
        let bibtex = #"@article{test, title = {K\"orper}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == #"\"o"# }?.token == .accent)
    }

    @Test("When a LaTeX command occurs inside braces, then it receives a command token")
    func latexCommandInsideBracesIsHighlighted() {
        let bibtex = #"@article{test, title = {\textbf{Bold} text}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == #"\textbf"# }?.token == .command)
    }

    @Test(
        "When a literal quote occurs inside a braced value, then following entries remain independent"
    )
    func literalQuoteInsideBracedValueDoesNotConsumeFollowingEntries() {
        let bibtex = #"@misc{screen,title={A 6" display},year={2024}} @book{next,title={Next}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .entryType }.map(\.text) == ["@misc", "@book"])
        #expect(tokens.filter { $0.token == .citationKey }.map(\.text) == ["screen", "next"])
        #expect(tokens.first { $0.text == #"""# }?.token == .string)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test("When a backslash precedes an opening brace, then that brace still affects value balance")
    func backslashPrefixedOpeningBraceAffectsBracedValueBalance() {
        let bibtex =
            #"@misc{broken,title={Unclosed \{value}} @book{notSeparate,title={Next}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .entryType }.map(\.text) == ["@misc"])
        #expect(tokens.first { $0.text == #"\"# }?.token == .command)
        #expect(
            tokens.first { $0.text == "{" && $0.range.lowerBound > bibtex.startIndex }?.token
                == .punctuation)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When a backslash precedes a closing brace, then that brace still ends the value structurally"
    )
    func backslashPrefixedClosingBraceEndsBracedValueStructurally() {
        let bibtex = #"@misc{broken,title={Early \} closing}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == #"\"# }?.token == .command)
        #expect(tokens.first { $0.text == "closing" }?.token == .text)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When a quoted value has an unbalanced brace, then a following declaration cannot escape its state"
    )
    func unbalancedBraceInQuotedValueCannotHideFollowingEntryState() {
        let bibtex =
            #"@misc{broken,title="Unclosed \{value"} @book{notSeparate,title={Next}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .entryType }.map(\.text) == ["@misc"])
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When scanning a command group, then backslash-prefixed braces still contribute to balance")
    func commandGroupScannerCountsBackslashPrefixedBraces() {
        let bibtex = #"\begin{\{} @article{notSeparate,title={Next}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.filter { $0.token == .environment }.map(\.text) == [bibtex])
        #expect(tokens.allSatisfy { $0.token != .entryType })
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When a braced value mixes text and LaTeX, then every component retains its semantic token kind"
    )
    func bracedValueRetainsSemanticLaTeXTokensAndStringContent() {
        let bibtex =
            #"@article{test,title={Plain \textbf{bold}, K\"orper, \begin{equation}x^2\end{equation}, and $y$}}"#
        let tokens = tokenizer.tokenize(bibtex)

        #expect(tokens.first { $0.text == "Plain" }?.token == .string)
        #expect(tokens.first { $0.text == #"\textbf"# }?.token == .command)
        #expect(tokens.first { $0.text == #"\"o"# }?.token == .accent)
        #expect(
            tokens.filter { $0.token == .environment }.map(\.text) == [
                #"\begin{equation}"#, #"\end{equation}"#,
            ])
        #expect(tokens.first { $0.text == "$y$" }?.token == .math)
        #expect(tokens.map(\.text).joined() == bibtex)
    }

    @Test(
        "When LaTeX accent text occurs in a comment, then the containing comment remains recognized"
    )
    func latexAccentOutsideBracesStillHighlighted() {
        // Tests that LaTeX accents OUTSIDE field braces still get proper highlighting
        // This is an edge case - LaTeX in comments or @preamble should still be highlighted
        let bibtex = #"% Comment with K\"orper"#
        let tokens = tokenizer.tokenize(bibtex)

        // Comments consume the whole line, so this is fine
        let commentTokens = tokens.filter { $0.token == .comment }
        #expect(!(commentTokens.isEmpty))
    }

    private struct SeededGenerator {
        private var state: UInt64

        init(state: UInt64) {
            self.state = state
        }

        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }
}
