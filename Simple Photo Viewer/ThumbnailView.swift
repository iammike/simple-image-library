//
//  ThumbnailView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import Photos

struct ThumbnailView: View {
    let asset: PHAsset

    var body: some View {
        ZStack {
            Image(uiImage: getThumbnail(for: asset))
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if asset.mediaType == .video {
                // Overlay a play button icon for videos
                Image(systemName: "play.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
        }
    }

    private func getThumbnail(for asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        var thumbnail = UIImage()
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: { (result, _) in
            if let result = result {
                thumbnail = result
            }
        })
        return thumbnail
    }
}

