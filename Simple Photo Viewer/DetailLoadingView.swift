//
//  DetailLoadingView.swift
//  Simple Photo Viewer
//
//  The placeholder each full-screen media type shows before its own load finishes.
//  Shared so a photo, Live Photo or video reads the same way while loading.
//

import SwiftUI

struct DetailLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
