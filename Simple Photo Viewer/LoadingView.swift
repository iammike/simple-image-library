//
//  LoadingView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/24/24.
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var barOpacity: Double = 0.5

    var body: some View {
        ZStack {
            background
            VStack(spacing: 20) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: "#FF8C42").opacity(0.25), radius: 12, x: 0, y: 6)

                Text("LE Viewer")
                    .font(.title2)
                    .bold()

                Capsule()
                    .fill(Color(hex: "#FF8C42"))
                    .frame(width: 80, height: 4)
                    .opacity(barOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            barOpacity = 1.0
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        if colorScheme == .dark {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
        } else {
            LinearGradient(
                colors: [Color(hex: "#FFF8F2"), Color(hex: "#FFE8D6")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
