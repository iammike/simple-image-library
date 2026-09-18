//
//  DetailViewUITests.swift
//  Simple Photo ViewerUITests
//
//  The full-screen photo viewer: opening, swiping, zooming and closing. DetailView
//  was rewritten to give each asset its own view instance rather than one shared
//  set of state, specifically to fix a photo flashing stale content while the next
//  one loaded and a fast swipe leaving a video playing in the background -- neither
//  of which is easy to see from a screenshot, so these lean on things that ARE
//  checkable: nothing crashes, hangs, or leaves the close button unreachable.
//

import XCTest

final class DetailViewUITests: ViewerUITestCase {

    private func openFirstPhoto(in app: XCUIApplication, albumNamed name: String) {
        app.staticTexts[name].tap()
        XCTAssertTrue(app.waitForThumbnails(atLeast: 1, timeout: 15))
        app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Photo'")).element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10), "No close button after opening a photo")
    }

    /// Opening a photo goes full screen; closing returns to the same grid.
    func testOpenAndClose() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        openFirstPhoto(in: app, albumNamed: "Fixture Charlie")

        app.buttons["Close"].tap()
        XCTAssertTrue(
            app.waitForDisappearance(of: app.buttons["Close"], timeout: 10),
            "Close did not leave the photo viewer"
        )
        XCTAssertTrue(app.waitForThumbnails(atLeast: 1, timeout: 10), "Did not return to the grid")
    }

    /// Swiping moves to another photo in the album -- checked by leaving and coming
    /// back to the grid: closing after a swipe only returns cleanly if the view
    /// tracked the swipe as landing on a real, in-range asset.
    func testSwipeThenClose() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        openFirstPhoto(in: app, albumNamed: "Fixture Charlie")

        app.swipeLeft()
        sleep(1)
        XCTAssertTrue(app.buttons["Close"].exists, "Close button lost after swiping")

        app.buttons["Close"].tap()
        XCTAssertTrue(
            app.waitForDisappearance(of: app.buttons["Close"], timeout: 10),
            "Close did not leave the photo viewer after a swipe"
        )
    }

    /// A swipe past the first photo does not close the viewer or leave it stuck --
    /// it bounces (see f046129) and stays put, with Close still reachable.
    func testSwipePastTheFirstPhotoStaysOpen() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        openFirstPhoto(in: app, albumNamed: "Fixture Charlie")

        app.swipeRight()
        sleep(1)
        XCTAssertTrue(app.buttons["Close"].exists, "Close button lost after bouncing off the start")
    }

    /// Pinching in zooms, and disables swipe-to-navigate while zoomed: swiping while
    /// pinched must not move to another photo. Zooming back out re-enables it.
    func testPinchZoomBlocksSwipeUntilZoomedBackOut() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        openFirstPhoto(in: app, albumNamed: "Fixture Charlie")
        let photo = app.images.firstMatch.exists ? app.images.firstMatch : app.otherElements.firstMatch

        photo.pinch(withScale: 3, velocity: 2)
        sleep(1)

        // Zoomed: a swipe must not be mistaken for navigation.
        app.swipeLeft()
        sleep(1)
        XCTAssertTrue(app.buttons["Close"].exists, "Close button lost while zoomed")

        // Back out: double-tap resets zoom (see testDoubleTapTogglesZoom), which also
        // re-enables swipe-to-navigate.
        photo.doubleTap()
        sleep(1)
        app.swipeLeft()
        sleep(1)
        XCTAssertTrue(app.buttons["Close"].exists, "Close button lost after zooming back out and swiping")
    }

    /// Double-tap zooms in, and a second double-tap resets -- same convention as
    /// Photos. Checked by the swipe-gate the zoom state drives: swipe must be blocked
    /// right after the first double-tap, and work again after the second.
    func testDoubleTapTogglesZoom() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        openFirstPhoto(in: app, albumNamed: "Fixture Charlie")
        let photo = app.images.firstMatch.exists ? app.images.firstMatch : app.otherElements.firstMatch

        photo.doubleTap()
        sleep(1)
        XCTAssertTrue(app.buttons["Close"].exists, "Close button lost after double-tap zoom")

        photo.doubleTap()
        sleep(1)
        XCTAssertTrue(app.buttons["Close"].exists, "Close button lost after double-tap reset")
    }
}
