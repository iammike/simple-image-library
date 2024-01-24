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

    // Define the minimum width for each thumbnail
    let minThumbnailWidth: CGFloat = 200 // Adjust this value as needed

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minThumbnailWidth))]) {
                ForEach(viewModel.uniqueAssets, id: \.id) { uniqueAsset in
                    ThumbnailView(asset: uniqueAsset.asset)
                        .onTapGesture {
                            self.selectedAsset = uniqueAsset.asset
                            self.isDetailViewPresented = true
                        }
                        .onAppear {
                            if viewModel.uniqueAssets.last?.id == uniqueAsset.id {
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
