//
//  AudioSession.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import AVFoundation

func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.playback)
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        print("Failed to set audio session category. Error: \(error)")
    }
}

