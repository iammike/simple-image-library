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
//    let albumColor: Color
    var toggleVisibility: () -> Void
    var selectAlbum: () -> Void

    var body: some View {
        HStack {
            Group {
                Text(album.localizedTitle ?? "Unknown Album")
                Spacer()
            }
            .onTapGesture {
                selectAlbum()
            }

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
    }
}
