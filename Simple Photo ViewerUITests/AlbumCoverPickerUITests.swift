//
//  AlbumCoverPickerUITests.swift
//  Simple Photo ViewerUITests
//
//  An album's cover used to be whatever photo was newest, so it silently changed
//  identity every time one was added. These cover the caregiver's way to pin it
//  to a specific photo instead.
//

import XCTest

final class AlbumCoverPickerUITests: ViewerUITestCase {

    private func openCoverPicker(forAlbumNamed name: String, in app: XCUIApplication) {
        let row = app.settingsRow(forAlbumNamed: name)
        let cover = row.buttons["Album cover"]
        XCTAssertTrue(cover.waitForExistence(timeout: 10), "No cover button for \(name)")
        cover.tap()
    }

    /// The picker shows one candidate per photo in the album, and picking one closes it.
    func testPickerShowsEveryPhotoAndPickingDismisses() throws {
        let app = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 20))

        openCoverPicker(forAlbumNamed: "Fixture Charlie", in: app)
        XCTAssertTrue(app.navigationBars["Choose Cover"].waitForExistence(timeout: 10))

        let candidates = app.buttons.matching(
            NSPredicate(format: "label == 'Use this photo as the album cover'")
        )
        XCTAssertTrue(
            app.waitFor(timeout: 15) { candidates.count >= 4 },
            "Expected at least the 4 photos Fixture Charlie was seeded with, found \(candidates.count)"
        )

        // The second photo, not the first: picking the newest again would not tell
        // a genuine selection apart from the sheet just closing on a default.
        candidates.element(boundBy: 1).tap()

        XCTAssertTrue(
            app.waitForDisappearance(of: app.navigationBars["Choose Cover"], timeout: 10),
            "Picking a photo did not close the picker"
        )
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 10))
    }

    /// "Use Newest" clears a choice and closes the picker without requiring a tap on
    /// any specific photo.
    func testUseNewestDismissesWithoutChoosingAPhoto() throws {
        let app = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 20))

        openCoverPicker(forAlbumNamed: "Fixture Charlie", in: app)
        XCTAssertTrue(app.navigationBars["Choose Cover"].waitForExistence(timeout: 10))

        app.navigationBars["Choose Cover"].buttons["Use Newest"].tap()

        XCTAssertTrue(
            app.waitForDisappearance(of: app.navigationBars["Choose Cover"], timeout: 10),
            "Use Newest did not close the picker"
        )
    }

    /// Cancel leaves the picker with no change, same as it does everywhere else a
    /// caregiver can back out of something in Setup.
    func testCancelDismissesWithoutChoosingAPhoto() throws {
        let app = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 20))

        openCoverPicker(forAlbumNamed: "Fixture Charlie", in: app)
        XCTAssertTrue(app.navigationBars["Choose Cover"].waitForExistence(timeout: 10))

        app.navigationBars["Choose Cover"].buttons["Cancel"].tap()

        XCTAssertTrue(
            app.waitForDisappearance(of: app.navigationBars["Choose Cover"], timeout: 10),
            "Cancel did not close the picker"
        )
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 10))
    }
}
