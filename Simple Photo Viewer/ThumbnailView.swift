//
//  ThumbnailView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import Photos

struct ThumbnailView: View {
    @State private var thumbnailImage: UIImage? = nil
    let asset: PHAsset

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// iPad cells are a fixed 200pt, which its grid columns never fall below. A phone
    /// column is narrower than that, so there the cell takes the column's width instead.
    private var fixedSide: CGFloat? {
        horizontalSizeClass == .compact ? nil : 200
    }

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(width: fixedSide, height: fixedSide)
            .overlay {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .overlay(
                            Image(systemName: "icloud.slash")
                                .foregroundStyle(Color.gray)
                        )
                }
            }
            // On the sized cell, not the image: a non-square image overflows the cell
            // before it is clipped, and a badge placed on it would be clipped too.
            .overlay { if thumbnailImage != nil { mediaOverlay } }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray, lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityDescription)
            .onAppear {
                loadThumbnailImage()
            }
    }

    private var accessibilityDescription: String {
        if asset.mediaType == .video {
            return "Video, \(videoDurationText)"
        } else if asset.mediaSubtypes.contains(.photoLive) {
            return "Live Photo"
        } else {
            return "Photo"
        }
    }

    @ViewBuilder
    private var mediaOverlay: some View {
        VStack(alignment: .trailing) {
            Spacer()
            HStack {
                Spacer()
                if asset.mediaType == .video {
                    Text("⏵ \(videoDurationText)")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(4)
                } else if asset.mediaSubtypes.contains(.photoLive) {
                    Image(systemName: "livephoto")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                        .padding(4)
                }
            }
        }
        .padding(8)
    }

    private func loadThumbnailImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact

        manager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                self.thumbnailImage = image
            }
        }
    }

    private var videoDurationText: String {
        let durationInSeconds = Int(round(asset.duration))
        let hours = durationInSeconds / 3600
        let minutes = (durationInSeconds % 3600) / 60
        let seconds = durationInSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
