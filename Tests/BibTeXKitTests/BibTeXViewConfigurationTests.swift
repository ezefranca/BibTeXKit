//
//  BibTeXViewConfigurationTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI
import Testing
@testable import BibTeXKit

@Suite("Given a BibTeX view configuration")
struct BibTeXViewConfigurationTests {
    
    // MARK: - Default Initialization Tests
    
    @Test("Given no arguments, when configuration is initialized, then native defaults are applied")
    func defaultInitializationAppliesNativeDefaults() {
        let config = BibTeXViewConfiguration()
        
        #expect(!config.showLineNumbers)
        #expect(config.showCopyButton)
        #expect(!config.showMetadata)
        #expect(config.enableTextSelection)
        #expect(config.formattingStyle == .standard)
        #expect(config.maxHeight == nil)
        #expect(config.minHeight == nil)
        #expect(config.adaptToColorScheme)
        #expect(config.cornerRadius == 8)
        #expect(config.lineSpacing == 1.2)
        #expect(config.showBorder)
        #expect(config.borderWidth == 1)
        #expect(config.copyButtonPosition == .topTrailing)
        #expect(config.copyButtonStyle == .iconOnly)
    }
    
    // MARK: - Custom Initialization Tests
    
    @Test("Given explicit arguments, when configuration is initialized, then every value is preserved")
    func customInitializationPreservesEveryValue() {
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
        
        #expect(config.showLineNumbers)
        #expect(!config.showCopyButton)
        #expect(config.showMetadata)
        #expect(!config.enableTextSelection)
        #expect(config.formattingStyle == .compact)
        #expect(config.maxHeight == 300)
        #expect(config.minHeight == 100)
        #expect(config.cornerRadius == 12)
        #expect(config.lineSpacing == 1.5)
        #expect(!config.showBorder)
        #expect(config.borderWidth == 2)
        #expect(config.copyButtonPosition == .bottomTrailing)
        #expect(config.copyButtonStyle == .labeled)
    }
    
    // MARK: - Preset Tests
    
    @Test("Given the minimal preset, when inspected, then decoration and controls are disabled")
    func minimalPresetDisablesDecorationAndControls() {
        let config = BibTeXViewConfiguration.minimal
        
        #expect(!config.showLineNumbers)
        #expect(!config.showCopyButton)
        #expect(!config.showMetadata)
        #expect(config.cornerRadius == 4)
        #expect(!config.showBorder)
    }
    
    @Test("Given the compact preset, when inspected, then compact formatting and controls are selected")
    func compactPresetSelectsCompactFormatting() {
        let config = BibTeXViewConfiguration.compact
        
        #expect(!config.showLineNumbers)
        #expect(config.showCopyButton)
        #expect(!config.showMetadata)
        #expect(config.formattingStyle == .compact)
        #expect(config.cornerRadius == 6)
        #expect(config.copyButtonStyle == .iconOnly)
    }
    
    @Test("Given the full preset, when inspected, then metadata, line numbers, and aligned formatting are enabled")
    func fullPresetEnablesCompletePresentation() {
        let config = BibTeXViewConfiguration.full
        
        #expect(config.showLineNumbers)
        #expect(config.showCopyButton)
        #expect(config.showMetadata)
        #expect(config.formattingStyle == .aligned)
        #expect(config.cornerRadius == 12)
    }
    
    @Test("Given the mobile preset, when inspected, then compact touch-friendly presentation is selected")
    func mobilePresetSelectsCompactTouchPresentation() {
        let config = BibTeXViewConfiguration.mobile
        
        #expect(!config.showLineNumbers)
        #expect(config.showCopyButton)
        #expect(!config.showMetadata)
        #expect(config.formattingStyle == .compact)
        #expect(config.copyButtonPosition == .topTrailing)
        #expect(config.copyButtonStyle == .iconOnly)
    }
    
    // MARK: - Theme Resolution Tests
    
    @Test("Given default configuration, when light appearance resolves, then the light theme is returned")
    func lightAppearanceResolvesDefaultLightTheme() {
        let config = BibTeXViewConfiguration()
        let theme = config.theme(for: .light)
        
        #expect(theme.name == "Default Light")
    }
    
    @Test("Given default configuration, when dark appearance resolves, then the dark theme is returned")
    func darkAppearanceResolvesDefaultDarkTheme() {
        let config = BibTeXViewConfiguration()
        let theme = config.theme(for: .dark)
        
        #expect(theme.name == "Default Dark")
    }
    
    @Test("Given an explicit theme, when either appearance resolves, then it overrides adaptive themes")
    func explicitThemeOverridesAdaptiveThemes() {
        var config = BibTeXViewConfiguration()
        config.explicitTheme = MonokaiTheme()
        
        let lightTheme = config.theme(for: .light)
        let darkTheme = config.theme(for: .dark)
        
        #expect(lightTheme.name == "Monokai")
        #expect(darkTheme.name == "Monokai")
    }
    
