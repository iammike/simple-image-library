//
//  SpeechManager.swift
//  Simple Photo Viewer
//
//  Thin wrapper around AVSpeechSynthesizer for the tap-to-hear feature.
//  Reads the `readAloudOnTap` preference and the system VoiceOver state, so
//  callers can simply call `speak(_:)`. The speak/skip decision lives in the
//  testable `ReadAloud.shouldSpeak`.
//

import AVFoundation
import UIKit

final class SpeechManager {
    static let shared = SpeechManager()

    /// UserDefaults key backing the "Read names aloud on tap" Settings toggle.
    static let preferenceKey = "readAloudOnTap"

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// Speaks the given text aloud when read-aloud is enabled and VoiceOver isn't running.
    func speak(_ text: String) {
        let enabled = UserDefaults.standard.bool(forKey: Self.preferenceKey)
        guard ReadAloud.shouldSpeak(enabled: enabled, voiceOverRunning: UIAccessibility.isVoiceOverRunning),
              !text.isEmpty else {
            return
        }
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(AVSpeechUtterance(string: text))
    }
}
