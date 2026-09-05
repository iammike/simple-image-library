//
//  XCUIApplication+Viewer.swift
//  Simple Photo ViewerUITests
//
//  The app-specific vocabulary the tests are written in. Keeping the queries here
//  means a SwiftUI change that reshapes the accessibility tree is one edit, not
//  twenty, and the tests read as the QA plan reads.
//

import XCTest

extension XCUIApplication {

    // MARK: - Setup screen

    /// The Setup row for an album, found by the album's own name.
    func settingsRow(forAlbumNamed name: String) -> XCUIElement {
        cells.containing(NSPredicate(format: "label == %@", name)).element
    }

    /// Taps the eye on one album's Setup row.
    func hideAlbum(named name: String) {
        let row = settingsRow(forAlbumNamed: name)
        XCTAssertTrue(row.waitForExistence(timeout: 10), "No Setup row for \(name)")
        if !row.isHittable { row.scrollIntoView(in: self) }
        row.buttons["Hide album"].tap()
    }

    /// Leaves Setup for the viewer.
    ///
    /// Two deliberate details, both learned from failures rather than from the docs:
    ///
    /// The query is scoped to the navigation bar because the parental gate's number pad
    /// carries its own "Done" in a keyboard toolbar, and that button lingers in the
    /// hierarchy after the gate's sheet dismisses.
    ///
    /// The tap is a coordinate tap because when Setup is reached *through* the gate,
    /// something invisible from the dismissed sheet sits over the navigation bar on
    /// iOS 16: XCUITest resolves the button's hit point to {-1, -1}, silently taps
    /// nothing, and reports no error. Taps inside the form work fine, so this is
    /// specific to the bar. A coordinate tap uses the frame directly and goes through.
    func finishSetup(file: StaticString = #filePath, line: UInt = #line) {
        let setupBar = navigationBars["Setup"]
        let done = setupBar.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10), "No Done in Setup", file: file, line: line)

        for attempt in 1...3 {
            done.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if waitForDisappearance(of: setupBar, timeout: 3) { return }
            print("finishSetup: Done tap \(attempt) did not close Setup; retrying")
        }

        XCTFail("Done did not close Setup after three taps", file: file, line: line)
    }

    /// Waits for an element to go away. A push or a dismissal keeps both screens in
    /// the hierarchy while it animates, so "the old screen is gone" is a wait, not a
    /// read — asserting it immediately is a race that fails on a slow machine.
    func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval) -> Bool {
        waitFor(timeout: timeout) { !element.exists }
    }

    /// Hides every album currently listed in Setup, including the smart albums the
    /// simulator's library provides (Recents and friends), so the viewer really has
    /// nothing left to show.
    func hideEveryAlbum() {
        // Each tap flips one row's label from "Hide album" to "Show album", so the
        // query shrinks by one; loop until none are left rather than indexing.
        var guardCount = 0
        while buttons["Hide album"].exists, guardCount < 40 {
            let button = buttons["Hide album"].firstMatch
            if button.isHittable {
                button.tap()
            } else {
                swipeUp()
            }
            guardCount += 1
        }
        XCTAssertLessThan(guardCount, 40, "Never ran out of albums to hide")
    }

    // MARK: - Viewer screen

    /// The gear carries a 3-second `onLongPressGesture`; a tap does nothing. The
    /// VoiceOver escape hatch on it is an `accessibilityAction`, which XCUITest cannot
    /// invoke, so the press is the only way in.
    func openSetupThroughTheParentalGate(
        holdDuration: TimeInterval = 3.5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let gear = navigationBars.buttons["Open Setup"]
        XCTAssertTrue(gear.waitForExistence(timeout: 15), "No gear in the toolbar", file: file, line: line)
        gear.press(forDuration: holdDuration)

        XCTAssertTrue(
            staticTexts["Adult Check"].waitForExistence(timeout: 10),
            "The press-and-hold did not open the parental gate",
            file: file, line: line
        )
        answerParentalGate(file: file, line: line)

        XCTAssertTrue(
            navigationBars["Setup"].waitForExistence(timeout: 15),
            "The gate accepted the answer but Setup did not open",
            file: file, line: line
        )
        // Setup appears the instant `isSetupMode` flips, while the gate's sheet is
        // still dismissing over it. Wait for the sheet to really be gone.
        XCTAssertTrue(
            waitForDisappearance(of: staticTexts["Adult Check"], timeout: 10),
            "The gate sheet never went away",
            file: file, line: line
        )
    }

    /// The gate's sum is randomised, so the answer has to be read off the screen.
    func answerParentalGate(file: StaticString = #filePath, line: UInt = #line) {
        let prompt = staticTexts.matching(
            NSPredicate(format: "label MATCHES %@", #"^\d+ \+ \d+$"#)
        ).element
        XCTAssertTrue(prompt.waitForExistence(timeout: 10), "No arithmetic prompt", file: file, line: line)

        let parts = prompt.label.components(separatedBy: " + ")
        guard parts.count == 2, let a = Int(parts[0]), let b = Int(parts[1]) else {
            XCTFail("Could not read the gate prompt '\(prompt.label)'", file: file, line: line)
            return
        }

        let field = textFields["Answer"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), file: file, line: line)
        field.tap()
        field.typeText("\(a + b)")

        // The number pad has no Return key and covers the buttons on a small phone.
        let keyboardDone = keyboards.buttons["Done"]
        if keyboardDone.exists { keyboardDone.tap() }

        // "Open Setup" also labels the gear behind the sheet; the gate's is the button
        // that is not in a navigation bar.
        let submit = buttons.matching(NSPredicate(format: "label == %@", "Open Setup"))
            .allElementsBoundByIndex
            .first { $0.frame.height > 20 && $0.frame.width > 80 }
        XCTAssertNotNil(submit, "No submit button on the gate", file: file, line: line)
        submit?.tap()
    }

    /// Photo thumbnails carry "Photo", "Live Photo" or "Video, mm:ss" as their label,
    /// which separates them from the SF Symbols the album rows and empty state draw.
    ///
    /// The element type is deliberately unconstrained: `ThumbnailView` puts
    /// `.accessibilityElement(children: .ignore)` on a `Group`, and SwiftUI publishes
    /// that as an `Other` wrapping an unlabelled `Image`, not as an `Image`.
    var thumbnailCount: Int {
        descendants(matching: .any).matching(
            NSPredicate(format: "label == 'Photo' OR label == 'Live Photo' OR label BEGINSWITH 'Video, '")
        ).count
    }

    /// Thumbnails load asynchronously from Photos, so counts need a wait, not a read.
    func waitForThumbnails(atLeast minimum: Int, timeout: TimeInterval) -> Bool {
        waitFor(timeout: timeout) { self.thumbnailCount >= minimum }
    }

    func waitForThumbnails(atMost maximum: Int, timeout: TimeInterval) -> Bool {
        waitFor(timeout: timeout) { self.thumbnailCount <= maximum }
    }

    func waitFor(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if condition() { return true }
            _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.3))
        } while Date() < deadline
        return condition()
    }

    /// Pull-to-refresh on the album list.
    func pullToRefreshAlbumList() {
        let list = collectionViews.element(boundBy: 0)
        let start = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}

extension XCUIElement {
    /// Scrolls a scrollable ancestor until this element can be tapped.
    func scrollIntoView(in app: XCUIApplication, attempts: Int = 8) {
        var remaining = attempts
        while !isHittable, remaining > 0 {
            app.swipeUp()
            remaining -= 1
        }
    }
}
