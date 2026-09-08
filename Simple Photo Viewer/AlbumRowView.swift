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

    @AppStorage("albumNameTextSize") private var albumNameTextSizeRaw = AlbumNameTextSize.defaultValue.rawValue

    private var albumNameTextSize: AlbumNameTextSize {
        AlbumNameTextSize(rawValue: albumNameTextSizeRaw) ?? .defaultValue
    }

    /// Scales the cover with the system text-size setting, matching the name beside it.
    @ScaledMetric(relativeTo: .body) private var dynamicTypeScale: CGFloat = 1

    private var showsCover: Bool {
        !viewModel.isSetupMode
    }

    /// Sized against the album name so the row grows with the caregiver's preset.
    private var coverSize: CGFloat {
        max(44, albumNameTextSize.pointSize * 2.5 * dynamicTypeScale)
    }

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
            if showsCover {
                AlbumCoverView(
                    asset: viewModel.albumCoverAssets[album.localIdentifier],
                    size: coverSize,
                    accentColor: albumColorHex.map { Color(hex: $0) }
                )
            }

            Text(albumTitle)
                .font(albumNameTextSize.font)
                .onTapGesture {
                    selectAndSpeak()
                }

            Spacer()

            if viewModel.isSetupMode {
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
                if !viewModel.isSetupMode {
                    Button(action: selectAndSpeak) {
                        Rectangle().foregroundColor(Color.clear)
                    }
                }
            }
        )
    }
}
