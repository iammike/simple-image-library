//
//  AlbumRowView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/31/24.
//

import SwiftUI
import Photos

struct AlbumRowView: View {
    let album: PHAssetCollection
    let isSelected: Bool
    let isVisible: Bool
    let albumColor: Color
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

            Button(action: toggleVisibility) {
                Image(systemName: "eye")
                    .foregroundColor(isVisible ? .primary : .gray)
            }
        }
        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray, lineWidth: isSelected ? 2 : 0)
                .background(albumColor)
        )
    }
}
