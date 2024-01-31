//
//  AlbumRowView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/31/24.
//

import SwiftUI
import Photos

struct AlbumRowView: View {
    @ObservedObject var viewModel: ViewModel

    let album: PHAssetCollection
    let isSelected: Bool
    let isVisible: Bool
    var toggleVisibility: () -> Void
    var selectAlbum: () -> Void

    var body: some View {
        HStack {
            Text(album.localizedTitle ?? "Unknown Album")
                .onTapGesture {
                    selectAlbum()
                }

            Spacer()

            if viewModel.showAlbumViewSettings {
                Button(action: toggleVisibility) {
                    Image(systemName: "eye")
                        .foregroundColor(isVisible ? .primary : .gray)
                }
            }
        }
        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
        .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        .cornerRadius(6)
        .overlay(
            Group {
                if !viewModel.showAlbumViewSettings {
                    Button(action: selectAlbum) {
                        Rectangle().foregroundColor(Color.clear)
                    }
                }
            }
        )
    }
}
