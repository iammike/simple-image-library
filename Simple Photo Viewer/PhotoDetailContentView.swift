//
//  PhotoDetailContentView.swift
//  Simple Photo Viewer
//
//  A single full-screen photo: loads, shows a placeholder until it does, and is
//  zoomable. One instance exists per photo shown -- DetailView keys it by the
//  asset's identifier -- so its own @State (the image, the zoom) cannot leak into
//  whatever photo is swiped to next; SwiftUI simply makes a fresh one.
//

import SwiftUI
import Photos

struct PhotoDetailContentView: View {
    @ObservedObject var viewModel: ViewModel
    let asset: PHAsset
    @Binding var isZoomed: Bool

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .zoomable(isZoomed: $isZoomed)
            } else {
                DetailLoadingView()
            }
        }
        .task(id: asset.localIdentifier) {
            // A fast, lower-quality pass appears almost immediately -- which matters
            // most for a large photo (a panorama) that is slow to reach full quality
            // -- then a final pass replaces it. Swiping away cancels this Task, which
            // cancels the underlying Photos request in turn.
            for await update in viewModel.imageUpdates(for: asset) {
                image = update
            }
        }
    }
}
