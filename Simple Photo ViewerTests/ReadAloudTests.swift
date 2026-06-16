//
//  ReadAloudTests.swift
//  Simple Photo ViewerTests
//

import XCTest
@testable import Simple_Photo_Viewer

final class ReadAloudTests: XCTestCase {
    func testShouldSpeakWhenEnabledAndVoiceOverOff() {
        XCTAssertTrue(ReadAloud.shouldSpeak(enabled: true, voiceOverRunning: false))
    }

    func testShouldNotSpeakWhenDisabled() {
        XCTAssertFalse(ReadAloud.shouldSpeak(enabled: false, voiceOverRunning: false))
    }

    func testShouldNotSpeakWhenVoiceOverRunning() {
        // Avoid double-speaking over the system screen reader.
        XCTAssertFalse(ReadAloud.shouldSpeak(enabled: true, voiceOverRunning: true))
    }

    func testSpokenDateStringIsNilForNoDate() {
        XCTAssertNil(ReadAloud.spokenDateString(for: nil))
    }

    func testSpokenDateStringUsesLongStyle() {
        var components = DateComponents()
        components.year = 2024
        components.month = 3
        components.day = 5
        components.hour = 12
        let date = Calendar.current.date(from: components)!

        XCTAssertEqual(
            ReadAloud.spokenDateString(for: date, locale: Locale(identifier: "en_US")),
            "March 5, 2024"
        )
    }
}
