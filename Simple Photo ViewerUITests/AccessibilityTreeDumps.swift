//
//  AccessibilityTreeDumps.swift
//  Simple Photo ViewerUITests
//
//  Diagnostics, not assertions. SwiftUI decides what element type each view becomes,
//  and guessing costs more than looking: the photo thumbnails, for instance, publish
//  as `Other` wrapping an unlabelled `Image`, which no amount of reading the source
//  would have told you.
//
//  Skipped unless DUMP_TREES=1 is in the test action's environment, so they cost
//  nothing on a normal run.
//

import XCTest

final class AccessibilityTreeDumps: ViewerUITestCase {

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["DUMP_TREES"] == "1",
            "Set DUMP_TREES=1 to dump accessibility trees"
        )
        try super.setUpWithError()
    }

    private func dump(_ app: XCUIApplication, named name: String) {
        let text = app.debugDescription
        let attachment = XCTAttachment(string: text)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        print("=== \(name) ===\n\(text)\n=== END \(name) ===")
    }

    func testDumpSetupScreen() {
        let app = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 20))
        dump(app, named: "setup")
    }

    func testDumpAlbumList() {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))
        dump(app, named: "album-list")
    }

    func testDumpPhotoGrid() {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))
        app.staticTexts["Fixture Charlie"].tap()
        _ = app.waitForThumbnails(atLeast: 1, timeout: 15)
        dump(app, named: "photo-grid")
    }
}
