//
//  ZoomableMedia.swift
//  Simple Photo Viewer
//
//  Pinch-to-zoom, pan-while-zoomed, and double-tap-to-zoom-at-a-point, shared by the
//  full-screen photo and Live Photo views -- the only two media types the app lets
//  someone zoom. AVKit brings its own, separate zoom gesture for video, which this
//  app has no way to see or coordinate with (see #64).
//
//  Panning and zooming used to clamp against UIScreen.main.bounds, the whole
//  screen's size -- wrong on iPad Split View or Slide Over, where the app is not
//  full screen, and it would let the image be dragged out of view or refuse to pan
//  as far as the visible area actually allows. A GeometryReader measures this view's
//  own size instead, which is correct everywhere.
//

import SwiftUI

struct ZoomableMedia: ViewModifier {
    /// Reported up so the enclosing DetailView can gate its own swipe-to-navigate
    /// gesture: swiping away while zoomed in would lose your place in the image.
    @Binding var isZoomed: Bool

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var pinchState: CGFloat = 1
    @GestureState private var dragState: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 8
    /// Where a double-tap zooms in to, matching Photos.
    private let doubleTapScale: CGFloat = 3

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            content
                .frame(width: size.width, height: size.height)
                .scaleEffect(scale * pinchState)
                .offset(x: offset.width + dragState.width, y: offset.height + dragState.height)
                .gesture(
                    SimultaneousGesture(
                        SimultaneousGesture(magnification(in: size), pan),
                        doubleTapToZoom(in: size)
                    )
                )
        }
    }

    /// The furthest `offset` can go at a given scale before the content's edge would
    /// pull in past the view's edge, in either axis.
    private func clampedOffset(_ proposed: CGSize, scale: CGFloat, in size: CGSize) -> CGSize {
        guard scale > 1 else { return .zero }
        let maxX = size.width * (scale - 1) / 2
        let maxY = size.height * (scale - 1) / 2
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func magnification(in size: CGSize) -> some Gesture {
        MagnificationGesture()
            .updating($pinchState) { current, state, _ in state = current }
            .onEnded { value in
                let newScale = min(max(scale * value, minScale), maxScale)
                offset = clampedOffset(offset, scale: newScale, in: size)
                scale = newScale
                isZoomed = scale > 1
            }
    }

    private var pan: some Gesture {
        DragGesture()
            .updating($dragState) { current, state, _ in
                guard isZoomed else { return }
                state = current.translation
            }
            .onEnded { value in
                guard isZoomed else { return }
                offset.width += value.translation.width
                offset.height += value.translation.height
            }
    }

    /// Zooms in centered on the tapped point, as Photos does, if not already zoomed;
    /// resets to fit, from wherever it was tapped, if it was.
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isZoomed {
                        scale = 1
                        offset = .zero
                        isZoomed = false
                    } else {
                        let tapFromCenter = CGSize(
                            width: value.location.x - size.width / 2,
                            height: value.location.y - size.height / 2
                        )
                        scale = doubleTapScale
                        offset = clampedOffset(
                            CGSize(
                                width: tapFromCenter.width * (1 - doubleTapScale),
                                height: tapFromCenter.height * (1 - doubleTapScale)
                            ),
                            scale: doubleTapScale,
                            in: size
                        )
                        isZoomed = true
                    }
                }
            }
    }
}

extension View {
    /// Pinch, pan, and double-tap to zoom, gated and reported through `isZoomed`.
    func zoomable(isZoomed: Binding<Bool>) -> some View {
        modifier(ZoomableMedia(isZoomed: isZoomed))
    }
}
