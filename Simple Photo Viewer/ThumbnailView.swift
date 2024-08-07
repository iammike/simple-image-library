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

    var body: some View {
        Group {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .overlay(mediaOverlay)
            } else {
                Rectangle()
                    .overlay(
                        Image(systemName: "icloud.slash")
                            .foregroundStyle(Color.gray)
                    )
                    .frame(width: 200, height: 200)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray, lineWidth: 1))
        .onAppear {
            loadThumbnailImage()
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
