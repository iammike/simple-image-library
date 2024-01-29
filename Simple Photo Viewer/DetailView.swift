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
    @State private var swipeDirection: SwipeDirection = .right // need to set an initial direction for the first asset loaded to work
    @State private var playerItemStatusObserver: Any?
    @State private var isAssetLoading: Bool = false
    @State private var currentScale: CGFloat = 1.0
    @State private var baseScale: CGFloat = 1.0
    @State private var currentIndex: Int = 0 {
        didSet {
            resetZoom()
        }
    }

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
            stopAndReleasePlayer()
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
            stopAndReleasePlayer()
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
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
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
                    .scaleEffect(currentScale)
                    .gesture(magnificationGesture)
            } else {
                loadingView
            }
        }
    }

    private func resetZoom() {
        currentScale = 1.0
        baseScale = 1.0
    }

    private func loadAsset() {
        resetZoom()
        viewModel.cancelVideoLoading()

        if currentAsset.mediaType == .video {
            loadVideo()
        } else {
            loadImage()
            player = nil
        }
    }

    private func loadImage() {
        isAssetLoading = true
        viewModel.getImage(for: currentAsset) { downloadedImage in
            DispatchQueue.main.async {
                self.image = downloadedImage
                self.isAssetLoading = false
            }
        }
    }

    private func loadVideo() {
        isAssetLoading = true
        viewModel.getVideo(for: currentAsset) { playerItem in
            guard let playerItem = playerItem else {
                DispatchQueue.main.async {
                    self.isAssetLoading = false
                }
                return
            }
            self.setupPlayer(with: playerItem)
        }
    }

    private func setupPlayer(with playerItem: AVPlayerItem) {
        playerItemStatusObserver = playerItem.observe(\.status, options: [.new, .old]) { item, _ in
            if item.status == .readyToPlay {
                DispatchQueue.main.async {
                    self.player?.play()
                    self.isAssetLoading = false
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

    private func stopAndReleasePlayer() {
        DispatchQueue.main.async {
            self.player?.pause()
            self.player = nil
            self.playerItemStatusObserver = nil
            self.isAssetLoading = false
        }
    }

    private var backgroundColorForScheme: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = value * baseScale
                let minScale: CGFloat = 1.0

                if newScale >= minScale {
                    self.currentScale = newScale
                }
            }
            .onEnded { value in
                self.baseScale = currentScale
            }
    }



    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                guard !isAssetLoading else { return }
                if gesture.translation.width > 100 {
                    if currentIndex > 0 { // first item?
                        stopAndReleasePlayer()
                        viewModel.cancelVideoLoading()
                        swipeDirection = .right
                        withAnimation {
                            currentIndex = max(currentIndex - 1, 0)
                        }
                        loadAsset()
                    }
                } else if gesture.translation.width < -100 {
                    if currentIndex < viewModel.images.count - 1 { // last item?
                        stopAndReleasePlayer()
                        viewModel.cancelVideoLoading()
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
