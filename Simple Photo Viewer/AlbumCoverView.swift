//
//  AlbumCoverView.swift
//  Simple Photo Viewer
//
//  A small square cover image for an album row.
//

import SwiftUI
import Photos

struct AlbumCoverView: View {
    let asset: PHAsset?
    let size: CGFloat
    /// The album's assigned color, drawn as a ring around the cover.
    var accentColor: Color?

    @State private var image: UIImage?
    @State private var imageRequestID: PHImageRequestID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var ringWidth: CGFloat { max(3, (size * 0.08).rounded()) }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                Rectangle()
                    .fill(Color(UIColor.tertiarySystemFill))
                    .overlay(
                        Image(systemName: "photo.fill")
                            .foregroundStyle(Color.gray)
                    )
                    .transition(.opacity)
            }
        }
        // Matches ThumbnailView's crossfade: a cover popping in reads as a jolt for
        // an audience more sensitive to it than most. Off under Reduce Motion.
        .animation(reduceMotion ? nil : .easeIn(duration: 0.2), value: image != nil)
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(accentColor ?? .clear, lineWidth: ringWidth)
        )
        .accessibilityHidden(true)
        .onAppear(perform: loadCover)
        // A refresh can hand this row a different asset (a newer photo). The image on
        // screen must follow it rather than freeze on whichever asset appeared first.
        .onChange(of: asset?.localIdentifier) { _, _ in
            cancelPendingRequest()
            image = nil
            loadCover()
        }
        .onDisappear(perform: cancelPendingRequest)
    }

    private func cancelPendingRequest() {
        if let imageRequestID {
            PHImageManager.default().cancelImageRequest(imageRequestID)
        }
        imageRequestID = nil
    }

    private func loadCover() {
        guard image == nil, let asset else { return }

        let options = PHImageRequestOptions()
        // This is a list thumbnail that can scroll past quickly; allowing network
        // access here would mean an iCloud download per row on a large library, for
        // what is only a decorative cover.
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

        let scale = UIScreen.main.scale
        let target = CGSize(width: size * scale, height: size * scale)

        imageRequestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: target,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result {
                image = result
            }
        }
    }
}
