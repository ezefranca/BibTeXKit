//
//  LaTeXConverter.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// Converts LaTeX special characters and accents to Unicode.
///
/// `LaTeXConverter` handles the conversion of common LaTeX commands
/// to their Unicode equivalents for display purposes.
///
/// ## Usage
///
/// ```swift
/// let unicode = LaTeXConverter.convertToUnicode("Caf\\'{e}")
/// // Returns "Café"
///
/// let latex = LaTeXConverter.convertToLaTeX("Müller")
/// // Returns "M\\\"{u}ller"
/// ```
public struct LaTeXConverter: Sendable {
    
    // MARK: - Accent Mappings
    
    /// Mapping of LaTeX accents to Unicode combining characters.
    private static let accentMappings: [String: [Character: Character]] = [
        "'": [ // Acute accent
            "a": "á", "e": "é", "i": "í", "o": "ó", "u": "ú", "y": "ý",
            "A": "Á", "E": "É", "I": "Í", "O": "Ó", "U": "Ú", "Y": "Ý",
            "c": "ć", "C": "Ć", "n": "ń", "N": "Ń", "s": "ś", "S": "Ś",
            "z": "ź", "Z": "Ź", "l": "ĺ", "L": "Ĺ", "r": "ŕ", "R": "Ŕ"
        ],
        "`": [ // Grave accent
            "a": "à", "e": "è", "i": "ì", "o": "ò", "u": "ù",
            "A": "À", "E": "È", "I": "Ì", "O": "Ò", "U": "Ù"
        ],
        "^": [ // Circumflex
            "a": "â", "e": "ê", "i": "î", "o": "ô", "u": "û",
            "A": "Â", "E": "Ê", "I": "Î", "O": "Ô", "U": "Û",
            "c": "ĉ", "C": "Ĉ", "g": "ĝ", "G": "Ĝ", "h": "ĥ", "H": "Ĥ",
            "j": "ĵ", "J": "Ĵ", "s": "ŝ", "S": "Ŝ", "w": "ŵ", "W": "Ŵ",
            "y": "ŷ", "Y": "Ŷ"
        ],
        "\"": [ // Umlaut/diaeresis
            "a": "ä", "e": "ë", "i": "ï", "o": "ö", "u": "ü", "y": "ÿ",
            "A": "Ä", "E": "Ë", "I": "Ï", "O": "Ö", "U": "Ü", "Y": "Ÿ"
        ],
        "~": [ // Tilde
            "a": "ã", "n": "ñ", "o": "õ",
            "A": "Ã", "N": "Ñ", "O": "Õ"
        ],
        "=": [ // Macron
            "a": "ā", "e": "ē", "i": "ī", "o": "ō", "u": "ū",
            "A": "Ā", "E": "Ē", "I": "Ī", "O": "Ō", "U": "Ū"
        ],
        ".": [ // Dot above
            "c": "ċ", "C": "Ċ", "e": "ė", "E": "Ė", "g": "ġ", "G": "Ġ",
            "z": "ż", "Z": "Ż", "I": "İ"
        ],
        "u": [ // Breve
            "a": "ă", "A": "Ă", "g": "ğ", "G": "Ğ", "u": "ŭ", "U": "Ŭ"
        ],
        "v": [ // Háček/caron
            "c": "č", "C": "Č", "d": "ď", "D": "Ď", "e": "ě", "E": "Ě",
            "n": "ň", "N": "Ň", "r": "ř", "R": "Ř", "s": "š", "S": "Š",
            "t": "ť", "T": "Ť", "z": "ž", "Z": "Ž"
        ],
        "H": [ // Double acute
            "o": "ő", "O": "Ő", "u": "ű", "U": "Ű"
        ],
        "c": [ // Cedilla
            "c": "ç", "C": "Ç", "s": "ş", "S": "Ş", "t": "ţ", "T": "Ţ"
        ],
        "k": [ // Ogonek
            "a": "ą", "A": "Ą", "e": "ę", "E": "Ę"
        ],
        "r": [ // Ring above
            "a": "å", "A": "Å", "u": "ů", "U": "Ů"
        ]
    ]
    
