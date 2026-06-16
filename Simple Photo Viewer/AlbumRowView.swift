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

    private var albumTitle: String {
        album.localizedTitle ?? "Unknown Album"
    }

    private var albumColorHex: String? {
        viewModel.albumSettings[album.localIdentifier]?.colorHex
    }

    private func selectAndSpeak() {
        SpeechManager.shared.speak(albumTitle)
        selectAlbum()
    }

    /// The control shown in setup mode for cycling the album's color.
    private var colorSwatch: some View {
        Group {
            if let hex = albumColorHex {
                Circle().fill(Color(hex: hex))
            } else {
                Circle().strokeBorder(Color.gray, lineWidth: 1)
            }
        }
        .frame(width: 22, height: 22)
    }

    var body: some View {
        HStack {
            // In normal use, a colored dot lets non-readers recognize albums by color.
            if !viewModel.showAlbumViewSettings, let hex = albumColorHex {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)
            }

            Text(albumTitle)
                .onTapGesture {
                    selectAndSpeak()
                }

            Spacer()

            if viewModel.showAlbumViewSettings {
                Button(action: { viewModel.setAlbumColor(album.localIdentifier) }) {
                    colorSwatch
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Album color")

                Button(action: toggleVisibility) {
                    Image(systemName: "eye")
                        .foregroundColor(isVisible ? .primary : .gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isVisible ? "Hide album" : "Show album")
            }
        }
        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
        .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
        .cornerRadius(6)
        .overlay(
            Group {
                if !viewModel.showAlbumViewSettings {
                    Button(action: selectAndSpeak) {
                        Rectangle().foregroundColor(Color.clear)
                    }
                }
            }
        )
    }
}
