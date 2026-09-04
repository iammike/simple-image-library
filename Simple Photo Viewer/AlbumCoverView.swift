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

    @State private var image: UIImage?

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
