//
//  MainContentView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/24/24.
//

import SwiftUI
import Photos

struct MainContentView: View {
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    var viewModel: ViewModel
    var selectedAsset: Binding<PHAsset?>
    var isDetailViewPresented: Binding<Bool>

    var body: some View {
        ZStack {
            if isFirstLaunch {
                InitialView(isFirstLaunch: $isFirstLaunch)
            } else {
                MainUI(viewModel: viewModel, selectedAsset: selectedAsset, isDetailViewPresented: isDetailViewPresented)
            }
        }
    }
}