    @Test("Given custom light and dark themes, when appearances resolve, then each matching theme is returned")
    func customThemesResolveForTheirAppearance() {
        var config = BibTeXViewConfiguration()
        config.lightTheme = SolarizedLightTheme()
        config.darkTheme = SolarizedDarkTheme()
        
        let lightTheme = config.theme(for: .light)
        let darkTheme = config.theme(for: .dark)
        
        #expect(lightTheme.name == "Solarized Light")
        #expect(darkTheme.name == "Solarized Dark")
    }

    @Test("Given adaptation is disabled, when dark appearance resolves, then the light theme remains active")
    func disablingAdaptationKeepsLightTheme() {
        let config = BibTeXViewConfiguration(
            adaptToColorScheme: false,
            lightTheme: XcodeLightTheme(),
            darkTheme: XcodeDarkTheme()
        )

        #expect(config.theme(for: .light).name == "Xcode Light")
        #expect(config.theme(for: .dark).name == "Xcode Light")
    }

    @Test("Given an explicit adaptive theme, when an appearance resolves, then its matching child is returned")
    func explicitAdaptiveThemeResolvesRequestedAppearance() {
        let config = BibTeXViewConfiguration(
            explicitTheme: AdaptiveTheme(
                light: XcodeLightTheme(),
                dark: XcodeDarkTheme()
            )
        )

        #expect(config.theme(for: .light).name == "Xcode Light")
        #expect(config.theme(for: .dark).name == "Xcode Dark")
    }
    
    // MARK: - Copy Button Position Tests
    
    @Test(
        "Given a copy-button position, when assigned, then the configuration preserves it",
        arguments: [
            BibTeXViewConfiguration.CopyButtonPosition.topLeading,
            .topTrailing,
            .bottomLeading,
            .bottomTrailing,
            .inline
        ]
    )
    func copyButtonPositionRoundTrips(
        _ position: BibTeXViewConfiguration.CopyButtonPosition
    ) {
        var config = BibTeXViewConfiguration()
        config.copyButtonPosition = position
        #expect(config.copyButtonPosition == position)
    }
    
    // MARK: - Copy Button Style Tests
    
    @Test(
        "Given a copy-button style, when assigned, then the configuration preserves it",
        arguments: [
            BibTeXViewConfiguration.CopyButtonStyle.iconOnly,
            .labeled,
            .compact
        ]
    )
    func copyButtonStyleRoundTrips(
        _ style: BibTeXViewConfiguration.CopyButtonStyle
    ) {
        var config = BibTeXViewConfiguration()
        config.copyButtonStyle = style
        #expect(config.copyButtonStyle == style)
    }
    
    // MARK: - Padding Tests
    
    @Test("Given default configuration, when padding is inspected, then every edge uses twelve points")
    func defaultPaddingUsesTwelvePointsOnEveryEdge() {
        let config = BibTeXViewConfiguration()
        
        #expect(config.contentPadding.top == 12)
        #expect(config.contentPadding.leading == 12)
        #expect(config.contentPadding.bottom == 12)
        #expect(config.contentPadding.trailing == 12)
    }
    
    @Test("Given custom padding, when configuration is initialized, then its edge values are preserved")
    func customPaddingIsPreserved() {
        let padding = EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16)
        let config = BibTeXViewConfiguration(contentPadding: padding)
        
        #expect(config.contentPadding.top == 20)
        #expect(config.contentPadding.leading == 16)
    }
    
    // MARK: - Formatting Style Tests
    
    @Test(
        "Given a formatting style, when configuration is initialized, then the style is preserved",
        arguments: [
            BibTeXEntry.FormattingStyle.standard,
            .compact,
            .minimal,
            .aligned
        ]
    )
    func formattingStyleIsPreserved(_ style: BibTeXEntry.FormattingStyle) {
        let config = BibTeXViewConfiguration(formattingStyle: style)
        #expect(config.formattingStyle == style)
    }
    
    // MARK: - Sendable Tests
    
    @Test("Given a configuration value, when sent to a detached task, then its state remains readable")
    func configurationCrossesTaskBoundary() async {
        let config = BibTeXViewConfiguration()

        let showCopyButton = await Task.detached {
            config.showCopyButton
        }.value

        #expect(showCopyButton)
    }
    
    // MARK: - Mutability Tests
    
    @Test("Given mutable configuration, when properties change, then each new value is retained")
    func mutableConfigurationRetainsChanges() {
        var config = BibTeXViewConfiguration()
        
        config.showLineNumbers = true
        config.showCopyButton = false
        config.cornerRadius = 20
        
        #expect(config.showLineNumbers)
        #expect(!config.showCopyButton)
        #expect(config.cornerRadius == 20)
    }
}
