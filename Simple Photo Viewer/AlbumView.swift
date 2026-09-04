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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingGate = false
    @State private var holdProgress: CGFloat = 0

    var body: some View {
        List {
            Text("Albums")
                .font(.title)
                .fontWeight(.bold)

            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                let isVisible = viewModel.albumSettings[album.localIdentifier]?.isVisible ?? true
                // Setup has its own screen now, so this list only ever shows the
                // albums a viewer is allowed to see.
                if isVisible {
                    AlbumRowView(
                        viewModel: viewModel,
                        album: album,
                        isSelected: viewModel.selectedAlbumIdentifier == album.localIdentifier,
                        isVisible: isVisible,
                        toggleVisibility: {
                            viewModel.toggleAlbumVisibility(album.localIdentifier)
                        },
                        selectAlbum: {
                            viewModel.openAlbum(album)
                        }
                    )
                }
            }
        }
        .refreshable {
            viewModel.refreshAlbums()
        }
        .toolbar {
            if !viewModel.isSetupMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ZStack {
                        Circle()
                            .trim(from: 0, to: holdProgress)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: holdProgress == 0 ? 0.2 : 3), value: holdProgress)
                        Image(systemName: "gearshape")
                    }
                    // At rest the progress ring draws nothing, so without an explicit
                    // shape only the glyph itself is touchable, well under 44pt, and
                    // this is the only route into Setup.
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    // In landscape on a phone the bar is short and its trailing edge
                    // sits close to the glyph, so the progress ring collides with the
                    // screen edge. iPad has room already and looks over-inset if padded.
                    .padding(.trailing, horizontalSizeClass == .compact ? 10 : 0)
                    .onLongPressGesture(minimumDuration: 3, maximumDistance: 50) {
                        holdProgress = 0
                        showingGate = true
                    } onPressingChanged: { pressing in
                        holdProgress = pressing ? 1 : 0
                    }
                    // The label and action belong on the element carrying the gesture:
                    // VoiceOver cannot perform a long press, so give it a direct action.
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Open Setup")
                    .accessibilityHint("Press and hold to open Setup")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        holdProgress = 0
                        showingGate = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingGate) {
            ParentalGateView { viewModel.enterSetup() }
        }
    }
}
