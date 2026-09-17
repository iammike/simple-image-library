//
//  ViewerUITestCase.swift
//  Simple Photo ViewerUITests
//
//  Shared setup, and a screenshot plus an accessibility-tree dump attached to any
//  failure. A UI test that fails on someone else's machine with only "XCTAssertTrue
//  failed" costs an hour; the same failure with a screenshot costs a minute.
//

import XCTest

class ViewerUITestCase: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try PhotoLibraryFixture.seed()
    }

    override func tearDown() {
        super.tearDown()
        guard !testRun!.hasSucceeded else { return }

        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "failure-screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let tree = XCTAttachment(string: XCUIApplication().debugDescription)
        tree.name = "failure-accessibility-tree"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
