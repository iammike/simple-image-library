//
//  AppStoreScreenshots.swift
//  Simple Photo ViewerUITests
//
//  Walks the app through the scenes the App Store listing shows and attaches a
//  full-resolution capture of each. Not a test of anything: it runs only when
//  SCREENSHOTS=1 is in the environment, against a simulator's own sample photo
//  library rather than the seeded fixture, whose swatches are not listing material.
//
//  Export the captures with
//    xcrun xcresulttool export attachments --path <result bundle> --output-path <dir>
//

import XCTest

final class AppStoreScreenshots: XCTestCase {

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SCREENSHOTS"] == "1",
            "Set SCREENSHOTS=1 to capture App Store screenshots"
        )
        continueAfterFailure = false
    }

    private func capture(_ name: String) {
        // Let any transition and image load settle before the frame is taken.
        sleep(2)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testCaptureListingScenes() throws {
        XCUIDevice.shared.orientation = isPad ? .landscapeLeft : .portrait

        // No launch arguments: a fresh install starts in onboarding and then Setup on
        // its own, and an argument for either flag would shadow the app's own write
        // when the button flips it. Uninstall the app before running.
        let app = XCUIApplication()
        // Album colours, as an `albumSettings` JSON blob in old-style plist data form
        // (`<hex>`), so the Setup scene shows coloured albums without tapping: a tap
        // on a row's swatch synthesized by XCUITest lands on the eye instead.
        if let hex = ProcessInfo.processInfo.environment["ALBUM_SETTINGS_HEX"], !hex.isEmpty {
            app.launchArguments += ["-albumSettings", "<\(hex)>"]
        }
        app.launch()
        SystemAlerts.allowFullPhotoAccess(timeout: 30)

        // 1. Welcome.
        XCTAssertTrue(app.staticTexts["Welcome to LE Viewer"].waitForExistence(timeout: 20))
        capture("01-welcome")

        // 2. The Guided Access page, which is the last one.
        let getStarted = app.buttons["Get Started"]
        var pages = 0
        while !getStarted.exists, pages < 5 {
            app.buttons["Next"].tap()
            pages += 1
            sleep(1)
        }
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        capture("02-guided-access")

        // 3. Setup, with the albums coloured the way the caregiver would.
        getStarted.tap()
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Album color"].firstMatch.waitForExistence(timeout: 10))
        capture("03-setup")

        // 4. The viewer.
        let start = app.buttons["Start Using LE Viewer"]
        if !start.isHittable { app.swipeUp() }
        start.tap()
        XCTAssertTrue(app.staticTexts["Albums"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Recents"].waitForExistence(timeout: 10))
        capture(isPad ? "04-browsing" : "04-albums")

        if !isPad {
            app.staticTexts["Recents"].tap()
        }
        let photos = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Photo'"))
        XCTAssertTrue(photos.firstMatch.waitForExistence(timeout: 15))
        if !isPad {
            capture("05-photos")
        }

        // 5. A photo, full screen. The second sample is the tall waterfall.
        let index = min(1, photos.count - 1)
        photos.element(boundBy: index).tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 10))
        capture(isPad ? "05-photo-detail" : "06-photo-detail")
    }
}
