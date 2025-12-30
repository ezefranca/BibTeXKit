//
//  BibTeXTokenizer.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// A robust tokenizer for BibTeX and LaTeX content.
///
/// `BibTeXTokenizer` breaks down BibTeX strings into tokens suitable
/// for syntax highlighting. It handles:
///
/// - All BibTeX entry types and structures
/// - Nested braces to arbitrary depth
/// - Comments (%)
/// - LaTeX commands and accents
/// - Math mode
/// - Special characters
///
/// ## Usage
///
/// ```swift
/// let tokenizer = BibTeXTokenizer()
/// let tokens = tokenizer.tokenize(bibtexString)
///
/// for token in tokens {
///     print("\(token.token): \(token.text)")
/// }
/// ```
///
/// ## Thread Safety
///
/// `BibTeXTokenizer` is fully thread-safe and can be used
/// from any thread or actor context.
public struct BibTeXTokenizer: Sendable {
    
    // MARK: - Constants
    
    /// Known BibTeX string constants (month abbreviations, etc.)
    private static let knownConstants: Set<String> = [
        "jan", "feb", "mar", "apr", "may", "jun",
        "jul", "aug", "sep", "oct", "nov", "dec"
    ]
    
    /// Special entry types that are directives
    private static let specialTypes: Set<String> = [
        "preamble", "string", "comment"
    ]
    
    /// Common LaTeX commands
    private static let latexCommands: Set<String> = [
        "textbf", "textit", "textrm", "textsf", "texttt", "textsc",
        "emph", "underline", "uppercase", "lowercase",
        "cite", "ref", "label", "footnote", "href", "url",
        "alpha", "beta", "gamma", "delta", "epsilon", "pi", "sigma", "omega",
        "sqrt", "frac", "sum", "prod", "int", "lim", "log", "exp", "sin", "cos"
    ]
    
    /// LaTeX accent commands
    private static let accentCommands: Set<String> = [
        "'", "`", "^", "\"", "~", "=", ".", "u", "v", "H", "t", "c", "d", "b", "r", "k"
    ]
    
    // MARK: - Initialization
    
    /// Creates a new tokenizer.
    public init() {}
    
    // MARK: - Public Methods
    
    /// Tokenizes a BibTeX string.
    ///
    /// - Parameter input: The BibTeX string to tokenize.
    /// - Returns: An array of tokens with their positions.
    public func tokenize(_ input: String) -> [BibTeXTokenInfo] {
        guard !input.isEmpty else { return [] }
        
        var tokens: [BibTeXTokenInfo] = []
        var index = input.startIndex
        var context = TokenContext()
        
        while index < input.endIndex {
            let remaining = input[index...]
            
            if let tokenInfo = nextToken(from: remaining, in: input, context: &context) {
                tokens.append(tokenInfo)
                index = tokenInfo.range.upperBound
            } else {
                // Fallback: consume single character
                let nextIndex = input.index(after: index)
                tokens.append(BibTeXTokenInfo(
                    token: .text,
                    text: String(input[index]),
                    range: index..<nextIndex
                ))
                index = nextIndex
            }
        }
        
        return tokens
    }
    
    /// Tokenizes and returns just the token-text pairs (simplified output).
    ///
    /// - Parameter input: The BibTeX string to tokenize.
    /// - Returns: An array of (text, token) tuples.
    public func tokenizePairs(_ input: String) -> [(text: String, token: BibTeXToken)] {
        tokenize(input).map { ($0.text, $0.token) }
    }
    
    // MARK: - Private Types
    
    private struct TokenContext {
        var expectingCitationKey = false
        var expectingFieldValue = false
        var inStringValue = false
        var braceDepth = 0
    }
    
    // MARK: - Private Methods
    
