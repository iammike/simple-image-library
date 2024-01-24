//
//  DetailView.swift
//  Simple Photo Viewer
//
//  Created by Michael Collins on 1/22/24.
//

import SwiftUI
import Photos

struct DetailView: View {
    @ObservedObject var viewModel: ViewModel
    let asset: PHAsset
    @Binding var isPresented: Bool
    @State private var image: UIImage? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = image {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .shadow(radius: 10)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button(action: {
                    self.isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                }.padding()
            } else {
                ProgressView()
                    .scaleEffect(1.5, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        viewModel.getImage(for: asset) { downloadedImage in
            self.image = downloadedImage
        }
    }
}
