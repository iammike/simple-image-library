//
//  VideoPlayerView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    let asset: PHAsset

    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            if player != nil {
                VideoPlayer(player: player)
                    .onAppear() {
                        player?.play()
                    }
                    .onDisappear() {
                        player?.pause()
                    }
            } else {
                Text("Loading...")
                    .onAppear {
                        loadVideo()
                    }
            }
        }
    }

    private func loadVideo() {
        let options = PHVideoRequestOptions()
        options.version = .original
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { (playerItem, _) in
            DispatchQueue.main.async {
                if let playerItem = playerItem {
                    self.player = AVPlayer(playerItem: playerItem)
                }
            }
        }
    }
}

