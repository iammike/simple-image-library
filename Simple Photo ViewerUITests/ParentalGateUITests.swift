//
//  ParentalGateUITests.swift
//  Simple Photo ViewerUITests
//
//  The gate is the only way into Setup on a real device, so it is worth one test that
//  drives it exactly as an adult would: a three-second hold, then an arithmetic answer
//  read off the screen.
//

import XCTest

final class ParentalGateUITests: ViewerUITestCase {

    func testPressAndHoldThenCorrectAnswerOpensSetup() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        app.openSetupThroughTheParentalGate()

        XCTAssertTrue(
            app.navigationBars["Setup"].waitForExistence(timeout: 10),
            "The gate did not open Setup"
        )
    }

    /// A short tap must not open the gate, or the gear is not child-proof at all.
    func testShortTapDoesNotOpenTheGate() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        app.navigationBars.buttons["Open Setup"].tap()

        XCTAssertFalse(
            app.staticTexts["Adult Check"].waitForExistence(timeout: 3),
            "A tap opened the parental gate"
        )
    }

    /// A wrong answer keeps the gate shut and re-rolls the challenge.
    func testWrongAnswerDoesNotOpenSetup() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        app.navigationBars.buttons["Open Setup"].press(forDuration: 3.5)
        XCTAssertTrue(app.staticTexts["Adult Check"].waitForExistence(timeout: 10))

        // 99 cannot be the sum of two single digits.
        let field = app.textFields["Answer"]
        field.tap()
        field.typeText("99")
        let keyboardDone = app.keyboards.buttons["Done"]
        if keyboardDone.exists { keyboardDone.tap() }
        app.buttons.matching(NSPredicate(format: "label == %@", "Open Setup"))
            .allElementsBoundByIndex
            .first { $0.frame.height > 20 && $0.frame.width > 80 }?
            .tap()

        XCTAssertTrue(app.staticTexts["Try again"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Setup"].exists)
    }
}
