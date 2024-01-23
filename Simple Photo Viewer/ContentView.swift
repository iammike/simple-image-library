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
        ZStack {
            // Main navigation view
            NavigationView {
                AlbumView(viewModel: viewModel)
                ThumbnailListView(viewModel: viewModel, selectedAsset: $selectedAsset, isDetailViewPresented: $isDetailViewPresented)
            }

            // Detail view overlay
            if isDetailViewPresented, let selectedAsset = selectedAsset {
                DetailView(asset: selectedAsset, isPresented: $isDetailViewPresented)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
            }
        }
    }
}

