//
//  DOIDetector.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import Foundation

/// A utility for detecting and extracting DOIs (Digital Object Identifiers) from text.
///
/// `DOIDetector` provides robust regex-based detection of DOIs in various formats:
///
/// - Standard DOI: `10.1000/xyz123`
/// - URL format: `https://doi.org/10.1000/xyz123`
/// - dx.doi.org format: `http://dx.doi.org/10.1000/xyz123`
/// - DOI prefix: `doi:10.1000/xyz123`
///
/// ## Usage
///
/// ```swift
/// // Check if a string contains a DOI
/// DOIDetector.containsDOI("See https://doi.org/10.1000/xyz123")  // true
///
/// // Extract the first DOI
/// DOIDetector.extractDOI(from: "Paper at doi:10.1000/xyz123")  // "10.1000/xyz123"
///
/// // Extract all DOIs
/// DOIDetector.extractAllDOIs(from: text)  // ["10.1000/abc", "10.2000/def"]
///
/// // Validate a DOI format
/// DOIDetector.isValidDOI("10.1000/xyz123")  // true
///
/// // Get DOI as URL
/// DOIDetector.doiURL(for: "10.1000/xyz123")  // URL("https://doi.org/10.1000/xyz123")
/// ```
///
/// ## DOI Format
///
/// A DOI consists of two parts separated by a forward slash:
/// - **Prefix**: Starts with `10.` followed by a registrant code (e.g., `10.1000`)
/// - **Suffix**: A unique identifier assigned by the registrant (e.g., `xyz123`)
///
/// ## Thread Safety
///
/// `DOIDetector` is fully thread-safe and can be used from any thread or actor context.
public struct DOIDetector: Sendable {
    
    // MARK: - Regex Patterns
    
    /// Standard DOI pattern: 10.prefix/suffix
    /// DOI suffixes can contain: alphanumerics, -, ., _, ;, (, ), /, :, <, >
    /// We allow parentheses in DOIs as they're common in some publishers
    private static let doiPattern = #"10\.\d{4,}(?:\.\d+)*/[^\s\]},\"']+"#
    
    /// Pattern to match DOI with common prefixes (doi:, DOI:, etc.)
    private static let doiWithPrefixPattern = #"(?:doi:|DOI:)\s*"# + doiPattern
    
    /// Pattern to match DOI URLs (doi.org, dx.doi.org)
    private static let doiURLPattern = #"(?:https?://)?(?:dx\.)?doi\.org/"# + doiPattern
    
    /// Combined pattern that matches DOI in any common format
    private static let combinedPattern = #"(?:(?:https?://)?(?:dx\.)?doi\.org/|(?:doi:|DOI:)\s*)?(10\.\d{4,}(?:\.\d+)*/[^\s\]},\"']+)"#
    
    // MARK: - Public Methods
    
    /// Checks if the given string contains a DOI.
    ///
    /// - Parameter text: The text to search for DOIs.
    /// - Returns: `true` if a DOI is found, `false` otherwise.
    public static func containsDOI(_ text: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
            return false
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
    
    /// Extracts the first DOI from the given text.
    ///
    /// - Parameter text: The text to search for DOIs.
    /// - Returns: The extracted DOI (without URL prefix), or `nil` if none found.
    ///
    /// The returned DOI is in the canonical form `10.xxxx/yyyy` without any
    /// URL or `doi:` prefix.
    public static func extractDOI(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let doiRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return cleanDOI(String(text[doiRange]))
    }
    
    /// Extracts all DOIs from the given text.
    ///
    /// - Parameter text: The text to search for DOIs.
    /// - Returns: An array of extracted DOIs (without URL prefixes).
    public static func extractAllDOIs(from text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        return matches.compactMap { match in
            guard match.numberOfRanges > 1,
                  let doiRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return cleanDOI(String(text[doiRange]))
        }
    }
    
    /// Validates whether a string is a valid DOI format.
    ///
    /// - Parameter doi: The DOI string to validate.
    /// - Returns: `true` if the string matches DOI format, `false` otherwise.
    ///
    /// This validates the format only, not whether the DOI actually exists.
    public static func isValidDOI(_ doi: String) -> Bool {
        let pattern = #"^10\.\d{4,}(?:\.\d+)*/[^\s]+$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return false
        }
        let range = NSRange(doi.startIndex..., in: doi)
        return regex.firstMatch(in: doi, options: [], range: range) != nil
    }
    
