//
//  DetailView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import Photos

struct DetailView: View {
    let asset: PHAsset

    var body: some View {
        if asset.mediaType == .image {
            GeometryReader { geometry in
                Image(uiImage: getImage(for: asset))
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        } else if asset.mediaType == .video {
            VideoPlayerView(asset: asset)
        }
    }

    private func getImage(for asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        var image = UIImage()
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option, resultHandler: { (result, _) in
            if let result = result {
                image = result
            }
        })
        return image
    }
}
