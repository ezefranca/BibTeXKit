//
//  NativeSurfaceCoverageTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import SwiftUI
import Testing

@testable import BibTeXKit

@Suite("Given the complete native theme surface")
struct NativeThemeSurfaceCoverageTests {
    @Test(
        "Given every built-in theme, when its complete palette is used, then token mappings and UI contrast invariants hold"
    )
    func builtInThemesExposeCompleteUsablePalettes() {
        let themes: [any BibTeXTheme] = [
            DefaultLightTheme(),
            DefaultDarkTheme(),
            XcodeLightTheme(),
            XcodeDarkTheme(),
            MonokaiTheme(),
            SolarizedLightTheme(),
            SolarizedDarkTheme(),
        ]

        for theme in themes {
            let mappedColors = BibTeXToken.allCases.map(theme.color(for:))

            #expect(mappedColors.count == BibTeXToken.allCases.count)
            #expect(theme.environmentColor == theme.commandColor)
            #expect(theme.specialCharColor == theme.accentColor)
            #expect(theme.backgroundColor != theme.textColor, "\(theme.name)")
            #expect(theme.backgroundColor != theme.borderColor, "\(theme.name)")
            #expect(theme.backgroundColor != theme.selectionColor, "\(theme.name)")
            #expect(!String(reflecting: theme.font).isEmpty)
        }
    }

    @Test(
        "Given an adaptive theme, when its direct properties are read, then every value delegates to its resolved light theme"
    )
    func adaptiveThemeDelegatesEveryDirectProperty() {
        let light = XcodeLightTheme()
        let adaptive = AdaptiveTheme(light: light, dark: XcodeDarkTheme())

        let adaptiveColors = [
            adaptive.backgroundColor,
            adaptive.textColor,
            adaptive.entryTypeColor,
            adaptive.citationKeyColor,
            adaptive.fieldNameColor,
            adaptive.stringColor,
            adaptive.numberColor,
            adaptive.punctuationColor,
            adaptive.operatorColor,
            adaptive.commentColor,
            adaptive.specialColor,
            adaptive.constantColor,
            adaptive.commandColor,
            adaptive.mathColor,
            adaptive.accentColor,
            adaptive.environmentColor,
            adaptive.specialCharColor,
            adaptive.borderColor,
            adaptive.lineNumberColor,
            adaptive.selectionColor,
        ]
        let expectedColors = [
            light.backgroundColor,
            light.textColor,
            light.entryTypeColor,
            light.citationKeyColor,
            light.fieldNameColor,
            light.stringColor,
            light.numberColor,
            light.punctuationColor,
            light.operatorColor,
            light.commentColor,
            light.specialColor,
            light.constantColor,
            light.commandColor,
            light.mathColor,
            light.accentColor,
            light.environmentColor,
            light.specialCharColor,
            light.borderColor,
            light.lineNumberColor,
            light.selectionColor,
        ]

        #expect(adaptive.name == light.name)
        #expect(adaptiveColors == expectedColors)
        #expect(String(reflecting: adaptive.font) == String(reflecting: light.font))
    }
}

@Suite("Given the complete native BibTeX view surface")
struct NativeViewSurfaceCoverageTests {
    @MainActor
    @Test(
        "Given a model entry and every public view modifier, when rendered, then the composed native view remains valid"
    )
    func entryInitializerAndModifiersComposeIntoARenderableView() throws {
        let entry = BibTeXEntry(
            type: .misc,
            citationKey: "native",
            fields: ["title": "Native SDK"]
        )
        let content = BibTeXView(entry: entry)
            .bibTeXTheme(XcodeLightTheme())
            .lineNumbers(false)
            .copyButtonHidden()
            .copyButtonStyle(.compact)
            .showMetadata(false)
            .formattingStyle(.minimal)
            .maxHeight(nil)
            .minHeight(80)
            .cornerRadius(6)
            .bordered(false)
            .textSelection(false)
            .contentPadding(
                EdgeInsets(top: 4, leading: 6, bottom: 8, trailing: 10)
            )
            .contentPadding(12)
            .preset(.full)
            .bibTeXTheme(XcodeLightTheme())
            .copyButtonStyle(.labeled)
            .textSelection(false)
            .frame(width: 420, height: 220)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        let image = try #require(renderer.cgImage)

        #expect(image.width == 420)
        #expect(image.height == 220)
    }

    @MainActor
    @Test(
        "Given every copy-button presentation, when rendered, then each style produces native content"
    )
    func everyCopyButtonStyleRenders() {
        let styles: [BibTeXViewConfiguration.CopyButtonStyle] = [
            .iconOnly,
            .labeled,
            .compact,
        ]

        for style in styles {
            let content = BibTeXView(bibtex: "@misc{style}")
                .copyButtonStyle(style)
                .frame(width: 320, height: 120)
            let renderer = ImageRenderer(content: content)

            #expect(renderer.cgImage != nil)
        }
    }

    @Test(
        "Given negative and nonfinite layout values, when sanitized for rendering, then no invalid geometry escapes"
    )
    func invalidGeometryIsSanitized() {
        let configuration = BibTeXViewConfiguration(
            maxHeight: .infinity,
            minHeight: -1,
            contentPadding: EdgeInsets(
                top: .nan,
                leading: .infinity,
                bottom: -.infinity,
                trailing: 5
            ),
            cornerRadius: .nan,
            lineSpacing: .infinity,
            borderWidth: -2
        )

        #expect(configuration.renderedMaximumHeight == nil)
        #expect(configuration.renderedMinimumHeight == nil)
        #expect(configuration.renderedCornerRadius == 0)
        #expect(configuration.renderedLineSpacing == 0)
        #expect(configuration.renderedBorderWidth == 0)
        #expect(configuration.renderedContentPadding.top == 0)
        #expect(configuration.renderedContentPadding.leading == 0)
        #expect(configuration.renderedContentPadding.bottom == 0)
        #expect(configuration.renderedContentPadding.trailing == 5)
    }
}
