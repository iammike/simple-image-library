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
    @State private var currentIndex: Int = 0

    var currentAsset: PHAsset {
        viewModel.images[currentIndex]
    }

    init(viewModel: ViewModel, isPresented: Binding<Bool>, asset: PHAsset) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: viewModel.images.firstIndex(where: { $0 == asset }) ?? 0)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .foregroundColor(backgroundColorForScheme.opacity(viewModel.useOpacity ? 0.7 : 1.0))
                .onTapGesture {
                    handleTapGesture()
                }
                .gesture(swipeGesture)
                .edgesIgnoringSafeArea(.all)

            content
                .onTapGesture {
                    handleTapGesture()
                }
                .gesture(swipeGesture)

            if showCloseButton {
                closeButton
                    .transition(AnyTransition.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            loadAsset()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    private var content: some View {
        return ZStack {
            if currentAsset.mediaType == .video {
                AnyView(videoPlayerView)
                    .transition(.slide)
            } else {
                AnyView(imageView)
                    .transition(.slide)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleTapGesture() {
        withAnimation {
            showCloseButton.toggle()
        }
        if showCloseButton {
            startHideTimer()
        } else {
            cancelHideTimer()
        }
    }

    private var closeButton: some View {
        Button(action: {
            if let player = player, currentAsset.mediaType == .video {
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
        .padding(.top, currentAsset.mediaType == .video ? 70 : 40)
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
        if currentAsset.mediaType == .video {
            loadVideo()
        } else {
            loadImage()
        }
    }

    private func loadImage() {
        viewModel.getImage(for: currentAsset) { downloadedImage in
            self.image = downloadedImage
        }
    }

    private func loadVideo() {
        let options = PHVideoRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true

        DispatchQueue.global(qos: .userInitiated).async {
            PHImageManager.default().requestAVAsset(forVideo: self.currentAsset, options: options) { (avAsset, audioMix, info) in
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

    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                if gesture.translation.width > 100 {
                    // Swipe right, go to the previous asset
                    currentIndex = max(currentIndex - 1, 0)
                    loadAsset()
                } else if gesture.translation.width < -100 {
                    // Swipe left, go to the next asset
                    currentIndex = min(currentIndex + 1, viewModel.images.count - 1)
                    loadAsset()
                }
            }
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
