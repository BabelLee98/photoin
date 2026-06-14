//
//  FeaturedPhotoCardView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import SwiftUI
import UIKit

struct FeaturedPhotoCardView: View {
    let photo: TravelPhoto

    var body: some View {
        let markerStyle = HomePhotoMarkerStyleProvider.style(for: photo)

        previewImage(for: markerStyle)
            .frame(maxWidth: .infinity)
            .frame(height: 196)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
    }

    /// Renders a real imported thumbnail when available, otherwise falls back to the existing styled marker block.
    @ViewBuilder
    private func previewImage(for markerStyle: HomePhotoMarkerStyle) -> some View {
        if let previewImageData = photo.previewImageData,
           let uiImage = UIImage(data: previewImageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 196)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            markerStyle.accentColor.opacity(0.95),
                            markerStyle.accentColor.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 196)
                .overlay {
                    Image(systemName: markerStyle.symbolName)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.white.opacity(0.96))
                }
        }
    }
}
