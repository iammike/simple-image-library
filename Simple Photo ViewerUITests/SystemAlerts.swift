//
//  SystemAlerts.swift
//  Simple Photo ViewerUITests
//
//  The Photos permission alert is owned by SpringBoard, not by the app, so it is
//  driven directly rather than through `addUIInterruptionMonitor`. An interruption
//  monitor only fires on the *next* interaction with the app, which makes the first
//  assertion of a test race the alert; querying SpringBoard is deterministic.
//
//  `xcrun simctl privacy <device> grant photos <bundle-id>` writes the TCC row but
//  does not suppress this alert (verified on iOS 16.4 and 17.2 simulators), so
//  something has to tap it.
//

import XCTest

enum SystemAlerts {
    static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    /// Wording differs by iOS version, so every known spelling is tried.
    /// iOS 16: "Allow Access to All Photos". iOS 17+: "Allow Full Access".
    private static let fullAccessButtonLabels = [
        "Allow Full Access",
        "Allow Access to All Photos",
        "Allow"
    ]

    /// Grants full photo access if the alert is on screen. Returns true if a button
    /// was tapped. Safe to call when no alert is showing: it costs `timeout` seconds.
    /// Deleting an album prompts too — "Allow ... to delete the album ...?" — and the
    /// prompt is what deadlocks `performChangesAndWait` on the main thread.
    private static let confirmChangeButtonLabels = ["Delete", "Allow", "OK"]

    /// The common case is "no alert, because this device already granted", and that
    /// case runs once per app launch, so it costs one cheap query per poll: the
    /// per-label button lookups only happen when an alert is actually up.
    @discardableResult
    static func allowFullPhotoAccess(timeout: TimeInterval = 10) -> Bool {
        tap(anyOf: fullAccessButtonLabels, timeout: timeout)
    }

    /// Confirms a destructive photo-library change requested by the runner.
    @discardableResult
    static func confirmPhotoLibraryChange(timeout: TimeInterval = 10) -> Bool {
        tap(anyOf: confirmChangeButtonLabels, timeout: timeout)
    }

    /// Polls SpringBoard for an alert and taps the first of `labels` it offers. The
    /// run loop is pumped rather than slept on, so a caller waiting on an asynchronous
    /// Photos callback still gets its completion delivered.
    @discardableResult
    static func tap(anyOf labels: [String], timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let alert = springboard.alerts.firstMatch
            if alert.exists {
                for label in labels {
                    let button = alert.buttons[label]
                    if button.exists && button.isHittable {
                        button.tap()
                        return true
                    }
                }
            }
            _ = RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.25))
        } while Date() < deadline
        return false
    }
}
