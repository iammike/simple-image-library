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

    @State private var currentIndex: Int = 0
    @State private var image: UIImage? = nil
    @State private var player: AVPlayer? = nil
    @State private var playerItemStatusObserver: Any?
    @State private var isAssetLoading: Bool = false

    @State private var isZoomed: Bool = false
    @State private var offset = CGSize.zero
    @State private var scale: CGFloat = 1
    @GestureState private var scaleState: CGFloat = 1.0
    @GestureState private var offsetState = CGSize.zero

    @State private var swipeDirection: SwipeDirection = .right // need to set an initial direction for the first asset loaded to work

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
                .foregroundColor(Color.black.opacity(viewModel.useOpacity ? 0.7 : 1.0))
                .highPriorityGesture(
                    isZoomed ? nil : swipeGesture
                )
                .edgesIgnoringSafeArea(.all)

            content
                .highPriorityGesture(
                    isZoomed ? nil : swipeGesture
                )

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
                    .scaleEffect(self.scale * scaleState)
                    .offset(x: offset.width + offsetState.width, y: offset.height + offsetState.height)
                    .gesture(SimultaneousGesture(magnificationGesture, dragGesture))
            } else {
                loadingView
            }
        }
    }

    private func loadAsset() {
        isAssetLoading = true
        viewModel.cancelVideoLoading()

        if currentAsset.mediaType == .video {
            loadVideo()
        } else {
            loadImage()
            player = nil
        }
    }

    private func loadImage() {
        viewModel.getImage(for: currentAsset) { downloadedImage in
            DispatchQueue.main.async {
                self.image = downloadedImage
                self.isAssetLoading = false
            }
        }
    }

    private func loadVideo() {
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

    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($scaleState) { currentState, gestureState, _ in
                gestureState = currentState
            }
            .onEnded { value in
                let newScale = scale * value
                let clampedScale = min(max(newScale, 1.0), 24.0)

                if clampedScale < scale {
                    let screenWidth = UIScreen.main.bounds.width
                    let screenHeight = UIScreen.main.bounds.height
                    let imageWidth = screenWidth * clampedScale
                    let imageHeight = screenHeight * clampedScale

                    let xOffset = min(max(offset.width + offsetState.width, -(imageWidth - screenWidth) / 2), (imageWidth - screenWidth) / 2)
                    let yOffset = min(max(offset.height + offsetState.height, -(imageHeight - screenHeight) / 2), (imageHeight - screenHeight) / 2)

                    offset = CGSize(width: xOffset, height: yOffset)
                }

                scale = clampedScale

                if scale == 1.0 {
                    isZoomed = false
                } else {
                    isZoomed = true
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($offsetState) { currentState, gestureState, _ in
                if isZoomed {
                    gestureState = currentState.translation
                } else {
                    gestureState = CGSize.zero
                }
            }
            .onEnded { value in
                if isZoomed {
                    offset.height += value.translation.height
                    offset.width += value.translation.width
                }
            }
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                guard !isAssetLoading && scale == 1.0 else { return }
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
