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
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            
            Text("LE Viewer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.top, 20)

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

