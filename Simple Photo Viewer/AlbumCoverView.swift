//
//  AlbumCoverView.swift
//  Simple Photo Viewer
//
//  A small square cover image for an album row. The app's users are described as
//  non-readers, so a picture carries more than the album's name does.
//

import SwiftUI
import Photos

struct AlbumCoverView: View {
    let asset: PHAsset?
    let size: CGFloat
    /// The album's assigned color, drawn as a ring around the cover. A separate dot
    /// alongside a photo gave non-readers two cues for one job, so the color rides
    /// on the thumbnail instead of competing with it.
    var accentColor: Color?

    @State private var image: UIImage?

    private var ringWidth: CGFloat { max(3, (size * 0.08).rounded()) }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color(UIColor.tertiarySystemFill))
                    .overlay(
                        Image(systemName: "photo.fill")
                            .foregroundStyle(Color.gray)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(accentColor ?? .clear, lineWidth: ringWidth)
        )
        .accessibilityHidden(true)
        .onAppear(perform: loadCover)
    }

    private func loadCover() {
        guard image == nil, let asset else { return }

        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

        let scale = UIScreen.main.scale
        let target = CGSize(width: size * scale, height: size * scale)

        PHImageManager.default().requestImage(
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
