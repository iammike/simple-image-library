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
                        DetailView(asset: selectedAsset, isPresented: $isDetailViewPresented)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                    }
                }
            } else if viewModel.photoLibraryAccessHasBeenChecked {
                // Access denied or limited
                Text("Full Access to the photo library is required. Please enable access in Settings.")
            } else {
                // Access check in progress
                Text("Loading...")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.photoLibraryAccessHasBeenChecked = false
            viewModel.checkPhotoLibraryAccess()
        }
    }
}
