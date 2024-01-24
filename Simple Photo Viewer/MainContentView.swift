//
//  MainContentView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/24/24.
//

import SwiftUI
import Photos

struct MainContentView: View {
    var viewModel: ViewModel
    var selectedAsset: Binding<PHAsset?>
    var isDetailViewPresented: Binding<Bool>

    var body: some View {
        ZStack {
            NavigationView {
                AlbumView(viewModel: viewModel)
                ThumbnailListView(viewModel: viewModel, selectedAsset: selectedAsset, isDetailViewPresented: isDetailViewPresented)
            }

            if isDetailViewPresented.wrappedValue, let selectedAsset = selectedAsset.wrappedValue {
                DetailView(viewModel: viewModel, asset: selectedAsset, isPresented: isDetailViewPresented)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.7).edgesIgnoringSafeArea(.all))
            }
        }
    }
}

