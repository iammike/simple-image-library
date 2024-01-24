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
    let asset: PHAsset
    @Binding var isPresented: Bool
    @State private var image: UIImage? = nil
    @State private var player: AVPlayer? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if asset.mediaType == .video {
                    videoPlayerView
                } else {
                    imageView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            closeButton
        }
        .onAppear {
            loadAsset()
        }
    }

    private var closeButton: some View {
        Button(action: {
            self.isPresented = false
        }) {
            Image(systemName: "xmark")
                .foregroundColor(.primary)
                .padding()
                .background(Color.gray.opacity(0.7))
                .clipShape(Circle())
        }
        .padding([.top, .trailing], asset.mediaType == .video ? 50 : 20) // video player has a sound control in top right
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
}
