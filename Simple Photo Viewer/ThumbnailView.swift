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
        Image(uiImage: getThumbnail(for: asset))
            .resizable()
            .scaledToFill() // Changed to scaledToFill
            .frame(width: 200, height: 200)
//            .background(Color.white) // Explicit background color
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)) // Optional: Add a border to clearly see the rounded corners
    }


    private func getThumbnail(for asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        var thumbnail = UIImage()
        manager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFit, options: option, resultHandler: { (result, _) in
            if let result = result {
                thumbnail = result
            }
        })
        return thumbnail
    }
}

