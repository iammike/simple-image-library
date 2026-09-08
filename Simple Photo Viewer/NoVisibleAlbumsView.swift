//
//  NoVisibleAlbumsView.swift
//  Simple Photo Viewer
//
//  Shown when an adult has hidden every album. It sits inside the album list rather
//  than replacing the screen, so the gear stays reachable: replacing the screen
//  would strand the adult with no way back into Setup to unhide anything.
//

import SwiftUI

struct NoVisibleAlbumsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack")
                .font(.largeTitle)
                .foregroundStyle(.tint)

            Text("No albums to show")
                .font(.headline)

            Text("To show albums again, press and hold the gear to open Setup.")
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
