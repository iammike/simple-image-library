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

    /// Set from Setup's cover, which doubles as the button that opens the picker.
    @State private var isShowingCoverPicker = false

    private var albumNameTextSize: AlbumNameTextSize {
        AlbumNameTextSize(rawValue: albumNameTextSizeRaw) ?? .defaultValue
    }

    /// Scales the cover with the system text-size setting, matching the name beside it.
    @ScaledMetric(relativeTo: .body) private var dynamicTypeScale: CGFloat = 1

    /// Setup shows the cover too, now that tapping it is how a caregiver chooses one.
    private var showsCover: Bool { true }

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
        if viewModel.isSetupMode {
            // Setup's rows hold their own colour and visibility buttons, which have to
            // stay separately reachable, so the row is not combined into one element.
            rowContent
                .sheet(isPresented: $isShowingCoverPicker) {
                    AlbumCoverPickerView(viewModel: viewModel, album: album)
                }
        } else {
            // One labelled button rather than an invisible overlay button, which laid
            // out at zero size and so could not be focused by assistive technology.
            rowContent
                .contentShape(Rectangle())
                .onTapGesture(perform: selectAndSpeak)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(albumTitle)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(.default, selectAndSpeak)
        }
    }

    private var rowContent: some View {
        HStack {
            if showsCover {
                let cover = AlbumCoverView(
                    asset: viewModel.albumCoverAssets[album.localIdentifier],
                    size: coverSize,
                    accentColor: albumColorHex.map { Color(hex: $0) }
                )
                if viewModel.isSetupMode {
                    // The cover is the button that opens the picker: tap the picture
                    // to change the picture, rather than a separate control to find.
                    Button {
                        isShowingCoverPicker = true
                    } label: {
                        cover
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Album cover")
                    .accessibilityHint("Choose which photo represents this album")
                } else {
                    cover
                }
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
    }
}
