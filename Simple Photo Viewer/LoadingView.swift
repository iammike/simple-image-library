//
//  LoadingView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/24/24.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Text("Loading, please sit tight!")
                .font(.headline)
                .foregroundColor(.primary)
            ProgressView()
                .scaleEffect(1.5, anchor: .center)
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                .padding()
        }
    }
}

