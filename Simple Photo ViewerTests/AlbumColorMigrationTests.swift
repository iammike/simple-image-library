//
//  AlbumColorMigrationTests.swift
//  Simple Photo ViewerTests
//
//  The palette's original orange collided with the app's own accent and was
//  retired (see AlbumColorPalette.legacyOrange). These cover what happens to an
//  album that was already colored with it.
//

import XCTest
@testable import Simple_Photo_Viewer

final class AlbumColorMigrationTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "AlbumColorMigrationTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    private func store(_ settings: [String: AlbumSettings]) throws {
        defaults.set(try JSONEncoder().encode(settings), forKey: "albumSettings")
    }

    private func storedSettings() throws -> [String: AlbumSettings] {
        let data = try XCTUnwrap(defaults.data(forKey: "albumSettings"))
        return try JSONDecoder().decode([String: AlbumSettings].self, from: data)
    }

    func testLegacyOrangeAlbumIsMigratedOnLoad() throws {
        try store(["a": AlbumSettings(isVisible: true, colorHex: AlbumColorPalette.legacyOrange)])

        let viewModel = ViewModel(defaults: defaults)

        XCTAssertEqual(
            viewModel.albumSettings["a"]?.colorHex,
            AlbumColorPalette.replacementForLegacyOrange
        )
    }

    /// Visibility is a separate concern from color and must survive the migration
    /// untouched.
    func testMigrationPreservesVisibility() throws {
        try store(["a": AlbumSettings(isVisible: false, colorHex: AlbumColorPalette.legacyOrange)])

        let viewModel = ViewModel(defaults: defaults)

        XCTAssertEqual(viewModel.albumSettings["a"]?.isVisible, false)
    }

    /// The migration is not just an in-memory patch: the stored blob itself must
    /// stop naming the retired color, or every future launch would silently redo
    /// the same rewrite forever.
    func testMigrationIsPersistedToStorage() throws {
        try store(["a": AlbumSettings(colorHex: AlbumColorPalette.legacyOrange)])

        _ = ViewModel(defaults: defaults)

        let saved = try storedSettings()
        XCTAssertEqual(saved["a"]?.colorHex, AlbumColorPalette.replacementForLegacyOrange)
    }

    /// An album with any other color, or none, must be left exactly alone.
    func testNonLegacyColorsAreUntouched() throws {
        try store([
            "red": AlbumSettings(colorHex: "#E53935"),
            "none": AlbumSettings(colorHex: nil)
        ])

        let viewModel = ViewModel(defaults: defaults)

        XCTAssertEqual(viewModel.albumSettings["red"]?.colorHex, "#E53935")
        XCTAssertNil(viewModel.albumSettings["none"]?.colorHex)
    }
}
