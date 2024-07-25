//
//  LivePhotoView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 7/25/24.
//

import SwiftUI
import PhotosUI

struct LivePhotoView: UIViewRepresentable {
    var livePhoto: PHLivePhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        let livePhotoView = PHLivePhotoView()
        livePhotoView.contentMode = .scaleAspectFit
        livePhotoView.livePhoto = livePhoto
        return livePhotoView
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
    }
}
