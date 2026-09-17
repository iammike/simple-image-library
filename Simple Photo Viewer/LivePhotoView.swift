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

    /// The view must take the space it is offered, not the photo's pixel size, which
    /// is what it asks for on its own: that laid it out thousands of points wide and
    /// carried the close button off screen with it.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PHLivePhotoView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }
}