    private func nextToken(
        from remaining: Substring,
        in input: String,
        context: inout TokenContext
    ) -> BibTeXTokenInfo? {
        guard let first = remaining.first else { return nil }
        let startIndex = remaining.startIndex
        
        // Comment: % to end of line
        if first == "%" && !context.inStringValue {
            return consumeComment(from: remaining, in: input)
        }
        
        // Whitespace
        if first.isWhitespace {
            return consumeWhitespace(from: remaining, in: input)
        }
        
        // Entry type: @type
        if first == "@" && !context.inStringValue {
            let result = consumeEntryType(from: remaining, in: input)
            if result != nil {
                context.expectingCitationKey = true
            }
            return result
        }
        
        // Opening brace or parenthesis
        if (first == "{" || first == "(") && !context.inStringValue {
            let nextIndex = input.index(after: startIndex)
            let tokenInfo = BibTeXTokenInfo(
                token: .punctuation,
                text: String(first),
                range: startIndex..<nextIndex
            )
            
            if context.expectingCitationKey {
                context.expectingCitationKey = false
                // Next non-whitespace token is the citation key
            }
            
            context.braceDepth += 1
            return tokenInfo
        }
        
        // Closing brace or parenthesis
        if (first == "}" || first == ")") && !context.inStringValue {
            let nextIndex = input.index(after: startIndex)
            context.braceDepth = max(0, context.braceDepth - 1)
            return BibTeXTokenInfo(
                token: .punctuation,
                text: String(first),
                range: startIndex..<nextIndex
            )
        }
        
        // Comma
        if first == "," {
            let nextIndex = input.index(after: startIndex)
            context.expectingFieldValue = false
            return BibTeXTokenInfo(
                token: .punctuation,
                text: ",",
                range: startIndex..<nextIndex
            )
        }
        
        // Equals sign
        if first == "=" {
            let nextIndex = input.index(after: startIndex)
            context.expectingFieldValue = true
            return BibTeXTokenInfo(
                token: .operator,
                text: "=",
                range: startIndex..<nextIndex
            )
        }
        
        // Hash (string concatenation)
        if first == "#" {
            let nextIndex = input.index(after: startIndex)
            context.expectingFieldValue = true
            return BibTeXTokenInfo(
                token: .operator,
                text: "#",
                range: startIndex..<nextIndex
            )
        }
        
        // Quoted string
        if first == "\"" {
            return consumeQuotedString(from: remaining, in: input, context: &context)
        }
        
        // Braced string value
        if first == "{" && context.expectingFieldValue {
            return consumeBracedString(from: remaining, in: input, context: &context)
        }
        
        // LaTeX command
        if first == "\\" {
            return consumeLatexCommand(from: remaining, in: input)
        }
        
        // Math mode
        if first == "$" {
            return consumeMathMode(from: remaining, in: input)
        }
        
        // Number
        if first.isNumber && context.expectingFieldValue {
            return consumeNumber(from: remaining, in: input, context: &context)
        }
        
        // Word (field name, constant, citation key, or text)
        if first.isLetter || first == "_" {
            return consumeWord(from: remaining, in: input, context: &context)
        }
        
        // Single character fallback
        let nextIndex = input.index(after: startIndex)
        return BibTeXTokenInfo(
            token: .text,
            text: String(first),
            range: startIndex..<nextIndex
        )
    }
    
    // MARK: - Token Consumers
    
    private func consumeComment(from remaining: Substring, in input: String) -> BibTeXTokenInfo {
        let startIndex = remaining.startIndex
        var endIndex = startIndex
        
        while endIndex < remaining.endIndex && remaining[endIndex] != "\n" && remaining[endIndex] != "\r" {
            endIndex = input.index(after: endIndex)
        }
        
        return BibTeXTokenInfo(
            token: .comment,
            text: String(remaining[startIndex..<endIndex]),
            range: startIndex..<endIndex
        )
    }
    
    private func consumeWhitespace(from remaining: Substring, in input: String) -> BibTeXTokenInfo {
        let startIndex = remaining.startIndex
        var endIndex = startIndex
        
        while endIndex < remaining.endIndex && remaining[endIndex].isWhitespace {
            endIndex = input.index(after: endIndex)
        }
        
        return BibTeXTokenInfo(
            token: .whitespace,
            text: String(remaining[startIndex..<endIndex]),
            range: startIndex..<endIndex
        )
    }
    
    private func consumeEntryType(from remaining: Substring, in input: String) -> BibTeXTokenInfo? {
        guard remaining.first == "@" else { return nil }
        
        let startIndex = remaining.startIndex
        var endIndex = input.index(after: startIndex)
        
        // Consume the type name
        while endIndex < remaining.endIndex {
            let char = remaining[endIndex]
            if char.isLetter || char == "*" {
                endIndex = input.index(after: endIndex)
            } else {
                break
            }
        }
        
        let text = String(remaining[startIndex..<endIndex])
        let typeName = String(text.dropFirst()).lowercased()
        
        let token: BibTeXToken = Self.specialTypes.contains(typeName) ? .special : .entryType
        
        return BibTeXTokenInfo(
            token: token,
            text: text,
            range: startIndex..<endIndex
        )
    }
    
