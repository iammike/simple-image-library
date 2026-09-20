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

    private func makeViewModel(storing stored: Data? = nil) -> ViewModel {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        if let stored { defaults.set(stored, forKey: "albumSettings") }
        return ViewModel(defaults: defaults)
    }

    private var defaults: UserDefaults { UserDefaults(suiteName: suite)! }

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

    // MARK: - Undecodable stored settings

    private let garbage = Data("not json".utf8)

    /// Visibility is the mechanism that decides what a child may see, so a blob that
    /// will not decode must not fall back to "everything visible".
    func testUndecodableSettingsHideAlbumsWithoutAnEntry() {
        let viewModel = makeViewModel(storing: garbage)

        XCTAssertTrue(viewModel.albumSettingsFailedToDecode)
        XCTAssertFalse(viewModel.isVisibleAlbum(identifiedBy: "any-album"))
    }

    /// A clean read keeps the usual default, so the fail-closed rule cannot leak into
    /// normal operation.
    func testReadableSettingsKeepTheVisibleDefault() throws {
        let stored = try JSONEncoder().encode(["a": AlbumSettings(isVisible: false)])
        let viewModel = makeViewModel(storing: stored)

        XCTAssertFalse(viewModel.albumSettingsFailedToDecode)
        XCTAssertTrue(viewModel.isVisibleAlbum(identifiedBy: "unseen-album"))
        XCTAssertFalse(viewModel.isVisibleAlbum(identifiedBy: "a"))
    }

    /// One tap on the eye in Setup must bring an album back and write settings that
    /// decode next time, or the adult is stuck.
    func testShowingAnAlbumAfterAnUndecodableReadSavesReadableSettings() throws {
        let viewModel = makeViewModel(storing: garbage)
        viewModel.albumSettings["a"] = AlbumSettings(isVisible: false)

        viewModel.toggleAlbumVisibility("a")

        XCTAssertTrue(viewModel.isVisibleAlbum(identifiedBy: "a"))
        let saved = try XCTUnwrap(defaults.data(forKey: "albumSettings"))
        let decoded = try JSONDecoder().decode([String: AlbumSettings].self, from: saved)
        XCTAssertEqual(decoded["a"]?.isVisible, true)
    }

    /// The bad blob is kept aside rather than silently replaced by the next save.
    func testUndecodableSettingsAreKeptAside() {
        let viewModel = makeViewModel(storing: garbage)
        viewModel.albumSettings["a"] = AlbumSettings(isVisible: false)
        viewModel.toggleAlbumVisibility("a")

        XCTAssertEqual(defaults.data(forKey: ViewModel.unreadableAlbumSettingsKey), garbage)
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
