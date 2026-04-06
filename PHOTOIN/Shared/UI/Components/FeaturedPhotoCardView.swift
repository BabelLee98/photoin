//
//  FeaturedPhotoCardView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import SwiftUI

struct FeaturedPhotoCardView: View {
    let photo: TravelPhoto

    var body: some View {
        let markerStyle = HomePhotoMarkerStyleProvider.style(for: photo)

        HStack(spacing: 14) {
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
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: markerStyle.symbolName)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white.opacity(0.96))
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(photo.title)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.2))

                Text("\(photo.locationName) · \(photo.regionName)")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Color(red: 0.36, green: 0.41, blue: 0.43))

                Text("拍摄于 \(photo.captureDate)")
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundStyle(Color(red: 0.46, green: 0.5, blue: 0.53))

                Label("已定位保存", systemImage: "location.fill")
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(markerStyle.accentColor)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        }
    }
}
