//
//  AlbumView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/23/24.
//

import SwiftUI
import Photos

struct AlbumView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        List {
            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                HStack {
                    Text(album.localizedTitle ?? "Unknown Album")
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.selectedAlbumIdentifier != album.localIdentifier {
                        viewModel.selectAlbum(album)
                    }
                }
                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                .background(viewModel.selectedAlbumIdentifier == album.localIdentifier ? Color.blue.opacity(0.3) : Color.clear)
                .cornerRadius(10)
            }
        }
    }
}

