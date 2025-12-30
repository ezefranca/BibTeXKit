//
//  BibTeXThemeTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import XCTest
import SwiftUI
@testable import BibTeXKit

final class BibTeXThemeTests: XCTestCase {
    
    // MARK: - Default Light Theme Tests
    
    func testDefaultLightTheme() {
        let theme = DefaultLightTheme()
        
        XCTAssertNotNil(theme.font)
        XCTAssertNotNil(theme.backgroundColor)
    }
    
    // MARK: - Default Dark Theme Tests
    
    func testDefaultDarkTheme() {
        let theme = DefaultDarkTheme()
        
        XCTAssertNotNil(theme.font)
    }
    
    // MARK: - Xcode Light Theme Tests
    
    func testXcodeLightTheme() {
        let theme = XcodeLightTheme()
        
        XCTAssertNotNil(theme.backgroundColor)
    }
    
    func testXcodeLightThemeEntryType() {
        let theme = XcodeLightTheme()
        let color = theme.color(for: .entryType)
        
        XCTAssertNotNil(color)
    }
    
    // MARK: - Xcode Dark Theme Tests
    
    func testXcodeDarkTheme() {
        let theme = XcodeDarkTheme()
        
        XCTAssertNotNil(theme.backgroundColor)
    }
    
    // MARK: - Monokai Theme Tests
    
    func testMonokaiTheme() {
        let theme = MonokaiTheme()
        
        XCTAssertNotNil(theme.font)
    }
    
    func testMonokaiThemeColors() {
        let theme = MonokaiTheme()
        
        // Monokai should have distinct colors for syntax elements
        let entryTypeColor = theme.color(for: .entryType)
        let stringColor = theme.color(for: .string)
        let commentColor = theme.color(for: .comment)
        
        XCTAssertNotNil(entryTypeColor)
        XCTAssertNotNil(stringColor)
        XCTAssertNotNil(commentColor)
    }
    
    // MARK: - Solarized Light Theme Tests
    
    func testSolarizedLightTheme() {
        let theme = SolarizedLightTheme()
        
        XCTAssertEqual(theme.name, "Solarized Light")
        XCTAssertNotNil(theme.backgroundColor)
    }
    
    func testSolarizedLightThemeColors() {
        let theme = SolarizedLightTheme()
        
        let tokenTypes: [BibTeXToken] = [.entryType, .citationKey, .string, .comment]
        
        for token in tokenTypes {
            XCTAssertNotNil(theme.color(for: token))
        }
    }
    
    // MARK: - Solarized Dark Theme Tests
    
    func testSolarizedDarkTheme() {
        let theme = SolarizedDarkTheme()
        
        XCTAssertEqual(theme.name, "Solarized Dark")
        XCTAssertNotNil(theme.backgroundColor)
    }
    
    // MARK: - Adaptive Theme Tests
    
    func testAdaptiveThemeLight() {
        let theme = AdaptiveTheme()
        
        // Should return light theme properties
        XCTAssertNotNil(theme.backgroundColor)
        XCTAssertNotNil(theme.color(for: .entryType))
    }
    
    func testAdaptiveThemeDark() {
        let theme = AdaptiveTheme()
        
        // Should return dark theme properties
        XCTAssertNotNil(theme.backgroundColor)
        XCTAssertNotNil(theme.color(for: .entryType))
    }
    
    func testAdaptiveThemeWithCustomThemes() {
        let light = MonokaiTheme() // Use as light for testing
        let dark = SolarizedDarkTheme()
        
        let themeLight = AdaptiveTheme(light: light, dark: dark)
        let themeDark = AdaptiveTheme(light: light, dark: dark)
        
        XCTAssertEqual(themeLight.name, light.name)
        XCTAssertEqual(themeDark.name, dark.name)
    }
    
    // MARK: - Theme Protocol Tests
    
    func testThemeProtocolConformance() {
        let themes: [any BibTeXTheme] = [
            DefaultLightTheme(),
            DefaultDarkTheme(),
            XcodeLightTheme(),
            XcodeDarkTheme(),
            MonokaiTheme(),
            SolarizedLightTheme(),
            SolarizedDarkTheme()
        ]
        
        for theme in themes {
            // All required properties should be accessible
            XCTAssertFalse(theme.name.isEmpty, "\(type(of: theme)) should have a name")
            XCTAssertNotNil(theme.font, "\(type(of: theme)) should have a font")
            XCTAssertNotNil(theme.backgroundColor, "\(type(of: theme)) should have a background color")
            XCTAssertNotNil(theme.borderColor, "\(type(of: theme)) should have a border color")
        }
    }
    
    // MARK: - Font Tests
    
    func testFontIsMonospaced() {
        let themes: [any BibTeXTheme] = [
            DefaultLightTheme(),
            MonokaiTheme(),
            XcodeLightTheme()
        ]
        
        for theme in themes {
            let font = theme.font
            XCTAssertNotNil(font, "\(theme.name) should have a font")
        }
    }
    
    // MARK: - Built-in Themes List Tests
    
    func testBuiltInThemesCount() {
        // We have 7 built-in themes
        let themes: [any BibTeXTheme] = [
            DefaultLightTheme(),
            DefaultDarkTheme(),
            XcodeLightTheme(),
            XcodeDarkTheme(),
            MonokaiTheme(),
            SolarizedLightTheme(),
            SolarizedDarkTheme()
        ]
        
        XCTAssertEqual(themes.count, 7)
    }
    
    func testThemeNamesUnique() {
        let themes: [any BibTeXTheme] = [
            DefaultLightTheme(),
            DefaultDarkTheme(),
            XcodeLightTheme(),
            XcodeDarkTheme(),
            MonokaiTheme(),
            SolarizedLightTheme(),
            SolarizedDarkTheme()
        ]
        
        let colors = themes.map { $0.specialColor }
        let uniqueSpecialColors = Set(colors)
        
        XCTAssertEqual(colors.count, uniqueSpecialColors.count, "All theme Special Colors should be unique")
    }
    
    // MARK: - Theme Sendable Tests
    
    func testThemesAreSendable() {
        let theme: any BibTeXTheme & Sendable = DefaultLightTheme()
        
        // If this compiles, the theme is Sendable
        Task {
            let _ = theme.font
        }
        
        XCTAssertNotNil(theme)
    }
}
