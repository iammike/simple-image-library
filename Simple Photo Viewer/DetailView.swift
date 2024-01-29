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
    @State private var hideTimerWorkItem: DispatchWorkItem?
    @State private var currentIndex: Int = 0
    @State private var swipeDirection: SwipeDirection = .right // need to set an initial direction for the first asset loaded to work
    @State private var playerItemStatusObserver: Any?

    enum SwipeDirection {
        case left, right, none
    }

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
                .gesture(swipeGesture)
                .edgesIgnoringSafeArea(.all)

            content
                .gesture(swipeGesture)

            closeButton
        }
        .onAppear {
            loadAsset()
        }
        .onDisappear {
            playerItemStatusObserver = nil
            player?.pause()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
    }

    private var content: some View {
        GeometryReader { geometry in
            ZStack {
                if currentAsset.mediaType == .video {
                    videoPlayerView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(currentIndex)
                        .transition(contentTransition)
                } else {
                    imageView
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(currentIndex)
                        .transition(contentTransition)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var contentTransition: AnyTransition {
        switch swipeDirection {
        case .left:
            return AnyTransition.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .right:
            return AnyTransition.asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        default:
            return .identity
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
                .background(Color.gray.opacity(0.7))
                .clipShape(Circle())
        }
        .padding(.top, 70)
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

    private var videoPlayerView: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
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
            player = nil
        }
    }

    private func loadImage() {
        viewModel.getImage(for: currentAsset) { downloadedImage in
            self.image = downloadedImage
        }
    }

    private func loadVideo() {
        viewModel.getVideo(for: currentAsset) { playerItem in
            guard let playerItem = playerItem else {
                // Handle error if needed
                return
            }
            setupPlayer(with: playerItem)
        }
    }

    private func setupPlayer(with playerItem: AVPlayerItem) {
        playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .old]) { item, _ in
            if item.status == .readyToPlay {
                DispatchQueue.main.async {
                    self.player?.play()
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            self.player?.seek(to: CMTime.zero)
        }

        self.player = AVPlayer(playerItem: playerItem)
    }

    private var backgroundColorForScheme: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                if gesture.translation.width > 100 {
                    if currentIndex > 0 { // Check if not at the first item
                        self.player?.pause()
                        swipeDirection = .right
                        withAnimation {
                            currentIndex = max(currentIndex - 1, 0)
                        }
                        loadAsset()
                    }
                } else if gesture.translation.width < -100 {
                    if currentIndex < viewModel.images.count - 1 { // Check if not at the last item
                        self.player?.pause()
                        swipeDirection = .left
                        withAnimation {
                            currentIndex = min(currentIndex + 1, viewModel.images.count - 1)
                        }
                        loadAsset()
                    }
                }
            }
    }
}
