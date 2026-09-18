//
//  AlbumSettingsTests.swift
//  Simple Photo ViewerTests
//

import XCTest
@testable import Simple_Photo_Viewer

final class AlbumSettingsTests: XCTestCase {
    func testDefaultsAreVisibleWithNoColor() {
        let settings = AlbumSettings()
        XCTAssertTrue(settings.isVisible)
        XCTAssertNil(settings.colorHex)
    }

    func testEncodeDecodeRoundTripWithColor() throws {
        var settings = AlbumSettings(isVisible: false)
        settings.colorHex = "#1E88E5"

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AlbumSettings.self, from: data)

        XCTAssertFalse(decoded.isVisible)
        XCTAssertEqual(decoded.colorHex, "#1E88E5")
    }

    func testDecodeLegacyJSONWithoutColorHex() throws {
        // Data persisted by earlier versions only contained isVisible.
        let legacy = Data("{\"isVisible\":true}".utf8)

        let decoded = try JSONDecoder().decode(AlbumSettings.self, from: legacy)

        XCTAssertTrue(decoded.isVisible)
        XCTAssertNil(decoded.colorHex)
    }

    func testEncodeDecodeRoundTripWithCover() throws {
        var settings = AlbumSettings()
        settings.coverAssetIdentifier = "ABCD-1234/L0/001"

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AlbumSettings.self, from: data)

        XCTAssertEqual(decoded.coverAssetIdentifier, "ABCD-1234/L0/001")
    }

    func testDecodeDataWithoutCoverAssetIdentifier() throws {
        // Data persisted before the cover picker existed has no such key.
        let legacy = Data("{\"isVisible\":true,\"colorHex\":\"#1E88E5\"}".utf8)

        let decoded = try JSONDecoder().decode(AlbumSettings.self, from: legacy)

        XCTAssertNil(decoded.coverAssetIdentifier)
        XCTAssertEqual(decoded.colorHex, "#1E88E5")
    }
}
