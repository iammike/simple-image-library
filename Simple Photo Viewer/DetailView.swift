//
//  DetailView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import Photos
import AVKit

struct DetailView: View {
    @ObservedObject var viewModel: ViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var isPresented: Bool
    @State private var image: UIImage? = nil
    @State private var player: AVPlayer? = nil
    @State private var showCloseButton = false
    @State private var hideTimerWorkItem: DispatchWorkItem?

    let asset: PHAsset

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
            if showCloseButton {
                closeButton
                    .transition(AnyTransition.opacity.combined(with: .scale))
            }
        }
        .onTapGesture {
            withAnimation {
                showCloseButton.toggle()
            }
            if showCloseButton {
                startHideTimer()
            } else {
                cancelHideTimer()
            }
        }
        .onAppear {
            loadAsset()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColorForScheme.opacity(viewModel.useOpacity ? 0.7 : 1.0))
        .edgesIgnoringSafeArea(.all)
    }

    private var content: some View {
        Group {
            if asset.mediaType == .video {
                videoPlayerView
            } else {
                imageView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var closeButton: some View {
        Button(action: {
            if let player = player, asset.mediaType == .video {
                player.pause()
            }
            self.isPresented = false
        }) {
            Image(systemName: "xmark")
                .foregroundColor(.black)
                .padding()
                .background(Color.white)
                .clipShape(Circle())
        }
        .padding(.top, asset.mediaType == .video ? 70 : 40) // Account for volume button in video player
        .padding(.trailing, 20)
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Spacer()
        }
    }

    private var videoPlayerView: some View  {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                loadingView
            }
        }
    }

    private var imageView: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                loadingView
            }
        }
    }

    private func loadAsset() {
        if asset.mediaType == .video {
            loadVideo()
        } else {
            loadImage()
        }
    }

    private func loadImage() {
        viewModel.getImage(for: asset) { downloadedImage in
            self.image = downloadedImage
        }
    }

    private func loadVideo() {
        let options = PHVideoRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true

        DispatchQueue.global(qos: .userInitiated).async {
            PHImageManager.default().requestAVAsset(forVideo: self.asset, options: options) { (avAsset, audioMix, info) in
                DispatchQueue.main.async {
                    if let avAsset = avAsset as? AVURLAsset {
                        self.player = AVPlayer(url: avAsset.url)
                    }
                }
            }
        }
    }

    private var backgroundColorForScheme: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    private func startHideTimer() {
        cancelHideTimer()

        let workItem = DispatchWorkItem {
            withAnimation {
                self.showCloseButton = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        hideTimerWorkItem = workItem
    }

    private func cancelHideTimer() {
        hideTimerWorkItem?.cancel()
        hideTimerWorkItem = nil
    }
}
