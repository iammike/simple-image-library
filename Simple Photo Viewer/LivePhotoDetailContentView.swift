//
//  LivePhotoDetailContentView.swift
//  Simple Photo Viewer
//
//  A single full-screen Live Photo: loads, shows a placeholder until it does, and is
//  zoomable. See PhotoDetailContentView for why this owns its own state instead of
//  sharing it with whatever is swiped to next.
//

import SwiftUI
import Photos

struct LivePhotoDetailContentView: View {
    @ObservedObject var viewModel: ViewModel
    let asset: PHAsset
    @Binding var isZoomed: Bool

    @State private var livePhoto: PHLivePhoto?

    var body: some View {
        Group {
            if let livePhoto {
                LivePhotoView(livePhoto: livePhoto)
                    .zoomable(isZoomed: $isZoomed)
            } else {
                DetailLoadingView()
            }
        }
        .task(id: asset.localIdentifier) {
            livePhoto = await viewModel.livePhoto(for: asset)
        }
    }
}
