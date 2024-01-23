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
                ForEach(viewModel.images, id: \.self) { asset in
                    ThumbnailView(asset: asset)
                        .onTapGesture {
                            self.selectedAsset = asset
                            self.isDetailViewPresented = true
                        }
                        .onAppear {
                            if viewModel.images.last == asset {
                                viewModel.loadMorePhotos()
                            }
                        }
                }
            }
            .padding()
        }
    }
}



// Columnar
//struct ThumbnailListView: View {
//    @ObservedObject var viewModel: ViewModel
//    @Binding var selectedAsset: PHAsset?
//    @Binding var isDetailViewPresented: Bool
//
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]) {
//                ForEach(viewModel.images, id: \.self) { asset in
//                    ThumbnailView(asset: asset)
//                        .onTapGesture {
//                            self.selectedAsset = asset
//                            self.isDetailViewPresented = true
//                        }
//
//                        .onAppear {
//                            if viewModel.images.last == asset {
//                                viewModel.loadMorePhotos()
//                            }
//                        }
//                }
//            }
//            .padding()
//        }
//    }
//}
