//
//  ThumbnailListView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/23/24.
//

import SwiftUI
import Photos

struct ThumbnailListView: View {
    @ObservedObject var viewModel: ViewModel
    @Binding var selectedAsset: PHAsset?
    @Binding var isDetailViewPresented: Bool

    let minThumbnailWidth: CGFloat = 200

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minThumbnailWidth))]) {
                ForEach(viewModel.images, id: \.localIdentifier) { asset in
                    ZStack {
                        ThumbnailView(asset: asset)
                            .onTapGesture {
                                self.selectedAsset = asset
                                self.isDetailViewPresented = true
                            }

                        if asset.mediaType == .video {
                            // Overlay a play button for videos
                            Image(systemName: "play.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                        }
                    }
                    .onAppear {
                        if let lastAsset = viewModel.images.last, lastAsset == asset {
                            viewModel.loadMorePhotos()
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.refreshThumbnails()
        }
    }
}
