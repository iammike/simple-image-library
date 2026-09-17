//
//  FixtureProofTests.swift
//  Simple Photo ViewerUITests
//
//  Proves the fixture mechanism itself, separately from any assertion about the app.
//  If these fail, nothing else in the suite can be trusted.
//

import Photos
import XCTest

final class FixtureProofTests: ViewerUITestCase {

    /// The runner process can reach `.authorized` and create named user albums.
    func testRunnerSeedsNamedAlbums() throws {
        for spec in PhotoLibraryFixture.specs {
            XCTAssertNotNil(
                PhotoLibraryFixture.fetchAlbum(named: spec.name),
                "\(spec.name) was not created"
            )
            XCTAssertEqual(
                PhotoLibraryFixture.assetCount(inAlbumNamed: spec.name),
                spec.assetCount,
                "\(spec.name) holds the wrong number of assets"
            )
        }
    }

    /// Re-seeding is a no-op, so tests can call `seed()` in every `setUp`.
    func testSeedingIsIdempotent() throws {
        let before = PhotoLibraryFixture.specs.map {
            PhotoLibraryFixture.assetCount(inAlbumNamed: $0.name)
        }
        try PhotoLibraryFixture.seed()
        let after = PhotoLibraryFixture.specs.map {
            PhotoLibraryFixture.assetCount(inAlbumNamed: $0.name)
        }
        XCTAssertEqual(before, after)
    }

    /// The launch-argument reset really reaches the app: `-isSetupMode` decides which
    /// screen opens, with nothing persisted between runs. Everything else in the suite
    /// depends on this, so it is asserted rather than assumed.
    func testLaunchArgumentsChooseTheStartingScreen() throws {
        let setup = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(setup.navigationBars["Setup"].waitForExistence(timeout: 20))
        setup.terminate()

        let viewer = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(viewer.staticTexts["Albums"].waitForExistence(timeout: 20))
        XCTAssertFalse(viewer.navigationBars["Setup"].exists)
    }

    /// `-albumSettings <7b7d>` (an old-style plist data literal for `{}`) restores
    /// every album to visible, so a test that hides something cannot poison the next
    /// one. Without this each test would have to unhide by hand through the UI.
    func testAlbumSettingsResetSurvivesAHiddenAlbum() throws {
        let hiding = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(hiding.navigationBars["Setup"].waitForExistence(timeout: 20))
        hiding.hideAlbum(named: "Fixture Alpha")
        hiding.finishSetup()
        XCTAssertTrue(hiding.staticTexts["Albums"].waitForExistence(timeout: 10))
        XCTAssertFalse(hiding.staticTexts["Fixture Alpha"].exists)
        hiding.terminate()

        let fresh = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(fresh.staticTexts["Albums"].waitForExistence(timeout: 20))
        XCTAssertTrue(
            fresh.staticTexts["Fixture Alpha"].exists,
            "The hidden album stayed hidden; the launch-argument reset did not take"
        )
    }
}
