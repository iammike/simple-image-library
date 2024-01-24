//
//  ContentView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var selectedAsset: PHAsset?
    @State private var isDetailViewPresented = false

    var body: some View {
        Group {
            if viewModel.hasPhotoLibraryAccess {
                // Main content
                ZStack {
                    NavigationView {
                        AlbumView(viewModel: viewModel)
                        ThumbnailListView(viewModel: viewModel, selectedAsset: $selectedAsset, isDetailViewPresented: $isDetailViewPresented)
                    }

                    if isDetailViewPresented, let selectedAsset = selectedAsset {
                        DetailView(viewModel: viewModel, asset: selectedAsset, isPresented: $isDetailViewPresented)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.7).edgesIgnoringSafeArea(.all))
                    }
                }
            } else if viewModel.photoLibraryAccessHasBeenChecked {
                // Access denied or limited
                Text("Full Access to the photo library is required. Please enable access in Settings.")
            } else {
                ProgressView()
                    .scaleEffect(1.5, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
        }
    }
}
