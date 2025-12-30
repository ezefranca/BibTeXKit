//
//  BibTeXViewConfigurationTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
import SwiftUI
@testable import BibTeXKit

final class BibTeXViewConfigurationTests: XCTestCase {
    
    // MARK: - Default Initialization Tests
    
    func testDefaultValues() {
        let config = BibTeXViewConfiguration()
        
        XCTAssertFalse(config.showLineNumbers)
        XCTAssertTrue(config.showCopyButton)
        XCTAssertFalse(config.showMetadata)
        XCTAssertTrue(config.enableTextSelection)
        XCTAssertEqual(config.formattingStyle, .standard)
        XCTAssertNil(config.maxHeight)
        XCTAssertNil(config.minHeight)
        XCTAssertTrue(config.adaptToColorScheme)
        XCTAssertEqual(config.cornerRadius, 8)
        XCTAssertEqual(config.lineSpacing, 1.2)
        XCTAssertTrue(config.showBorder)
        XCTAssertEqual(config.borderWidth, 1)
        XCTAssertEqual(config.copyButtonPosition, .topTrailing)
        XCTAssertEqual(config.copyButtonStyle, .iconOnly)
    }
    
    // MARK: - Custom Initialization Tests
    
    func testCustomInitialization() {
        let config = BibTeXViewConfiguration(
            showLineNumbers: true,
            showCopyButton: false,
            showMetadata: true,
            enableTextSelection: false,
            formattingStyle: .compact,
            maxHeight: 300,
            minHeight: 100,
            cornerRadius: 12,
            lineSpacing: 1.5,
            showBorder: false,
            borderWidth: 2,
            copyButtonPosition: .bottomTrailing,
            copyButtonStyle: .labeled
        )
        
        XCTAssertTrue(config.showLineNumbers)
        XCTAssertFalse(config.showCopyButton)
        XCTAssertTrue(config.showMetadata)
        XCTAssertFalse(config.enableTextSelection)
        XCTAssertEqual(config.formattingStyle, .compact)
        XCTAssertEqual(config.maxHeight, 300)
        XCTAssertEqual(config.minHeight, 100)
        XCTAssertEqual(config.cornerRadius, 12)
        XCTAssertEqual(config.lineSpacing, 1.5)
        XCTAssertFalse(config.showBorder)
        XCTAssertEqual(config.borderWidth, 2)
        XCTAssertEqual(config.copyButtonPosition, .bottomTrailing)
        XCTAssertEqual(config.copyButtonStyle, .labeled)
    }
    
    // MARK: - Preset Tests
    
    func testMinimalPreset() {
        let config = BibTeXViewConfiguration.minimal
        
        XCTAssertFalse(config.showLineNumbers)
        XCTAssertFalse(config.showCopyButton)
        XCTAssertFalse(config.showMetadata)
        XCTAssertEqual(config.cornerRadius, 4)
        XCTAssertFalse(config.showBorder)
    }
    
    func testCompactPreset() {
        let config = BibTeXViewConfiguration.compact
        
        XCTAssertFalse(config.showLineNumbers)
        XCTAssertTrue(config.showCopyButton)
        XCTAssertFalse(config.showMetadata)
        XCTAssertEqual(config.formattingStyle, .compact)
        XCTAssertEqual(config.cornerRadius, 6)
        XCTAssertEqual(config.copyButtonStyle, .iconOnly)
    }
    
    func testFullPreset() {
        let config = BibTeXViewConfiguration.full
        
        XCTAssertTrue(config.showLineNumbers)
        XCTAssertTrue(config.showCopyButton)
        XCTAssertTrue(config.showMetadata)
        XCTAssertEqual(config.formattingStyle, .aligned)
        XCTAssertEqual(config.cornerRadius, 12)
    }
    
    func testMobilePreset() {
        let config = BibTeXViewConfiguration.mobile
        
        XCTAssertFalse(config.showLineNumbers)
        XCTAssertTrue(config.showCopyButton)
        XCTAssertFalse(config.showMetadata)
        XCTAssertEqual(config.formattingStyle, .compact)
        XCTAssertEqual(config.copyButtonPosition, .topTrailing)
        XCTAssertEqual(config.copyButtonStyle, .iconOnly)
    }
    
