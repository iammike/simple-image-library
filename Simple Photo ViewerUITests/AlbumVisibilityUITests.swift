//
//  AlbumVisibilityUITests.swift
//  Simple Photo ViewerUITests
//
//  Album visibility is the app's core promise: hiding an album is how an adult decides
//  what a child may see, and two bugs on this branch left hidden photos on screen. This
//  is the file worth having.
//

import XCTest

final class AlbumVisibilityUITests: ViewerUITestCase {

    /// Hiding one album in Setup removes it from the album list, and leaves the others.
    func testHidingOneAlbumRemovesItFromTheViewer() throws {
        let app = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 20))

        app.hideAlbum(named: "Fixture Bravo")
        app.finishSetup()

        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 10))
        XCTAssertFalse(
            app.staticTexts["Fixture Bravo"].exists,
            "A hidden album is still listed in the viewer"
        )
        XCTAssertTrue(app.staticTexts["Fixture Alpha"].exists)
        XCTAssertTrue(app.staticTexts["Fixture Charlie"].exists)
    }

    /// Hiding every album clears the loaded photos and explains the empty screen,
    /// rather than leaving the last album's thumbnails behind.
    func testHidingEveryAlbumClearsTheViewer() throws {
        let app = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 20))

        app.hideEveryAlbum()
        app.finishSetup()

        XCTAssertTrue(
            app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS %@", "No albums to show")
            ).element.waitForExistence(timeout: 10),
            "The empty-state explanation did not appear"
        )
        for spec in PhotoLibraryFixture.specs {
            XCTAssertFalse(
                app.staticTexts[spec.name].exists,
                "\(spec.name) survived hiding every album"
            )
        }
        // Thumbnails carry an accessibility label of "Photo"; the empty state's SF
        // Symbol is also an Image, so counting every image would count that too.
        XCTAssertEqual(
            app.thumbnailCount, 0,
            "Photos are still on screen with no visible album"
        )
    }

    /// An album created after launch is discovered by pull-to-refresh, and — this is
    /// the bug that shipped — can then be hidden like any other. An album with no
    /// stored settings must still get an entry, or its eye does nothing.
    func testAlbumDiscoveredByPullToRefreshCanBeHidden() throws {
        try PhotoLibraryFixture.removeLateAlbum()

        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.staticTexts[PhotoLibraryFixture.lateAlbum.name].exists)

        try PhotoLibraryFixture.seedLateAlbum()
        app.pullToRefreshAlbumList()

        XCTAssertTrue(
            app.staticTexts[PhotoLibraryFixture.lateAlbum.name].waitForExistence(timeout: 15),
            "Pull-to-refresh did not pick up the new album"
        )

        app.openSetupThroughTheParentalGate()
        app.hideAlbum(named: PhotoLibraryFixture.lateAlbum.name)

        // Relaunched rather than tapping Done, so that this test says something about
        // album visibility and nothing about Setup's exit — Done is broken after the
        // gate on iOS 16 at compact width, which `SetupExitUITests` covers on its own.
        // `resetAlbumSettings: false` keeps what was just written.
        app.terminate()
        let viewer = ViewerApp.launch(screen: .viewer, resetAlbumSettings: false)

        XCTAssertTrue(viewer.staticTexts["Albums"].waitForExistence(timeout: 20))
        XCTAssertFalse(
            viewer.staticTexts[PhotoLibraryFixture.lateAlbum.name].exists,
            "A refreshed-in album could not be hidden"
        )
        XCTAssertTrue(
            viewer.staticTexts["Fixture Alpha"].exists,
            "Hiding the new album hid the others too"
        )
    }
}