    /// Creates a URL for resolving the DOI.
    ///
    /// - Parameter doi: The DOI string (with or without URL prefix).
    /// - Returns: A URL pointing to doi.org resolver, or `nil` if invalid.
    public static func doiURL(for doi: String) -> URL? {
        // First extract the clean DOI if it has a prefix
        let cleanedDOI = extractDOI(from: doi) ?? doi
        
        guard isValidDOI(cleanedDOI) else {
            return nil
        }
        
        // URL-encode the DOI for the path
        guard let encoded = cleanedDOI.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        
        return URL(string: "https://doi.org/\(encoded)")
    }
    
    /// Normalizes a DOI string to its canonical form.
    ///
    /// - Parameter doi: The DOI string (may include URL prefix, doi: prefix, etc.).
    /// - Returns: The normalized DOI in `10.xxxx/yyyy` format, or `nil` if invalid.
    public static func normalize(_ doi: String) -> String? {
        guard let extracted = extractDOI(from: doi),
              isValidDOI(extracted) else {
            return nil
        }
        return extracted
    }
    
    // MARK: - Private Methods
    
    /// Cleans trailing punctuation from a DOI that might be part of surrounding text.
    private static func cleanDOI(_ doi: String) -> String {
        var cleaned = doi
        
        // Remove trailing punctuation that's likely part of the surrounding sentence
        let trailingPunctuation: Set<Character> = [".", ",", ";", ":"]
        while let last = cleaned.last, trailingPunctuation.contains(last) {
            cleaned.removeLast()
        }
        
        // Handle unbalanced trailing parentheses/brackets
        // Only remove trailing ) or ] if they're unbalanced
        while let last = cleaned.last {
            if last == ")" {
                let openCount = cleaned.filter { $0 == "(" }.count
                let closeCount = cleaned.filter { $0 == ")" }.count
                if closeCount > openCount {
                    cleaned.removeLast()
                } else {
                    break
                }
            } else if last == "]" {
                let openCount = cleaned.filter { $0 == "[" }.count
                let closeCount = cleaned.filter { $0 == "]" }.count
                if closeCount > openCount {
                    cleaned.removeLast()
                } else {
                    break
                }
            } else if last == ">" {
                cleaned.removeLast()
            } else {
                break
            }
        }
        
        return cleaned
    }
}

// MARK: - BibTeXEntry Extension

extension BibTeXEntry {
    
    /// The DOI as a resolvable URL.
    ///
    /// Returns a URL pointing to doi.org for resolving this entry's DOI.
    /// Returns `nil` if no DOI is present or if it's invalid.
    public var doiURL: URL? {
        guard let doi = self.doi else { return nil }
        return DOIDetector.doiURL(for: doi)
    }
    
    /// Whether this entry has a valid DOI.
    public var hasValidDOI: Bool {
        guard let doi = self.doi else { return false }
        let normalized = DOIDetector.normalize(doi)
        return normalized != nil && DOIDetector.isValidDOI(normalized!)
    }
    
    /// The normalized DOI in canonical format.
    ///
    /// Returns the DOI in `10.xxxx/yyyy` format, stripping any URL or prefix.
    /// Returns `nil` if no DOI is present.
    public var normalizedDOI: String? {
        guard let doi = self.doi else { return nil }
        return DOIDetector.normalize(doi)
    }
}
