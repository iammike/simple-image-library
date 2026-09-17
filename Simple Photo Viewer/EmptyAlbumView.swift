//
//  EmptyAlbumView.swift
//  Simple Photo Viewer
//
//  Shown in place of the grid when the open album's fetch came back with nothing.
//  An album only reaches the list because it held media, so this is what an
//  album looks like after its photos were deleted in Photos and the grid was
//  refreshed: the album list itself drops it on its next refresh.
//

import SwiftUI

struct EmptyAlbumView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.tint)

            Text("No photos here")
                .font(.headline)

            Text("This album is empty now. Pull down on the album list to refresh it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
    }
}
