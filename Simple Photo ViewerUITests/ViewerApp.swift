//
//  ViewerApp.swift
//  Simple Photo ViewerUITests
//
//  Launching the app under test in a known state.
//
//  The app persists everything a test cares about in `UserDefaults.standard`, so the
//  launch-argument domain is enough to override it without the app gaining any
//  test-only code: `NSUserDefaults` reads the argument domain ahead of the persisted
//  domain, and nothing written there survives the process.
//
//  `albumSettings` is stored as JSON `Data`. An argument value written as an
//  old-style property-list data literal (`<7b7d>` is the two bytes `{}`) comes back
//  from `data(forKey:)`, which decodes to "no album has settings" — i.e. every album
//  visible. That is the only reset a test needs.
//

import UIKit
import XCTest

enum ViewerApp {

    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    /// On iPad the album list is the first column of a `NavigationView`, and iPadOS
    /// hides that column in portrait — so a portrait iPad shows no album list, no
    /// album names and no gear. Every test that drives the list therefore runs in
    /// landscape, which is also how the app is used on a stand. A test that cares
    /// about portrait must say so.
    static var defaultOrientation: UIDeviceOrientation {
        isPad ? .landscapeLeft : .portrait
    }

    /// `{}` as an old-style plist data literal: an empty albumSettings dictionary.
    static let emptyAlbumSettingsLiteral = "<7b7d>"

    enum StartScreen {
        /// The album list a child sees.
        case viewer
        /// The caregiver's Setup screen, skipping the parental gate.
        case setup
    }

    /// - Parameters:
    ///   - screen: which side of `isSetupMode` to start on.
    ///   - resetAlbumSettings: clear every album's stored visibility and color.
    ///   - orientation: defaults to landscape on iPad so the album column is on screen.
    ///   - extraDefaults: further `-key value` pairs for the argument domain.
    static func launch(
        screen: StartScreen = .viewer,
        resetAlbumSettings: Bool = true,
        orientation: UIDeviceOrientation? = nil,
        extraDefaults: [String] = []
    ) -> XCUIApplication {
        XCUIDevice.shared.orientation = orientation ?? defaultOrientation

        let app = XCUIApplication()
        app.launchArguments += [
            // Skip the onboarding pages; they are covered by their own test.
            "-isFirstLaunch", "NO",
            "-isSetupMode", screen == .setup ? "YES" : "NO"
        ]
        if resetAlbumSettings {
            app.launchArguments += ["-albumSettings", emptyAlbumSettingsLiteral]
        }
        app.launchArguments += extraDefaults
        app.launch()
        answerFirstLaunchPhotoPrompt()
        return app
    }

    /// The app's Photos prompt appears at most once per device, so only the first
    /// launch of the test run waits properly for it. Every later launch does one cheap
    /// check, which is worth roughly half a minute across a full suite.
    private static var hasSeenFirstLaunch = false

    private static func answerFirstLaunchPhotoPrompt() {
        SystemAlerts.allowFullPhotoAccess(timeout: hasSeenFirstLaunch ? 0.5 : 8)
        hasSeenFirstLaunch = true
    }
}
