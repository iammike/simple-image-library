//
//  SetupExitUITests.swift
//  Simple Photo ViewerUITests
//
//  Getting *out* of Setup, which matters as much as getting in: an adult who cannot
//  leave Setup cannot hand the device back to the child.
//
//  `testDoneLeavesSetupAfterTheParentalGate` FAILS TODAY on a compact-width device
//  running iOS 16, and the failure is the app's, not the test's. Measured across four
//  simulators:
//
//      iPhone 14, iOS 16.4      Done is dead after the gate
//      iPhone 15, iOS 17.2      passes
//      iPad mini 6, iOS 16.4    passes
//      iPad mini 6, iOS 17.2    passes
//
//  Opening Setup directly (the `-isSetupMode YES` launch argument) leaves Done working
//  on every one of them, so the trigger is the transition: on iOS 16 at compact width,
//  swapping `MainUI`'s `NavigationStack(AlbumView)` for `SetupView`'s own
//  `NavigationStack` while the gate's sheet is dismissing leaves the old navigation bar
//  drawn on screen and lays the new one out roughly 30pt lower. The accessibility
//  snapshot shows it: the bar reports {0, 47, 390, 44} while its own Done button
//  reports {313.7, 97.5, 45.6, 26} — below the bar it belongs to. Tapping either the
//  reported frame or the drawn position does nothing, three times over.
//
//  The deployment target is iOS 16.0, so this ships. Force-quitting and reopening
//  recovers, because Setup then renders without the swap.
//

import UIKit
import XCTest

final class SetupExitUITests: ViewerUITestCase {

    /// Done closes Setup when Setup was opened directly. The control for the test below.
    func testDoneLeavesSetupOpenedDirectly() throws {
        let app = ViewerApp.launch(screen: .setup)
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 20))

        app.finishSetup()
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 10))
    }

    /// Done closes Setup when Setup was reached through the gear and the parental gate,
    /// which is the only route a real adult has. See the note at the top of this file:
    /// this fails on iPhone + iOS 16.
    func testDoneLeavesSetupAfterTheParentalGate() throws {
        let app = ViewerApp.launch(screen: .viewer)
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 20))

        app.openSetupThroughTheParentalGate()
        app.finishSetup()

        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 10))
    }
}
