//
//  DetailView.swift
//  Simple Photo Viewer
//
//  The full-screen photo/video/Live Photo viewer. Owns only what is shared across
//  every media type -- which asset is current, the swipe gesture, the edge bounce,
//  and the close button -- and delegates actually loading and showing one asset to
//  PhotoDetailContentView, LivePhotoDetailContentView or VideoDetailContentView,
//  one instance per asset. That split is what keeps a swipe from ever mixing up two
//  assets' state: each one's image, player or zoom lives only as long as its own
//  view does, so there is nothing left over for the next asset to inherit stale.
//

import SwiftUI
import Photos

struct DetailView: View {
    @ObservedObject var viewModel: ViewModel
    @Binding var isPresented: Bool

    @State private var currentIndex: Int
    /// Set by whichever media view is showing (only photos and Live Photos ever
    /// zoom); gates the swipe gesture below so swiping away does not lose your
    /// place mid-zoom.
    @State private var isZoomed = false
    @State private var swipeDirection: SwipeDirection = .right // initial direction for the first asset loaded

    /// A swipe past either end nudges the picture this far and springs it back, so
    /// the end of the album reads as a bounce rather than as a swipe that failed.
    @State private var edgeNudge: CGFloat = 0
    private let edgeNudgeDistance: CGFloat = 60

    @AppStorage("visionImpairedCloseButton") private var visionImpairedCloseButton = false

    enum SwipeDirection {
        case left, right, none
    }

    /// True while `currentIndex` points at a photo. The list can shrink under an open
    /// view, since hiding albums clears it, and the view must close rather than
    /// subscript past the end.
    private var hasCurrentAsset: Bool {
        viewModel.images.indices.contains(currentIndex)
    }

    private var currentAsset: PHAsset {
        viewModel.images[currentIndex]
    }

    init(viewModel: ViewModel, isPresented: Binding<Bool>, asset: PHAsset) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: viewModel.images.firstIndex(where: { $0 == asset }) ?? 0)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if hasCurrentAsset {
                content
                closeButton
            }
        }
        // Siblings in the ZStack below stay exposed to VoiceOver otherwise, and the
        // gear under an open photo must not be reachable.
        .accessibilityAddTraits(.isModal)
        .onAppear {
            guard hasCurrentAsset else {
                isPresented = false
                return
            }
            // Only for the asset this view opened on: read again on every swipe would
            // talk over itself and over whatever the caregiver is doing.
            SpeechManager.shared.speak(ReadAloud.spokenDateString(for: currentAsset.creationDate) ?? "")
        }
        .onChange(of: viewModel.images.count) { _, _ in
            if !hasCurrentAsset {
                isPresented = false
            }
        }
        .background(.black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .highPriorityGesture(
            isZoomed ? nil : swipeGesture
        )
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if currentAsset.mediaType == .video {
                VideoDetailContentView(viewModel: viewModel, asset: currentAsset)
            } else if currentAsset.mediaSubtypes.contains(.photoLive) {
                LivePhotoDetailContentView(viewModel: viewModel, asset: currentAsset, isZoomed: $isZoomed)
            } else {
                PhotoDetailContentView(viewModel: viewModel, asset: currentAsset, isZoomed: $isZoomed)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .offset(x: edgeNudge)
        .id(currentAsset.localIdentifier)
        .transition(contentTransition)
    }

    private var closeButton: some View {
        let buttonSize: CGFloat = visionImpairedCloseButton ? 1.5 : 1.0
        let buttonOpacity: Double = visionImpairedCloseButton ? 1.0 : 0.7

        // Closing removes `content`, which removes whichever media view was showing,
        // which tears down its own player or cancels its own load in turn -- nothing
        // further to release from here.
        return Button(action: { isPresented = false }) {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 24 * buttonSize, height: 24 * buttonSize)
                .foregroundColor(.black)
                .padding()
                .background(Color.gray.opacity(buttonOpacity))
                .clipShape(Circle())
        }
        .accessibilityLabel("Close")
        .padding(.top, 70)
        .padding(.trailing, 20)
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

    /// - Parameter direction: 1 nudges the picture to the right, -1 to the left.
    private func bounce(towards direction: CGFloat) {
        withAnimation(.easeOut(duration: 0.15)) {
            edgeNudge = direction * edgeNudgeDistance
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.15)) {
            edgeNudge = 0
        }
    }

    private var swipeGesture: some Gesture {
        // Zoom already gates this gesture entirely (see `.highPriorityGesture`
        // above), and each asset's load is owned by its own view now, so nothing
        // here needs to wait on the previous asset's cleanup before moving on.
        DragGesture()
            .onEnded { gesture in
                if gesture.translation.width > 100 {
                    if currentIndex == 0 {
                        bounce(towards: 1)
                    } else {
                        swipeDirection = .right
                        withAnimation {
                            currentIndex -= 1
                            isZoomed = false
                        }
                    }
                } else if gesture.translation.width < -100 {
                    if currentIndex >= viewModel.images.count - 1 {
                        bounce(towards: -1)
                    } else {
                        swipeDirection = .left
                        withAnimation {
                            currentIndex += 1
                            isZoomed = false
                        }
                    }
                }
            }
    }
}