    private func consumeQuotedString(
        from remaining: Substring,
        in input: String,
        context: inout TokenContext
    ) -> BibTeXTokenInfo {
        guard remaining.first == "\"" else {
            let nextIndex = input.index(after: remaining.startIndex)
            return BibTeXTokenInfo(token: .text, text: "\"", range: remaining.startIndex..<nextIndex)
        }
        
        let startIndex = remaining.startIndex
        var endIndex = input.index(after: startIndex)
        var escaped = false
        
        while endIndex < remaining.endIndex {
            let char = remaining[endIndex]
            if escaped {
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "\"" {
                endIndex = input.index(after: endIndex)
                break
            }
            endIndex = input.index(after: endIndex)
        }
        
        context.expectingFieldValue = false
        
        return BibTeXTokenInfo(
            token: .string,
            text: String(remaining[startIndex..<endIndex]),
            range: startIndex..<endIndex
        )
    }
    
    private func consumeBracedString(
        from remaining: Substring,
        in input: String,
        context: inout TokenContext
    ) -> BibTeXTokenInfo {
        guard remaining.first == "{" else {
            let nextIndex = input.index(after: remaining.startIndex)
            return BibTeXTokenInfo(token: .punctuation, text: "{", range: remaining.startIndex..<nextIndex)
        }
        
        let startIndex = remaining.startIndex
        var endIndex = input.index(after: startIndex)
        var depth = 1
        
        while endIndex < remaining.endIndex && depth > 0 {
            let char = remaining[endIndex]
            if char == "{" {
                depth += 1
            } else if char == "}" {
                depth -= 1
            }
            endIndex = input.index(after: endIndex)
        }
        
        context.expectingFieldValue = false
        
        return BibTeXTokenInfo(
            token: .string,
            text: String(remaining[startIndex..<endIndex]),
            range: startIndex..<endIndex
        )
    }
    
    private func consumeLatexCommand(from remaining: Substring, in input: String) -> BibTeXTokenInfo {
        guard remaining.first == "\\" else {
            let nextIndex = input.index(after: remaining.startIndex)
            return BibTeXTokenInfo(token: .text, text: "\\", range: remaining.startIndex..<nextIndex)
        }
        
        let startIndex = remaining.startIndex
        var endIndex = input.index(after: startIndex)
        
        // Check for special single-character commands
        if endIndex < remaining.endIndex {
            let nextChar = remaining[endIndex]
            
            // Special characters: \& \% \$ \# \_ \{ \}
            if "\\&%$#_{}".contains(nextChar) {
                endIndex = input.index(after: endIndex)
                return BibTeXTokenInfo(
                    token: .specialChar,
                    text: String(remaining[startIndex..<endIndex]),
                    range: startIndex..<endIndex
                )
            }
            
            // Accent commands: \' \" \` \^ \~ etc.
            if Self.accentCommands.contains(String(nextChar)) {
                endIndex = input.index(after: endIndex)
                
                // Optionally consume the accented character
                if endIndex < remaining.endIndex {
                    let following = remaining[endIndex]
                    if following == "{" {
                        // \'{e} or \"{o} style
                        var braceDepth = 1
                        endIndex = input.index(after: endIndex)
                        while endIndex < remaining.endIndex && braceDepth > 0 {
                            if remaining[endIndex] == "{" { braceDepth += 1 }
                            if remaining[endIndex] == "}" { braceDepth -= 1 }
                            endIndex = input.index(after: endIndex)
                        }
                    } else if following.isLetter {
                        // \'e style
                        endIndex = input.index(after: endIndex)
                    }
                }
                
                return BibTeXTokenInfo(
                    token: .accent,
                    text: String(remaining[startIndex..<endIndex]),
                    range: startIndex..<endIndex
                )
            }
        }
        
        // Regular command: \commandname
        while endIndex < remaining.endIndex && remaining[endIndex].isLetter {
            endIndex = input.index(after: endIndex)
        }
        
        // Check for * suffix
        if endIndex < remaining.endIndex && remaining[endIndex] == "*" {
            endIndex = input.index(after: endIndex)
        }
        
        let text = String(remaining[startIndex..<endIndex])
        let commandName = String(text.dropFirst())
        
        // Determine token type
        let token: BibTeXToken
        if commandName == "begin" || commandName == "end" {
            // Try to capture the environment name
            if endIndex < remaining.endIndex && remaining[endIndex] == "{" {
                var braceDepth = 1
                endIndex = input.index(after: endIndex)
                while endIndex < remaining.endIndex && braceDepth > 0 {
                    if remaining[endIndex] == "{" { braceDepth += 1 }
                    if remaining[endIndex] == "}" { braceDepth -= 1 }
                    endIndex = input.index(after: endIndex)
                }
            }
            token = .environment
        } else if Self.latexCommands.contains(commandName) {
            token = .command
        } else {
            token = .command
        }
        
        return BibTeXTokenInfo(
            token: token,
            text: String(remaining[startIndex..<endIndex]),
            range: startIndex..<endIndex
        )
    }
    
    private func consumeMathMode(from remaining: Substring, in input: String) -> BibTeXTokenInfo {
        guard remaining.first == "$" else {
            let nextIndex = input.index(after: remaining.startIndex)
            return BibTeXTokenInfo(token: .text, text: "$", range: remaining.startIndex..<nextIndex)
        }
        
        let startIndex = remaining.startIndex
        var endIndex = input.index(after: startIndex)
        
        // Check for $$ (display math)
        let isDisplayMath = endIndex < remaining.endIndex && remaining[endIndex] == "$"
        if isDisplayMath {
            endIndex = input.index(after: endIndex)
        }
        
        // Find closing delimiter
        let delimiter = isDisplayMath ? "$$" : "$"
        var escaped = false
        
        while endIndex < remaining.endIndex {
            let char = remaining[endIndex]
            if escaped {
                escaped = false
                endIndex = input.index(after: endIndex)
            } else if char == "\\" {
                escaped = true
                endIndex = input.index(after: endIndex)
            } else if char == "$" {
                if isDisplayMath {
                    let nextIdx = input.index(after: endIndex)
                    if nextIdx < remaining.endIndex && remaining[nextIdx] == "$" {
                        endIndex = input.index(after: nextIdx)
                        break
                    }
                    endIndex = input.index(after: endIndex)
                } else {
                    endIndex = input.index(after: endIndex)
                    break
                }
            } else {
                endIndex = input.index(after: endIndex)
            }
        }
        
        return BibTeXTokenInfo(
            token: .math,
            text: String(remaining[startIndex..<endIndex]),
            range: startIndex..<endIndex
        )
    }
    
    private func consumeNumber(
        from remaining: Substring,
        in input: String,
        context: inout TokenContext
    ) -> BibTeXTokenInfo {
        let startIndex = remaining.startIndex
        var endIndex = startIndex
        
        while endIndex < remaining.endIndex && remaining[endIndex].isNumber {
            endIndex = input.index(after: endIndex)
        }
        
        context.expectingFieldValue = false
        
        return BibTeXTokenInfo(
            token: .number,
            text: String(remaining[startIndex..<endIndex]),
            range: startIndex..<endIndex
        )
    }
    
    private func consumeWord(
        from remaining: Substring,
        in input: String,
        context: inout TokenContext
    ) -> BibTeXTokenInfo {
        let startIndex = remaining.startIndex
        var endIndex = startIndex
        
        while endIndex < remaining.endIndex {
            let char = remaining[endIndex]
            if char.isLetter || char.isNumber || char == "_" || char == "-" || char == ":" {
                endIndex = input.index(after: endIndex)
            } else {
                break
            }
        }
        
        let word = String(remaining[startIndex..<endIndex])
        
        // Determine token type based on context
        let token: BibTeXToken
        
        if context.expectingCitationKey {
            token = .citationKey
            context.expectingCitationKey = false
        } else if context.expectingFieldValue {
            // Check if it's a known constant
            if Self.knownConstants.contains(word.lowercased()) {
                token = .constant
            } else {
                token = .constant // Unquoted value is treated as constant
            }
            context.expectingFieldValue = false
        } else {
            // Check if followed by = (making it a field name)
            var checkIndex = endIndex
            while checkIndex < remaining.endIndex && remaining[checkIndex].isWhitespace {
                checkIndex = input.index(after: checkIndex)
            }
            
            if checkIndex < remaining.endIndex && remaining[checkIndex] == "=" {
                token = .fieldName
            } else if Self.knownConstants.contains(word.lowercased()) {
                token = .constant
            } else {
                token = .text
            }
        }
        
        return BibTeXTokenInfo(
            token: token,
            text: word,
            range: startIndex..<endIndex
        )
    }
}
