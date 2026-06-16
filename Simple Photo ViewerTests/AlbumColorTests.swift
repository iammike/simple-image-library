//
//  AlbumColorTests.swift
//  Simple Photo ViewerTests
//

import XCTest
@testable import Simple_Photo_Viewer

final class AlbumColorTests: XCTestCase {
    func testPaletteIsNonEmptyAndDistinct() {
        let colors = AlbumColorPalette.colors
        XCTAssertFalse(colors.isEmpty)
        XCTAssertEqual(Set(colors).count, colors.count, "Palette colors should be distinct")
    }

    func testCycleFromNoneGoesToFirstColor() {
        XCTAssertEqual(AlbumColorPalette.next(after: nil), AlbumColorPalette.colors.first)
    }

    func testCycleAdvancesThroughColors() {
        let colors = AlbumColorPalette.colors
        XCTAssertEqual(AlbumColorPalette.next(after: colors[0]), colors[1])
    }

    func testCycleFromLastColorReturnsToNone() {
        XCTAssertNil(AlbumColorPalette.next(after: AlbumColorPalette.colors.last))
    }

    func testCycleFromUnknownColorReturnsFirst() {
        XCTAssertEqual(AlbumColorPalette.next(after: "#NOTREAL"), AlbumColorPalette.colors.first)
    }
}
