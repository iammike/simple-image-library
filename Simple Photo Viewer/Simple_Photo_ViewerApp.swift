//
//  Simple_Photo_ViewerApp.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import AVFoundation

@main
struct Simple_Photo_ViewerApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
    }
}
