//
//  AlbumCoverSelectionTests.swift
//  Simple Photo ViewerTests
//
//  What ViewModel.setAlbumCover does to stored settings. Resolving the choice back
//  into an actual PHAsset needs a real photo library and is covered by
//  AlbumCoverPickerUITests instead.
//

import XCTest
@testable import Simple_Photo_Viewer

final class AlbumCoverSelectionTests: XCTestCase {
    private let suite = "AlbumCoverSelectionTests"

    private func makeViewModel(storing stored: Data? = nil) -> ViewModel {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        if let stored { defaults.set(stored, forKey: "albumSettings") }
        return ViewModel(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func testSettingACoverStoresItsIdentifier() throws {
        let stored = try JSONEncoder().encode(["a": AlbumSettings()])
        let viewModel = makeViewModel(storing: stored)

        viewModel.setAlbumCover("a", to: "some-asset-id")

        XCTAssertEqual(viewModel.albumSettings["a"]?.coverAssetIdentifier, "some-asset-id")
    }

    /// `nil` clears a previous choice, going back to following the newest photo.
    func testClearingACoverRemovesItsIdentifier() throws {
        let stored = try JSONEncoder().encode(["a": AlbumSettings(coverAssetIdentifier: "old-id")])
        let viewModel = makeViewModel(storing: stored)

        viewModel.setAlbumCover("a", to: nil)

        XCTAssertNil(viewModel.albumSettings["a"]?.coverAssetIdentifier)
    }

    /// Choosing a cover must not disturb the album's other settings.
    func testSettingACoverPreservesVisibilityAndColor() throws {
        let stored = try JSONEncoder().encode([
            "a": AlbumSettings(isVisible: false, colorHex: "#1E88E5")
        ])
        let viewModel = makeViewModel(storing: stored)

        viewModel.setAlbumCover("a", to: "some-asset-id")

        XCTAssertEqual(viewModel.albumSettings["a"]?.isVisible, false)
        XCTAssertEqual(viewModel.albumSettings["a"]?.colorHex, "#1E88E5")
    }
}
