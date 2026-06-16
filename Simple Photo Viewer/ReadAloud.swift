//
//  ReadAloud.swift
//  Simple Photo Viewer
//
//  Pure helpers for the tap-to-hear (read-aloud) accessibility feature.
//  Kept free of AVSpeechSynthesizer/UIKit so the decision logic is testable.
//

import Foundation

enum ReadAloud {
    /// Whether speech should occur: only when the feature is enabled and the
    /// system VoiceOver screen reader is not already running (avoids double-speaking).
    static func shouldSpeak(enabled: Bool, voiceOverRunning: Bool) -> Bool {
        enabled && !voiceOverRunning
    }

    /// A friendly, spoken-style date string (e.g. "March 5, 2024"), or `nil` when there is no date.
    static func spokenDateString(for date: Date?, locale: Locale = .current) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
