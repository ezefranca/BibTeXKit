//
//  BibTeXKitTests.swift
//  BibTeXKit
//
//  Copyright © 2026. MIT License.
//

import Testing
@testable import BibTeXKit

@Suite("Given BibTeXKit release metadata")
struct BibTeXKitTests {
    @Test("Given the public metadata, when read, then it identifies release 1.1.0")
    func releaseMetadataIdentifiesCurrentRelease() {
        #expect(BibTeXKitMetadata.version == "1.1.0")
    }
}
