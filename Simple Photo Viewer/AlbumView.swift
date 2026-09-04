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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showingGate = false

    /// A phone in landscape gets a short navigation bar, roughly 32pt, and a 30pt
    /// ring plus its stroke fills that entirely, so the ring was clipped by the top
    /// of the screen. It shrinks to fit the bar it is drawn in.
    private var ringDiameter: CGFloat {
        verticalSizeClass == .compact ? 22 : 30
    }

    /// Matches the bar so the item is never laid out taller than what contains it.
    private var barHeight: CGFloat {
        verticalSizeClass == .compact ? 32 : 44
    }
    @State private var holdProgress: CGFloat = 0

    var body: some View {
        List {
            Text("Albums")
                .font(.title)
                .fontWeight(.bold)

            if viewModel.albumsLoaded && !viewModel.hasVisibleAlbums {
                NoVisibleAlbumsView()
                    .listRowBackground(Color.clear)
            }

            ForEach(viewModel.albums, id: \.localIdentifier) { album in
                let isVisible = viewModel.isVisible(album)
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
                            .frame(width: ringDiameter, height: ringDiameter)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: holdProgress == 0 ? 0.2 : 3), value: holdProgress)
                        Image(systemName: "gearshape")
                    }
                    // At rest the progress ring draws nothing, so without an explicit
                    // shape only the glyph itself is touchable, well under 44pt, and
                    // this is the only route into Setup. Width stays that of the ring:
                    // a 44pt-wide box pushed the glyph inside the bar's normal
                    // trailing margin.
                    .frame(width: ringDiameter, height: barHeight)
                    .contentShape(Rectangle())
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
