//
//  MainUI.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 5/1/24.
//

import SwiftUI
import Photos

struct MainUI: View {
    var viewModel: ViewModel
    var selectedAsset: Binding<PHAsset?>
    var isDetailViewPresented: Binding<Bool>

    var body: some View {
        NavigationView {
            AlbumView(viewModel: viewModel)
            ThumbnailListView(viewModel: viewModel, selectedAsset: selectedAsset, isDetailViewPresented: isDetailViewPresented)
        }

        if isDetailViewPresented.wrappedValue, let selectedAsset = selectedAsset.wrappedValue {
            DetailView(viewModel: viewModel, isPresented: isDetailViewPresented, asset: selectedAsset)
        }
    }
}
