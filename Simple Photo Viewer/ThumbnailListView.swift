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
                    ThumbnailView(asset: asset)
                        .onTapGesture {
                            self.selectedAsset = asset
                            self.isDetailViewPresented = true
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
