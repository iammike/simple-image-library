//
//  VideoDetailContentView.swift
//  Simple Photo Viewer
//
//  A single full-screen video: loads, plays once ready, and loops. One instance
//  exists per video shown -- DetailView keys it by the asset's identifier -- so a
//  video superseded by a fast swipe pauses and releases its own player in
//  `onDisappear` rather than one swipe's player surviving to play in the background
//  under whatever is swiped to next.
//
//  No zoom here: AVKit's own player brings its own pinch-to-zoom, which this view has
//  no way to see or coordinate a swipe gesture against (see #64) -- so unlike
//  the photo and Live Photo views, swiping is never disabled while a video is open.
//

import SwiftUI
import Photos
import AVKit

struct VideoDetailContentView: View {
    @ObservedObject var viewModel: ViewModel
    let asset: PHAsset

    @State private var player: AVPlayer?
    @State private var statusObserver: NSKeyValueObservation?
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                DetailLoadingView()
            }
        }
        .task(id: asset.localIdentifier) {
            guard let playerItem = await viewModel.videoPlayerItem(for: asset), !Task.isCancelled else {
                return
            }
            setUpPlayer(with: playerItem)
        }
        .onDisappear {
            tearDownPlayer()
        }
    }

    private func setUpPlayer(with playerItem: AVPlayerItem) {
        statusObserver = playerItem.observe(\.status, options: [.new]) { item, _ in
            guard item.status == .readyToPlay else { return }
            DispatchQueue.main.async {
                player?.play()
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
        }
        player = AVPlayer(playerItem: playerItem)
    }

    private func tearDownPlayer() {
        player?.pause()
        player = nil
        statusObserver?.invalidate()
        statusObserver = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }
}