    /// Special character mappings.
    private static let specialCharacters: [String: String] = [
        "\\&": "&",
        "\\%": "%",
        "\\$": "$",
        "\\#": "#",
        "\\_": "_",
        "\\{": "{",
        "\\}": "}",
        "\\textasciitilde": "~",
        "\\textasciicircum": "^",
        "\\textbackslash": "\\",
        "\\ss": "ß",
        "\\SS": "SS",
        "\\ae": "æ",
        "\\AE": "Æ",
        "\\oe": "œ",
        "\\OE": "Œ",
        "\\aa": "å",
        "\\AA": "Å",
        "\\o": "ø",
        "\\O": "Ø",
        "\\l": "ł",
        "\\L": "Ł",
        "\\i": "ı",
        "\\j": "ȷ",
        "\\dag": "†",
        "\\ddag": "‡",
        "\\S": "§",
        "\\P": "¶",
        "\\copyright": "©",
        "\\pounds": "£",
        "\\euro": "€",
        "\\yen": "¥",
        "\\textregistered": "®",
        "\\texttrademark": "™",
        "\\textdegree": "°",
        "\\textmu": "µ",
        "\\ldots": "…",
        "\\textendash": "–",
        "\\textemdash": "—",
        "\\textquoteleft": "'",
        "\\textquoteright": "'",
        "\\textquotedblleft": "\u{201C}",
        "\\textquotedblright": "\u{201D}",
        "---": "—",
        "--": "–",
        "``": "\u{201C}",
        "''": "\u{201D}",
        "`": "'",
        "'": "'"
    ]
    
    /// Greek letters.
    private static let greekLetters: [String: String] = [
        "\\alpha": "α", "\\beta": "β", "\\gamma": "γ", "\\delta": "δ",
        "\\epsilon": "ε", "\\zeta": "ζ", "\\eta": "η", "\\theta": "θ",
        "\\iota": "ι", "\\kappa": "κ", "\\lambda": "λ", "\\mu": "μ",
        "\\nu": "ν", "\\xi": "ξ", "\\pi": "π", "\\rho": "ρ",
        "\\sigma": "σ", "\\tau": "τ", "\\upsilon": "υ", "\\phi": "φ",
        "\\chi": "χ", "\\psi": "ψ", "\\omega": "ω",
        "\\Alpha": "Α", "\\Beta": "Β", "\\Gamma": "Γ", "\\Delta": "Δ",
        "\\Epsilon": "Ε", "\\Zeta": "Ζ", "\\Eta": "Η", "\\Theta": "Θ",
        "\\Iota": "Ι", "\\Kappa": "Κ", "\\Lambda": "Λ", "\\Mu": "Μ",
        "\\Nu": "Ν", "\\Xi": "Ξ", "\\Pi": "Π", "\\Rho": "Ρ",
        "\\Sigma": "Σ", "\\Tau": "Τ", "\\Upsilon": "Υ", "\\Phi": "Φ",
        "\\Chi": "Χ", "\\Psi": "Ψ", "\\Omega": "Ω"
    ]
    
    /// Math symbols.
    private static let mathSymbols: [String: String] = [
        "\\times": "×", "\\div": "÷", "\\pm": "±", "\\mp": "∓",
        "\\cdot": "·", "\\bullet": "•", "\\circ": "∘",
        "\\leq": "≤", "\\geq": "≥", "\\neq": "≠", "\\approx": "≈",
        "\\equiv": "≡", "\\sim": "∼", "\\propto": "∝",
        "\\infty": "∞", "\\partial": "∂", "\\nabla": "∇",
        "\\sum": "∑", "\\prod": "∏", "\\int": "∫",
        "\\sqrt": "√", "\\angle": "∠", "\\degree": "°",
        "\\forall": "∀", "\\exists": "∃", "\\in": "∈", "\\notin": "∉",
        "\\subset": "⊂", "\\supset": "⊃", "\\cup": "∪", "\\cap": "∩",
        "\\land": "∧", "\\lor": "∨", "\\neg": "¬",
        "\\rightarrow": "→", "\\leftarrow": "←", "\\leftrightarrow": "↔",
        "\\Rightarrow": "⇒", "\\Leftarrow": "⇐", "\\Leftrightarrow": "⇔"
    ]
    
    // MARK: - Public Methods
    
