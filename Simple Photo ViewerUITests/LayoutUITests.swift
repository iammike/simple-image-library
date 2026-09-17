//
//  LayoutUITests.swift
//  Simple Photo ViewerUITests
//
//  The two shapes the app takes: a push/pop stack at compact width, a split view at
//  regular width. Each test skips on the idiom it does not describe, so the same suite
//  runs on both destinations and reports honestly on each.
//

import UIKit
import XCTest

final class LayoutUITests: ViewerUITestCase {

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    /// iPhone: tapping an album pushes the grid, and Back returns to the album list.
    /// Launch-time selection must not push, or the child never sees the album list.
    func testPhonePushesTheGridAndComesBack() throws {
        try XCTSkipIf(isPad, "Compact-width behaviour")

        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        XCTAssertEqual(
            app.thumbnailCount, 0,
            "The grid was pushed at launch; only an explicit tap should push"
        )

        app.staticTexts["Fixture Charlie"].tap()

        XCTAssertTrue(
            app.waitForThumbnails(atLeast: 1, timeout: 15),
            "Tapping an album did not push the photo grid"
        )
        XCTAssertTrue(
            app.waitForDisappearance(of: app.staticTexts["Albums"], timeout: 5),
            "The album list is still on screen"
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            app.staticTexts["Albums"].waitForExistence(timeout: 10),
            "Back did not return to the album list"
        )
    }

    /// iPad: the album list and the photo grid are on screen at the same time, and
    /// stay that way after tapping an album.
    func testPadKeepsBothColumns() throws {
        try XCTSkipUnless(isPad, "Regular-width behaviour")

        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        // The first visible album is selected at launch, so the second column already
        // holds its photos while the list is still on screen.
        XCTAssertTrue(app.waitForThumbnails(atLeast: 1, timeout: 20))
        XCTAssertTrue(app.staticTexts["Albums"].exists, "The album list vanished")

        app.staticTexts["Fixture Charlie"].tap()
        XCTAssertTrue(app.waitForThumbnails(atLeast: 1, timeout: 15))
        XCTAssertTrue(
            app.staticTexts["Albums"].exists,
            "Tapping an album collapsed the split view"
        )
    }

    /// iPad, portrait: iPadOS collapses the first column of a `NavigationView`, so the
    /// album list — and with it the gear — is off screen until the sidebar is opened.
    /// Pinned because it is the reason Setup was moved out of the album list, and the
    /// reason every other iPad test here runs in landscape.
    func testPadPortraitHidesTheAlbumColumnUntilTheSidebarIsOpened() throws {
        try XCTSkipUnless(isPad, "Regular-width behaviour")

        let app = ViewerApp.launch(screen: .viewer, orientation: .portrait)
        XCTAssertTrue(app.waitForThumbnails(atLeast: 1, timeout: 20))
        XCTAssertFalse(
            app.staticTexts["Albums"].exists,
            "The album column is on screen in portrait; the landscape workaround is stale"
        )

        // The sidebar toggle is the only way back to the list, and so the only way to
        // the gear.
        let toggle = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 10))
    }

    /// iPad: hiding everything must empty the photo column too, not just the list.
    /// This is the half of the empty-state promise a phone cannot show.
    func testPadClearsThePhotoColumnWhenEverythingIsHidden() throws {
        try XCTSkipUnless(isPad, "The photo column only exists at regular width")

        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.waitForThumbnails(atLeast: 1, timeout: 20))

        app.openSetupThroughTheParentalGate()
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 10))
        app.hideEveryAlbum()
        app.finishSetup()

        XCTAssertTrue(app.waitForThumbnails(atMost: 0, timeout: 10), "Hidden photos are still on screen")
    }
}
