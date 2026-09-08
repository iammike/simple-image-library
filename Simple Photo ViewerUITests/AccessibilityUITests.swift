//
//  AccessibilityUITests.swift
//  Simple Photo ViewerUITests
//
//  VoiceOver cannot be run in the simulator, and the app's audience includes people
//  who depend on it, so what VoiceOver needs is asserted from the accessibility tree
//  instead: that the controls exist as controls, carry names, and can be activated.
//

import XCTest

final class AccessibilityUITests: ViewerUITestCase {

    /// An album row used to be static text beside a zero-size overlay button, which
    /// left assistive technology nothing to focus or activate.
    func testAlbumRowIsAButtonNamedAfterItsAlbum() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        let row = app.buttons["Fixture Charlie"]
        XCTAssertTrue(
            row.waitForExistence(timeout: 10),
            "The album row is not exposed as a button carrying the album's name"
        )
        XCTAssertTrue(row.frame.width > 0 && row.frame.height > 0,
                      "The album row has no frame to focus")
    }

    /// Activating that button must open the album, not merely be focusable.
    func testActivatingAnAlbumRowOpensIt() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        app.buttons["Fixture Charlie"].tap()

        XCTAssertTrue(
            app.waitForThumbnails(atLeast: 1, timeout: 15),
            "Activating the album row did not open the album"
        )
    }

    /// The gear is the only route into Setup and VoiceOver cannot perform a long
    /// press, so it needs a name and an action of its own.
    func testGearIsNamedAndActivatable() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        let gear = app.buttons["Open Setup"]
        XCTAssertTrue(gear.waitForExistence(timeout: 10), "The gear has no accessible name")
        XCTAssertTrue(gear.frame.width > 0 && gear.frame.height > 0)
    }
}
