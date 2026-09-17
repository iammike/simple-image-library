//
//  AlbumVisibilityTests.swift
//  Simple Photo ViewerTests
//
//  Album visibility is how an adult decides what the viewer may see, so these cover
//  the state that decides it rather than the formatting around it.
//

import XCTest
@testable import Simple_Photo_Viewer

final class AlbumVisibilityTests: XCTestCase {

    /// Toggling persists, so the model gets its own suite rather than writing the
    /// album configuration of whatever copy of the app shares this simulator.
    private let suite = "AlbumVisibilityTests"

    private func makeViewModel() -> ViewModel {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return ViewModel(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    /// Hiding used to bail out when an album had no stored settings, so the eye
    /// button silently did nothing for any album discovered by a refresh.
    func testHidingAlbumWithNoStoredSettings() {
        let viewModel = makeViewModel()
        viewModel.albumSettings = [:]

        viewModel.toggleAlbumVisibility("album-with-no-entry")

        XCTAssertEqual(viewModel.albumSettings["album-with-no-entry"]?.isVisible, false)
    }

    func testHidingThenShowingReturnsToVisible() {
        let viewModel = makeViewModel()
        viewModel.albumSettings = ["a": AlbumSettings(isVisible: true)]

        viewModel.toggleAlbumVisibility("a")
        XCTAssertEqual(viewModel.albumSettings["a"]?.isVisible, false)

        viewModel.toggleAlbumVisibility("a")
        XCTAssertEqual(viewModel.albumSettings["a"]?.isVisible, true)
    }

    func testTogglingPreservesAssignedColor() {
        let viewModel = makeViewModel()
        viewModel.albumSettings = ["a": AlbumSettings(isVisible: true, colorHex: "#FF8C42")]

        viewModel.toggleAlbumVisibility("a")

        XCTAssertEqual(viewModel.albumSettings["a"]?.colorHex, "#FF8C42")
    }

    /// An album with no stored settings counts as visible, which is what the album
    /// list has always assumed. The selection code used to assume the opposite.
    func testAlbumWithoutSettingsCountsAsVisible() {
        let viewModel = makeViewModel()
        viewModel.albumSettings = [:]

        XCTAssertTrue(viewModel.isVisibleAlbum(identifiedBy: "unseen-album"))
    }

    func testHiddenAlbumDoesNotCountAsVisible() {
        let viewModel = makeViewModel()
        viewModel.albumSettings = ["a": AlbumSettings(isVisible: false)]

        XCTAssertFalse(viewModel.isVisibleAlbum(identifiedBy: "a"))
    }

    /// The settings dictionary is persisted as [String: AlbumSettings]. A previous
    /// seeding path decoded that blob as a single AlbumSettings, which always failed.
    func testSettingsRoundTripAsADictionary() throws {
        let stored = ["a": AlbumSettings(isVisible: false, colorHex: "#00FF00")]
        let data = try JSONEncoder().encode(stored)

        let decoded = try JSONDecoder().decode([String: AlbumSettings].self, from: data)

        XCTAssertEqual(decoded["a"]?.isVisible, false)
        XCTAssertEqual(decoded["a"]?.colorHex, "#00FF00")
        XCTAssertNil(try? JSONDecoder().decode(AlbumSettings.self, from: data))
    }
}