    // MARK: - Theme Resolution Tests
    
    func testThemeForLightColorScheme() {
        let config = BibTeXViewConfiguration()
        let theme = config.theme(for: .light)
        
        XCTAssertEqual(theme.name, "Default Light")
    }
    
    func testThemeForDarkColorScheme() {
        let config = BibTeXViewConfiguration()
        let theme = config.theme(for: .dark)
        
        XCTAssertEqual(theme.name, "Default Dark")
    }
    
    func testExplicitThemeOverridesAdaptive() {
        var config = BibTeXViewConfiguration()
        config.explicitTheme = MonokaiTheme()
        
        let lightTheme = config.theme(for: .light)
        let darkTheme = config.theme(for: .dark)
        
        XCTAssertEqual(lightTheme.name, "Monokai")
        XCTAssertEqual(darkTheme.name, "Monokai")
    }
    
    func testCustomLightAndDarkThemes() {
        var config = BibTeXViewConfiguration()
        config.lightTheme = SolarizedLightTheme()
        config.darkTheme = SolarizedDarkTheme()
        
        let lightTheme = config.theme(for: .light)
        let darkTheme = config.theme(for: .dark)
        
        XCTAssertEqual(lightTheme.name, "Solarized Light")
        XCTAssertEqual(darkTheme.name, "Solarized Dark")
    }
    
    // MARK: - Copy Button Position Tests
    
    func testAllCopyButtonPositions() {
        let positions: [BibTeXViewConfiguration.CopyButtonPosition] = [
            .topLeading, .topTrailing, .bottomLeading, .bottomTrailing, .inline
        ]
        
        for position in positions {
            var config = BibTeXViewConfiguration()
            config.copyButtonPosition = position
            XCTAssertEqual(config.copyButtonPosition, position)
        }
    }
    
    // MARK: - Copy Button Style Tests
    
    func testAllCopyButtonStyles() {
        let styles: [BibTeXViewConfiguration.CopyButtonStyle] = [
            .iconOnly, .labeled, .compact
        ]
        
        for style in styles {
            var config = BibTeXViewConfiguration()
            config.copyButtonStyle = style
            XCTAssertEqual(config.copyButtonStyle, style)
        }
    }
    
    // MARK: - Padding Tests
    
    func testDefaultPadding() {
        let config = BibTeXViewConfiguration()
        
        XCTAssertEqual(config.contentPadding.top, 12)
        XCTAssertEqual(config.contentPadding.leading, 12)
        XCTAssertEqual(config.contentPadding.bottom, 12)
        XCTAssertEqual(config.contentPadding.trailing, 12)
    }
    
    func testCustomPadding() {
        let padding = EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16)
        let config = BibTeXViewConfiguration(contentPadding: padding)
        
        XCTAssertEqual(config.contentPadding.top, 20)
        XCTAssertEqual(config.contentPadding.leading, 16)
    }
    
    // MARK: - Formatting Style Tests
    
    func testAllFormattingStyles() {
        let styles: [BibTeXEntry.FormattingStyle] = [
            .standard, .compact, .minimal, .aligned
        ]
        
        for style in styles {
            let config = BibTeXViewConfiguration(formattingStyle: style)
            XCTAssertEqual(config.formattingStyle, style)
        }
    }
    
    // MARK: - Sendable Tests
    
    func testConfigurationIsSendable() {
        let config = BibTeXViewConfiguration()
        
        Task {
            let _ = config.showCopyButton
        }
        
        XCTAssertNotNil(config)
    }
    
    // MARK: - Mutability Tests
    
    func testConfigurationMutability() {
        var config = BibTeXViewConfiguration()
        
        config.showLineNumbers = true
        config.showCopyButton = false
        config.cornerRadius = 20
        
        XCTAssertTrue(config.showLineNumbers)
        XCTAssertFalse(config.showCopyButton)
        XCTAssertEqual(config.cornerRadius, 20)
    }
}