    /// Converts LaTeX commands to Unicode.
    ///
    /// - Parameter input: The LaTeX string to convert.
    /// - Returns: A Unicode string.
    public static func toUnicode(_ input: String) -> String {
        var result = input
        
        // Convert special characters first (longer sequences)
        for (latex, unicode) in specialCharacters.sorted(by: { $0.key.count > $1.key.count }) {
            result = result.replacingOccurrences(of: latex, with: unicode)
        }
        
        // Convert Greek letters
        for (latex, unicode) in greekLetters {
            result = result.replacingOccurrences(of: latex, with: unicode)
        }
        
        // Convert math symbols
        for (latex, unicode) in mathSymbols {
            result = result.replacingOccurrences(of: latex, with: unicode)
        }
        
        // Convert accents
        result = convertAccents(in: result)
        
        // Remove remaining braces that were just for grouping
        result = removeGroupingBraces(from: result)
        
        return result
    }
    
    /// Converts Unicode characters to LaTeX.
    ///
    /// - Parameter input: The Unicode string to convert.
    /// - Returns: A LaTeX string.
    public static func toLaTeX(_ input: String) -> String {
        var result = ""
        
        for char in input {
            if let latex = unicodeToLaTeX[char] {
                result += latex
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    private static func convertAccents(in input: String) -> String {
        var result = input
        
        for (accent, charMap) in accentMappings {
            // Pattern: \'{e} or \'e
            let bracedPattern = "\\\\\(accent)\\{([a-zA-Z])\\}"
            let unbracedPattern = "\\\\\(accent)([a-zA-Z])"
            
            // Replace braced version
            if let regex = try? NSRegularExpression(pattern: bracedPattern) {
                let range = NSRange(result.startIndex..., in: result)
                let matches = regex.matches(in: result, range: range)
                
                for match in matches.reversed() {
                    if let charRange = Range(match.range(at: 1), in: result) {
                        let char = result[charRange].first!
                        if let replacement = charMap[char] {
                            if let fullRange = Range(match.range, in: result) {
                                result.replaceSubrange(fullRange, with: String(replacement))
                            }
                        }
                    }
                }
            }
            
            // Replace unbraced version
            if let regex = try? NSRegularExpression(pattern: unbracedPattern) {
                let range = NSRange(result.startIndex..., in: result)
                let matches = regex.matches(in: result, range: range)
                
                for match in matches.reversed() {
                    if let charRange = Range(match.range(at: 1), in: result) {
                        let char = result[charRange].first!
                        if let replacement = charMap[char] {
                            if let fullRange = Range(match.range, in: result) {
                                result.replaceSubrange(fullRange, with: String(replacement))
                            }
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    private static func removeGroupingBraces(from input: String) -> String {
        var result = input
        
        // Remove empty braces
        result = result.replacingOccurrences(of: "{}", with: "")
        
        // Remove single-character braces like {A} -> A
        if let regex = try? NSRegularExpression(pattern: "\\{([^{}])\\}") {
            var range = NSRange(result.startIndex..., in: result)
            while let match = regex.firstMatch(in: result, range: range) {
                if let fullRange = Range(match.range, in: result),
                   let charRange = Range(match.range(at: 1), in: result) {
                    let char = String(result[charRange])
                    result.replaceSubrange(fullRange, with: char)
                    range = NSRange(result.startIndex..., in: result)
                } else {
                    break
                }
            }
        }
        
        return result
    }
    
    /// Reverse mapping for Unicode to LaTeX conversion.
    private static let unicodeToLaTeX: [Character: String] = {
        var mapping: [Character: String] = [:]
        
        // Add accent mappings
        for (accent, charMap) in accentMappings {
            for (original, converted) in charMap {
                mapping[converted] = "\\\(accent){\(original)}"
            }
        }
        
        // Add special characters
        mapping["&"] = "\\&"
        mapping["%"] = "\\%"
        mapping["$"] = "\\$"
        mapping["#"] = "\\#"
        mapping["_"] = "\\_"
        mapping["ß"] = "\\ss"
        mapping["æ"] = "\\ae"
        mapping["Æ"] = "\\AE"
        mapping["œ"] = "\\oe"
        mapping["Œ"] = "\\OE"
        mapping["ø"] = "\\o"
        mapping["Ø"] = "\\O"
        mapping["ł"] = "\\l"
        mapping["Ł"] = "\\L"
        
        return mapping
    }()
}
