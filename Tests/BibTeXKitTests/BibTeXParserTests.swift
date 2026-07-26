//
//  BibTeXParserTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Testing

@testable import BibTeXKit

@Suite("Given BibTeX parser input")
struct BibTeXParserTests {
    struct ErrorScenario: Sendable {
        let input: String
        let expected: BibTeXParser.Error
    }

    // MARK: - Basic Parsing Tests

    @Test("When input is empty, then parsing throws emptyInput")
    func parseEmptyString() throws {
        #expect(throws: BibTeXParser.Error.emptyInput) {
            try BibTeXParser.parse("")
        }
    }

    @Test("When input contains only whitespace, then parsing throws emptyInput")
    func parseWhitespaceOnly() throws {
        #expect(throws: BibTeXParser.Error.emptyInput) {
            try BibTeXParser.parse("   \n\t   ")
        }
    }

    @Test("When input has no BibTeX entries, then default parsing returns an empty array")
    func parseNonEntryContentReturnsEmptyByDefault() throws {
        #expect(try BibTeXParser.parse("This is not BibTeX.") == [])
    }

    @Test("When input has only comments and directives, then default parsing returns no entries")
    func parseCommentAndDirectiveOnlyInputReturnsEmptyByDefault() throws {
        let bibtex = """
            % no bibliography entries
            @comment{also ignored}
            @string{journalName = "Journal of Testing"}
            @preamble{"Generated bibliography"}
            """

        #expect(try BibTeXParser.parse(bibtex) == [])
        #expect(BibTeXParser.parseOrNil(bibtex) == [])
    }

    @Test("When strict parsing finds no entry, then it throws noEntriesFound")
    func strictOptionsRequireAtLeastOneEntry() {
        #expect(throws: BibTeXParser.Error.noEntriesFound) {
            try BibTeXParser.parse(
                "@comment{no entries}",
                options: .strict
            )
        }
    }

    @Test("When requireEntries sees directive-only input, then it throws noEntriesFound")
    func requireEntriesOptionRejectsEntryFreeInput() {
        let options = BibTeXParser.Options(requireEntries: true)

        #expect(throws: BibTeXParser.Error.noEntriesFound) {
            try BibTeXParser.parse(
                "@string{name = \"value\"}",
                options: options
            )
        }
    }

    @Test("When every parsing option is supplied, then all five values are retained")
    func completeOptionsInitializerRetainsEveryValue() {
        let options = BibTeXParser.Options(
            preserveRawBibTeX: true,
            normalizeFieldNames: false,
            stripDelimiters: false,
            convertLaTeXToUnicode: false,
            requireEntries: true
        )

        #expect(options.preserveRawBibTeX)
        #expect(!(options.normalizeFieldNames))
        #expect(!(options.stripDelimiters))
        #expect(!(options.convertLaTeXToUnicode))
        #expect(options.requireEntries)
    }

    @Test("When parsing one article, then one fully populated entry is returned")
    func parseSingleEntry() throws {
        let bibtex = """
            @article{test2024,
                author = {John Doe},
                title = {Test Article},
                year = {2024}
            }
            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.count == 1)
        #expect(entries.first?.type == .article)
        #expect(entries.first?.citationKey == "test2024")
        #expect(entries.first?["author"] == "John Doe")
        #expect(entries.first?["title"] == "Test Article")
        #expect(entries.first?["year"] == "2024")
    }

    @Test("When parsing multiple entries, then their types retain source order")
    func parseMultipleEntries() throws {
        let bibtex = """
            @article{entry1, title = {First}}
            @book{entry2, title = {Second}}
            @inproceedings{entry3, title = {Third}}
            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.count == 3)
        #expect(entries[0].type == .article)
        #expect(entries[1].type == .book)
        #expect(entries[2].type == .inproceedings)
    }

    // MARK: - Entry Type Tests

    @Test("When parsing standard entry declarations, then each maps to its expected type")
    func parseAllStandardTypes() throws {
        let types = [
            "article", "book", "booklet", "conference", "inbook",
            "incollection", "inproceedings", "manual", "mastersthesis",
            "misc", "phdthesis", "proceedings", "techreport", "unpublished",
        ]

        for type in types {
            let bibtex = "@\(type){test, title = {Test}}"
            let entries = try BibTeXParser.parse(bibtex)

            #expect(entries.count == 1, "Failed for type: \(type)")
            #expect(entries.first?.type.rawValue.lowercased() == type)
        }
    }

    @Test("When parsing an unknown entry declaration, then its custom type name is preserved")
    func parseCustomType() throws {
        let bibtex = "@customtype{mydata, title = {My Dataset}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.count == 1)
        #expect(entries.first?.type == .custom("customtype"))
    }

    @Test("When a custom type has whitespace and punctuation, then its entry parses completely")
    func parseWhitespaceSeparatedHyphenatedCustomType() throws {
        let entries = try BibTeXParser.parse(
            "@ custom-entry.type {custom-key, title = {Custom Entry}}"
        )

        #expect(entries.count == 1)
        #expect(entries.first?.type == .custom("custom-entry.type"))
        #expect(entries.first?.citationKey == "custom-key")
        #expect(entries.first?.title == "Custom Entry")
    }

    @Test("When an entry type uses uppercase letters, then it maps case-insensitively")
    func parseCaseInsensitiveType() throws {
        let bibtex = "@ARTICLE{test, title = {Test}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?.type == .article)
    }

    // MARK: - Field Parsing Tests

    @Test("When a field value uses braces, then its delimiters are removed")
    func parseFieldWithBraces() throws {
        let bibtex = "@article{test, title = {Hello World}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["title"] == "Hello World")
    }

    @Test("When a field value uses quotes, then its delimiters are removed")
    func parseFieldWithQuotes() throws {
        let bibtex = "@article{test, title = \"Hello World\"}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["title"] == "Hello World")
    }

    @Test("When a field value is numeric, then its digits are preserved as text")
    func parseFieldWithNumber() throws {
        let bibtex = "@article{test, year = 2024}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["year"] == "2024")
    }

    @Test("When a field contains nested braces, then its nested content is preserved")
    func parseNestedBraces() throws {
        let bibtex = "@article{test, title = {Hello {Nested {Deep}} World}}"
        let entries = try BibTeXParser.parse(bibtex)

        let title = entries.first?["title"]
        #expect(title != nil)
        #expect(title?.contains("Nested") ?? false)
    }

    @Test("When a braced value contains an equals sign, then it remains field content")
    func parseFieldWithEquals() throws {
        let bibtex = "@article{test, title = {E = mc^2}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["title"] == "E = mc^2")
    }

    @Test("When an entry has eight fields, then all fields and converted dashes are retained")
    func parseMultipleFields() throws {
        let bibtex = """
            @article{test,
                author = {John Doe},
                title = {Test Title},
                journal = {Test Journal},
                volume = {42},
                number = {7},
                pages = {100--200},
                year = {2024},
                doi = {10.1234/test}
            }
            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?.fields.count == 8)
        #expect(entries.first?["volume"] == "42")
        // LaTeX -- is converted to en-dash when convertLaTeXToUnicode is true (default)
        #expect(entries.first?["pages"] == "100–200")
    }

    @Test("When quoted and braced components concatenate, then one combined value is returned")
    func parseConcatenatedFieldComponents() throws {
        let bibtex = #"@article{test, title = "Hello " # {World} # "!"}"#
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.first?["title"] == "Hello World!")
    }

    @Test("When many mixed components concatenate, then their values join in source order")
    func parseArbitrarilyLongMixedConcatenation() throws {
        let bibtex = #"@article(test, value = 20 # 24 # "-" # suffix # { value})"#

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["value"] == "2024-suffix value")
    }

    @Test("When a comment separates concatenated components, then it is excluded from the value")
    func parseConcatenationSeparatedByComment() throws {
        let bibtex = """
            @article{test,
                title = "Hello " #
                    % The comment is syntax, not part of the value.
                    "World"
            }
            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["title"] == "Hello World")
    }

    @Test("When a string macro is referenced case-insensitively, then its expansion is resolved")
    func parseStringDirectiveAndCaseInsensitiveReference() throws {
        let bibtex = """
            @string{JournalName = "Journal of " # {Testing}}
            @article{test,
                journal = JOURNALNAME,
                month = jan
            }
            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.count == 1)
        #expect(entries.first?["journal"] == "Journal of Testing")
        #expect(entries.first?["month"] == "January")
    }

    @Test("When special directives surround an entry, then only the real entry is returned")
    func specialDirectivesDoNotBecomeBibliographyEntries() throws {
        let bibtex = #"""
            @comment{A nested {comment} that may contain @article{fake}}
            @preamble("\newcommand{\noop}{}" # middle # {) suffix})
            @article{real, title = {Real}}
            """#

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.map(\.citationKey) == ["real"])
    }

    @Test("When a custom field uses BibTeX punctuation, then its complete name is preserved")
    func customFieldNamesUseBibTeXIdentifierGrammar() throws {
        let bibtex = "@misc{test, x.custom/field = {supported}}"

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?.fields["x.custom/field"] == "supported")
    }

    @Test("When identifiers contain dollar signs or backslashes, then fields and macros resolve")
    func identifiersAllowDollarAndBackslashCharacters() throws {
        let bibtex = #"""
            @string{$macro = "Expanded"}
            @misc{test,
                $field = {Dollar Field},
                \field = {Backslash Field},
                note = $macro
            }
            """#

        let entry = try #require(BibTeXParser.parse(bibtex).first)

        #expect(entry.fields["$field"] == "Dollar Field")
        #expect(entry.fields[#"\field"#] == "Backslash Field")
        #expect(entry["note"] == "Expanded")
    }

    @Test("When identifiers contain digits, then names parse while bare numbers remain numeric")
    func identifierBodiesMayContainDigitsAndBareNumbersRemainValid() throws {
        let entry = try #require(
            BibTeXParser.parse("@custom2{key, field2 = {value}, year = 2024}").first
        )

        #expect(entry.type == .custom("custom2"))
        #expect(entry.fields["field2"] == "value")
        #expect(entry.year == 2024)
    }

    @Test("When an entry type starts with a digit, then parsing throws invalidEntryType")
    func entryTypesCannotBeginWithNumber() {
        #expect(
            throws: BibTeXParser.Error.invalidEntryType(position: 1)
        ) {
            try BibTeXParser.parse("@2custom{key}")
        }
    }

    @Test("When a field name starts with a digit, then parsing throws unexpectedCharacter")
    func fieldNamesCannotBeginWithNumber() {
        #expect(
            throws: BibTeXParser.Error.unexpectedCharacter(
                character: "2",
                position: 11
            )
        ) {
            try BibTeXParser.parse("@misc{key, 2field = {value}}")
        }
    }

    @Test("When a string macro starts with a digit, then parsing throws invalidFieldValue")
    func stringNamesCannotBeginWithNumber() {
        #expect(
            throws: BibTeXParser.Error.invalidFieldValue(
                field: "string",
                position: 8
            )
        ) {
            try BibTeXParser.parse(#"@string{2macro = "value"}"#)
        }
    }

    @Test("When a parenthesized entry has a braced value, then inner parentheses are preserved")
    func parenthesizedEntryWithBracedValue() throws {
        let entries = try BibTeXParser.parse("@article(test, title = {A (parenthesized) entry})")

        #expect(entries.first?["title"] == "A (parenthesized) entry")
    }

    @Test("When quotation marks are brace-protected, then they remain inside the quoted value")
    func quotedValueHonorsBraceProtectedQuotationMarks() throws {
        let bibtex = #"@article{test, title = "A {"quoted"} word"}"#
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.first?["title"] == #"A {"quoted"} word"#)
    }

    @Test("When backslashes prefix balanced braces, then their literal spelling is preserved")
    func backslashPrefixedBracesRemainBalancedStructuralBraces() throws {
        let bibtex = #"@article{test, title = {Use \{x\} safely}}"#
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.first?["title"] == #"Use \{x\} safely"#)
    }

    @Test("When quoted values contain unbalanced prefixed braces, then parsing rejects them")
    func quotedValuesRejectUnbalancedBackslashPrefixedBraces() {
        let malformedValues = [
            #"@article{test, title = "Unbalanced \{ opening"}"#,
            #"@article{test, title = "Unbalanced \} closing"}"#,
        ]

        for bibtex in malformedValues {
            #expect(throws: BibTeXParser.Error.self) {
                try BibTeXParser.parse(bibtex)
            }
        }
    }

    @Test("When braced values contain unbalanced prefixed braces, then parsing rejects them")
    func bracedValuesRejectUnbalancedBackslashPrefixedBraces() {
        let malformedValues = [
            #"@article{test, title = {Unbalanced \{ opening}}"#,
            #"@article{test, title = {Unbalanced \} closing}}"#,
        ]

        for bibtex in malformedValues {
            #expect(throws: BibTeXParser.Error.self) {
                try BibTeXParser.parse(bibtex)
            }
        }
    }

    @Test("When a top-level backslash quote reaches a value delimiter, then parsing rejects it")
    func topLevelBackslashQuoteDoesNotEscapeQuotedValueDelimiter() {
        #expect(throws: BibTeXParser.Error.self) {
            try BibTeXParser.parse(#"@article{test, author = "M\"uller"}"#)
        }
    }

    @Test("When an accent quote is brace-protected, then the quoted value preserves it")
    func braceProtectedAccentQuoteIsValidInsideQuotedValue() throws {
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        let entry = try #require(
            BibTeXParser.parse(
                #"@article{test, author = "M{\"u}ller"}"#,
                options: options
            ).first
        )

        #expect(entry.author == #"M{\"u}ller"#)
    }

    @Test("When a comment has an unmatched prefixed brace, then parsing reports unmatchedBraces")
    func commentDirectiveCountsBackslashPrefixedOpeningBrace() {
        #expect(
            throws: BibTeXParser.Error.unmatchedBraces(position: 8)
        ) {
            try BibTeXParser.parse(#"@comment{unclosed \{}"#)
        }
    }

    // MARK: - Key Parsing Tests

    @Test("When parsing a simple citation key, then its exact text is returned")
    func parseSimpleKey() throws {
        let bibtex = "@article{simplekey, title = {Test}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?.citationKey == "simplekey")
    }

    @Test("When a citation key contains digits, then its exact text is returned")
    func parseKeyWithNumbers() throws {
        let bibtex = "@article{author2024, title = {Test}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?.citationKey == "author2024")
    }

    @Test("When a citation key contains punctuation, then its exact text is returned")
    func parseKeyWithSpecialChars() throws {
        let bibtex = "@article{author:2024-paper_v1, title = {Test}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?.citationKey == "author:2024-paper_v1")
    }

    @Test("When a parenthesized key contains a close parenthesis, then the key preserves it")
    func parenthesizedEntryCitationKeyMayContainClosingParenthesis() throws {
        let entries = try BibTeXParser.parse(
            "@misc(identifier)revision, title = {Parenthesized Entry})"
        )

        #expect(entries.count == 1)
        #expect(entries.first?.citationKey == "identifier)revision")
        #expect(entries.first?.title == "Parenthesized Entry")
    }

    @Test("When a parenthesized key ends in a close parenthesis, then the key preserves it")
    func parenthesizedEntryCitationKeyMayEndWithClosingParenthesis() throws {
        let entries = try BibTeXParser.parse("@misc(foo), title = {Value})")

        #expect(entries.count == 1)
        #expect(entries.first?.citationKey == "foo)")
        #expect(entries.first?.title == "Value")
    }

    @Test("When a fieldless parenthesized entry has a comma, then it parses with no fields")
    func canonicalParenthesizedEntryWithoutFieldsUsesTrailingComma() throws {
        let entries = try BibTeXParser.parse("@misc(identifier,)")

        #expect(entries.count == 1)
        #expect(entries.first?.citationKey == "identifier")
        #expect(entries.first?.fields.isEmpty == true)
    }

    @Test("When a fieldless parenthesized entry omits its comma, then parsing rejects it")
    func ambiguousParenthesizedEntryWithoutCommaIsRejected() {
        #expect(
            throws: BibTeXParser.Error.unmatchedBraces(position: 5)
        ) {
            try BibTeXParser.parse("@misc(identifier)")
        }
    }

    @Test("When a comment follows a citation key, then the key stops before the percent sign")
    func citationKeyStopsBeforePercentComment() throws {
        let bibtex = """
            @misc(commented-key% citation-key comment
            , title = {Commented Key})
            """
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.count == 1)
        #expect(entries.first?.citationKey == "commented-key")
        #expect(entries.first?.title == "Commented Key")
    }

    // MARK: - LaTeX Handling Tests

    @Test("When LaTeX conversion is enabled, then accent commands become Unicode")
    func parseLaTeXAccents() throws {
        let bibtex = "@article{test, author = {M\\\"uller}}"
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = true

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.first?["author"] == "Müller")
    }

    @Test("When LaTeX conversion is disabled, then accent commands remain unchanged")
    func parseLaTeXWithoutConversion() throws {
        let bibtex = "@article{test, author = {M\\\"uller}}"
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.first?["author"] == "M\\\"uller")
    }

    @Test("When LaTeX conversion is enabled, then escaped percent content remains readable")
    func parseLaTeXSpecialChars() throws {
        let bibtex = "@article{test, title = {100\\% Complete}}"
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = true

        let entries = try BibTeXParser.parse(bibtex, options: options)

        let title = entries.first?["title"]
        #expect(title?.contains("100") ?? false)
    }

    @Test("When accents convert inside protected groups, then case-protection braces survive")
    func parsePreservesCaseProtectionWhileConvertingAccentArguments() throws {
        let bibtex = #"""
            @article{protected,
                title = {An {E}xample of {{Nested Protection}} at {\'{E}}cole},
                author = {Jos\'{e} {Garc\'{i}a}}
            }
            """#

        let entry = try #require(BibTeXParser.parse(bibtex).first)

        #expect(entry["title"] == "An {E}xample of {{Nested Protection}} at {É}cole")
        #expect(entry["author"] == "José {García}")
    }

    @Test("When protected fields round-trip through every format, then their values remain equal")
    func caseProtectionSurvivesParseFormatParseRoundTrip() throws {
        let bibtex = #"""
            @article{protected,
                title = {An {E}xample of {{Nested Protection}} at {\'{E}}cole},
                author = {Jos\'{e} {Garc\'{i}a}}
            }
            """#

        let parsed = try #require(BibTeXParser.parse(bibtex).first)

        for style in [
            BibTeXEntry.FormattingStyle.standard,
            .compact,
            .minimal,
            .aligned,
        ] {
            let reparsed = try #require(
                BibTeXParser.parse(parsed.formatted(style: style)).first
            )
            #expect(reparsed.fields == parsed.fields, "Failed for \(style)")
        }
    }

    // MARK: - Options Tests

    @Test("When preserveRawBibTeX is enabled, then the original declaration is retained")
    func optionsPreserveRawBibTeX() throws {
        let bibtex = "@article{test, title = {Test}}"
        var options = BibTeXParser.Options()
        options.preserveRawBibTeX = true

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.first?.rawBibTeX != nil)
        #expect(entries.first?.rawBibTeX?.contains("@article") ?? false)
    }

    @Test("When field-name normalization is enabled, then uppercase names resolve lowercase")
    func optionsNormalizeFieldNames() throws {
        let bibtex = "@article{test, TITLE = {Test}, AUTHOR = {Author}}"
        var options = BibTeXParser.Options()
        options.normalizeFieldNames = true

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.first?["title"] != nil)
        #expect(entries.first?["author"] != nil)
    }

    @Test("When delimiter stripping is enabled, then boundary whitespace is removed")
    func optionsStripDelimiters() throws {
        let bibtex = "@article{test, title = {  Test  }}"
        var options = BibTeXParser.Options()
        options.stripDelimiters = true

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.first?["title"] == "Test")
    }

    @Test("When multiline values are stripped, then every boundary newline and tab is removed")
    func stripDelimitersTrimsMultilineBoundaryWhitespace() throws {
        let bibtex =
            "@string{shared = \"\n\tShared Value\r\n\"}\n"
            + "@misc{test, title = {\n  Flight Control\n}, "
            + "note = \"\r\n  Quoted Value\t\n\", howpublished = shared}"

        let entry = try #require(BibTeXParser.parse(bibtex).first)

        #expect(entry["title"] == "Flight Control")
        #expect(entry["note"] == "Quoted Value")
        #expect(entry["howpublished"] == "Shared Value")
    }

    @Test(
        "When default options are created, then normalization, stripping, and conversion are enabled"
    )
    func defaultOptions() {
        let options = BibTeXParser.Options()

        #expect(options.normalizeFieldNames)
        #expect(options.stripDelimiters)
        #expect(options.convertLaTeXToUnicode)
        #expect(!(options.preserveRawBibTeX))
        #expect(!(options.requireEntries))
        #expect(BibTeXParser.Options.strict.requireEntries)
    }

    // MARK: - Error Handling Tests

    @Test("When an entry declaration omits its type, then parsing reports invalidEntryType")
    func invalidEntryType() throws {
        let bibtex = "@{test, title = {Test}}"

        #expect(
            throws: BibTeXParser.Error.invalidEntryType(position: 1)
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When a nested value lacks closing braces, then parsing reports unmatchedBraces")
    func missingClosingBrace() {
        let bibtex = "@article{test, title = {Unclosed"

        #expect(
            throws: BibTeXParser.Error.unmatchedBraces(position: 23)
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When an entry omits its citation key, then parsing reports missingCitationKey")
    func missingKey() throws {
        let bibtex = "@article{, title = {Test}}"

        #expect(
            throws: BibTeXParser.Error.missingCitationKey(
                entryType: "article",
                position: 9
            )
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When an entry lacks its outer closing brace, then parsing reports unmatchedBraces")
    func missingOuterClosingBrace() {
        let bibtex = "@article{test, title = {Closed}"

        #expect(
            throws: BibTeXParser.Error.unmatchedBraces(position: 8)
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When a quoted field is unterminated, then parsing reports invalidFieldValue")
    func unterminatedQuotedValue() {
        let bibtex = #"@article{test, title = "Unclosed}"#

        #expect(
            throws: BibTeXParser.Error.invalidFieldValue(
                field: "title",
                position: 23
            )
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When a quoted field has a stray closing brace, then parsing reports invalidFieldValue")
    func quotedValueRejectsUnmatchedClosingBrace() {
        let bibtex = #"@article{test, title = "A stray } brace", year = 2024}"#

        #expect(
            throws: BibTeXParser.Error.invalidFieldValue(
                field: "title",
                position: 23
            )
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When a field value is empty, then parsing reports invalidFieldValue")
    func emptyFieldValue() {
        let bibtex = "@article{test, title = , year = 2024}"

        #expect(
            throws: BibTeXParser.Error.invalidFieldValue(
                field: "title",
                position: 23
            )
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When an assignment omits its field name, then parsing reports unexpectedCharacter")
    func missingFieldNameCannotStallParser() {
        let bibtex = "@article{test, = {value}}"

        #expect(
            throws: BibTeXParser.Error.unexpectedCharacter(
                character: "=",
                position: 15
            )
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When a field omits its equals sign, then parsing reports unexpectedCharacter")
    func missingEqualsSignIsRejected() {
        let bibtex = "@article{test, title {value}}"

        #expect(
            throws: BibTeXParser.Error.unexpectedCharacter(
                character: "{",
                position: 21
            )
        ) {
            try BibTeXParser.parse(bibtex)
        }
    }

    @Test("When malformed input has leading spaces, then its error offset uses original input")
    func errorPositionUsesOriginalUntrimmedInput() {
        #expect(
            throws: BibTeXParser.Error.invalidEntryType(position: 3)
        ) {
            try BibTeXParser.parse("  @{test}")
        }
    }

    @Test(
        "Given Unicode before malformed syntax, when parsed, then errors use character offsets",
        arguments: [
            ErrorScenario(
                input: "👩🏽‍🚀\n@{test}",
                expected: .invalidEntryType(position: 3)
            ),
            ErrorScenario(
                input: "é @article",
                expected: .missingOpeningBrace(position: 10)
            ),
            ErrorScenario(
                input: "📚 @article{,}",
                expected: .missingCitationKey(
                    entryType: "article",
                    position: 11
                )
            ),
        ]
    )
    func exactErrorsUseUnicodeCharacterOffsets(
        _ scenario: ErrorScenario
    ) {
        #expect(throws: scenario.expected) {
            try BibTeXParser.parse(scenario.input)
        }
    }

    // MARK: - Comments and Whitespace Tests

    @Test("When comments surround an entry, then only the entry is returned")
    func ignoreComments() throws {
        let bibtex = """
            % This is a comment
            @article{test, title = {Test}}
            % Another comment
            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.count == 1)
    }

    @Test("When whitespace surrounds syntax and values, then one trimmed entry is returned")
    func whitespaceHandling() throws {
        let bibtex = """


            @article{test,
                title    =    {  Test  }
            }


            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.count == 1)
        #expect(entries.first?["title"] == "Test")
    }

    @Test("When normalized field names collide, then the first field value wins")
    func duplicateFieldsKeepFirstValueWhenNamesAreNormalized() throws {
        let bibtex = "@misc{test, TITLE = {First}, title = {Second}, Title = {Third}}"

        let entry = try #require(BibTeXParser.parse(bibtex).first)

        #expect(entry.fields == ["title": "First"])
        #expect(entry.title == "First")
    }

    @Test("When unnormalized field names collide by case, then the first spelling and value win")
    func duplicateFieldsKeepFirstValueCaseInsensitivelyWithoutNormalization() throws {
        let bibtex = "@misc{test, TITLE = {First}, title = {Second}, Title = {Third}}"
        var options = BibTeXParser.Options()
        options.normalizeFieldNames = false

        let entry = try #require(BibTeXParser.parse(bibtex, options: options).first)

        #expect(entry.fields == ["TITLE": "First"])
        #expect(entry.title == "First")
    }

    @Test("When citation keys differ only by case, then the first entry wins")
    func duplicateCitationKeysKeepFirstEntryCaseInsensitively() throws {
        let bibtex = """
            @misc{Key, title = {First}}
            @book{key, title = {Second}, publisher = {Publisher}, year = 2026}
            @article{other, title = {Other}}
            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.map(\.citationKey) == ["Key", "other"])
        #expect(entries.first?.type == .misc)
        #expect(entries.first?.title == "First")
    }

    @Test("When a delimiterless comment precedes an entry, then only the entry is returned")
    func delimiterlessCommentIsIgnoredBeforeFollowingEntry() throws {
        let bibtex = """
            @comment This text is outside an entry
            @article{real, title = {Real Entry}}
            """

        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.map(\.citationKey) == ["real"])
    }

    @Test("When a string macro overrides a built-in month, then the custom value resolves")
    func stringDirectiveOverridesBuiltInMonthConstant() throws {
        let bibtex = """
            @string{jan = "Custom January"}
            @misc{test, month = JAN}
            """

        let entry = try #require(BibTeXParser.parse(bibtex).first)

        #expect(entry["month"] == "Custom January")
    }

    // MARK: - Special Content Tests

    @Test("When a field contains Japanese Unicode, then its exact text is preserved")
    func unicodeContent() throws {
        let bibtex = "@article{test, title = {日本語タイトル}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["title"] == "日本語タイトル")
    }

    @Test("When a field contains a URL with query parameters, then the complete URL is preserved")
    func urlInField() throws {
        let bibtex = "@misc{test, url = {https://example.com/path?query=1&other=2}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["url"] == "https://example.com/path?query=1&other=2")
    }

    @Test("When a field contains a DOI, then its complete identifier is preserved")
    func doiInField() throws {
        let bibtex = "@article{test, doi = {10.1000/xyz123}}"
        let entries = try BibTeXParser.parse(bibtex)

        #expect(entries.first?["doi"] == "10.1000/xyz123")
    }

    // MARK: - Instance Parser Tests

    @Test("When an instance parser parses one entry, then it returns that entry")
    func instanceParser() throws {
        let parser = BibTeXParser()
        let bibtex = "@article{test, title = {Test}}"

        let entries = try parser.parse(bibtex)

        #expect(entries.count == 1)
    }

    @Test("When an instance parser preserves raw input, then the entry retains raw BibTeX")
    func instanceParserWithOptions() throws {
        var options = BibTeXParser.Options()
        options.preserveRawBibTeX = true

        let parser = BibTeXParser(options: options)
        let bibtex = "@article{test, title = {Test}}"

        let entries = try parser.parse(bibtex)

        #expect(entries.first?.rawBibTeX != nil)
    }

    @Test(
        "Given one parser, when tasks parse concurrently, then every result is deterministic"
    )
    func sharedParserSupportsDeterministicConcurrentParsing() async throws {
        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = false
        let parser = BibTeXParser(options: options)
        let bibtex = """
            @string{venue = "Flight Systems"}
            @article{shared,
                title = {Deterministic Parsing},
                journal = venue,
                year = 2026
            }
            """
        let expected = try parser.parse(bibtex)

        let results = try await withThrowingTaskGroup(
            of: [BibTeXEntry].self,
            returning: [[BibTeXEntry]].self
        ) { group in
            for _ in 0..<16 {
                group.addTask {
                    try parser.parse(bibtex)
                }
            }

            var parsedEntries: [[BibTeXEntry]] = []
            parsedEntries.reserveCapacity(16)
            for try await entries in group {
                parsedEntries.append(entries)
            }
            return parsedEntries
        }

        #expect(results.count == 16)
        for entries in results {
            #expect(entries == expected)
        }
    }

    // MARK: - Complex Entry Tests

    @Test("When parsing a real-world article, then all core metadata and accents are correct")
    func realWorldEntry() throws {
        let bibtex = """
            @article{einstein1905,
                author = {Albert Einstein},
                title = {Zur Elektrodynamik bewegter K\\"orper},
                journal = {Annalen der Physik},
                volume = {17},
                number = {10},
                pages = {891--921},
                year = {1905},
                doi = {10.1002/andp.19053221004},
                abstract = {This paper introduces the special theory of relativity.}
            }
            """

        var options = BibTeXParser.Options()
        options.convertLaTeXToUnicode = true

        let entries = try BibTeXParser.parse(bibtex, options: options)

        #expect(entries.count == 1)
        #expect(entries.first?.citationKey == "einstein1905")
        #expect(entries.first?.type == .article)
        #expect(entries.first?["author"] == "Albert Einstein")
        #expect(entries.first?["title"] == "Zur Elektrodynamik bewegter Körper")
        #expect(entries.first?["year"] == "1905")
    }
}
