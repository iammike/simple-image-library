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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var minThumbnailWidth: CGFloat {
        horizontalSizeClass == .compact ? 115 : 200
    }

    var body: some View {
        ScrollView {
            // On iPad the photo pane is what an adult is looking at after hiding
            // everything, so the explanation belongs here too.
            if viewModel.albumsLoaded && !viewModel.hasVisibleAlbums {
                NoVisibleAlbumsView()
            }

            if viewModel.currentAlbumIsEmpty {
                EmptyAlbumView()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: minThumbnailWidth))]) {
                ForEach(viewModel.images, id: \.localIdentifier) { asset in
                    ZStack {
                        ThumbnailView(asset: asset)
                            .onTapGesture {
                                self.selectedAsset = asset
                                self.isDetailViewPresented = true
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
