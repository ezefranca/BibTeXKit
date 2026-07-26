//
//  BibTeXThemeTests.swift
//  BibTeXKit
//
//  Copyright © 2025. MIT License.
//

import SwiftUI
import Testing
@testable import BibTeXKit

@Suite("Given a BibTeX syntax theme")
struct BibTeXThemeTests {
    @Test("Given the built-in themes, when metadata is inspected, then names are stable and unique")
    func builtInThemeMetadataIsStableAndUnique() {
        let themes: [any BibTeXTheme] = [
            DefaultLightTheme(),
            DefaultDarkTheme(),
            XcodeLightTheme(),
            XcodeDarkTheme(),
            MonokaiTheme(),
            SolarizedLightTheme(),
            SolarizedDarkTheme()
        ]

        #expect(
            themes.map(\.name) == [
                "Default Light",
                "Default Dark",
                "Xcode Light",
                "Xcode Dark",
                "Monokai",
                "Solarized Light",
                "Solarized Dark"
            ]
        )
        #expect(Set(themes.map(\.name)).count == themes.count)
    }

    @Test("Given every token kind, when its color is requested, then it maps to the documented theme property")
    func everyTokenMapsToItsDocumentedColor() {
        let theme = MappingTheme()
        let expectedColors: [BibTeXToken: Color] = [
            .entryType: theme.entryTypeColor,
            .citationKey: theme.citationKeyColor,
            .fieldName: theme.fieldNameColor,
            .string: theme.stringColor,
            .number: theme.numberColor,
            .operator: theme.operatorColor,
            .punctuation: theme.punctuationColor,
            .comment: theme.commentColor,
            .special: theme.specialColor,
            .constant: theme.constantColor,
            .command: theme.commandColor,
            .math: theme.mathColor,
            .environment: theme.environmentColor,
            .accent: theme.accentColor,
            .specialChar: theme.specialCharColor,
            .whitespace: theme.textColor,
            .text: theme.textColor
        ]

        #expect(expectedColors.count == BibTeXToken.allCases.count)
        for token in BibTeXToken.allCases {
            #expect(theme.color(for: token) == expectedColors[token])
        }
    }

    @Test("Given a concrete theme, when either color scheme resolves, then the same theme remains active")
    func concreteThemeResolutionIsStable() {
        let theme = MonokaiTheme()

        #expect(theme.resolved(for: .light).name == "Monokai")
        #expect(theme.resolved(for: .dark).name == "Monokai")
    }

    @Test("Given an adaptive theme, when explicit appearances resolve, then the matching child theme is selected")
    func adaptiveThemeSelectsMatchingChild() {
        let theme = AdaptiveTheme(
            light: XcodeLightTheme(),
            dark: XcodeDarkTheme()
        )

        #expect(theme.name == "Xcode Light")
        #expect(theme.resolved(for: .light).name == "Xcode Light")
        #expect(theme.resolved(for: .dark).name == "Xcode Dark")
    }

    @Test("Given nested adaptive themes, when dark appearance resolves, then resolution continues to a concrete theme")
    func nestedAdaptiveThemesResolveRecursively() {
        let nestedDark = AdaptiveTheme(
            light: SolarizedLightTheme(),
            dark: MonokaiTheme()
        )
        let theme = AdaptiveTheme(
            light: DefaultLightTheme(),
            dark: nestedDark
        )

        #expect(theme.resolved(for: .dark).name == "Monokai")
    }

    @Test("Given a theme value, when sent to a detached task, then its immutable metadata remains readable")
    func themeCrossesTaskBoundary() async {
        let theme: any BibTeXTheme & Sendable = DefaultLightTheme()

        let name = await Task.detached {
            theme.name
        }.value

        #expect(name == "Default Light")
    }
}

private struct MappingTheme: BibTeXTheme {
    let name = "Mapping"
    let backgroundColor = Color(red: 0.01, green: 0.01, blue: 0.01)
    let entryTypeColor = Color(red: 0.02, green: 0.02, blue: 0.02)
    let citationKeyColor = Color(red: 0.03, green: 0.03, blue: 0.03)
    let fieldNameColor = Color(red: 0.04, green: 0.04, blue: 0.04)
    let stringColor = Color(red: 0.05, green: 0.05, blue: 0.05)
    let numberColor = Color(red: 0.06, green: 0.06, blue: 0.06)
    let punctuationColor = Color(red: 0.07, green: 0.07, blue: 0.07)
    let operatorColor = Color(red: 0.08, green: 0.08, blue: 0.08)
    let commentColor = Color(red: 0.09, green: 0.09, blue: 0.09)
    let specialColor = Color(red: 0.10, green: 0.10, blue: 0.10)
    let constantColor = Color(red: 0.11, green: 0.11, blue: 0.11)
    let commandColor = Color(red: 0.12, green: 0.12, blue: 0.12)
    let mathColor = Color(red: 0.13, green: 0.13, blue: 0.13)
    let accentColor = Color(red: 0.14, green: 0.14, blue: 0.14)
    let environmentColor = Color(red: 0.19, green: 0.19, blue: 0.19)
    let specialCharColor = Color(red: 0.20, green: 0.20, blue: 0.20)
    let textColor = Color(red: 0.15, green: 0.15, blue: 0.15)
    let lineNumberColor = Color(red: 0.16, green: 0.16, blue: 0.16)
    let selectionColor = Color(red: 0.17, green: 0.17, blue: 0.17)
    let borderColor = Color(red: 0.18, green: 0.18, blue: 0.18)
    let font = Font.system(.body, design: .monospaced)
}
