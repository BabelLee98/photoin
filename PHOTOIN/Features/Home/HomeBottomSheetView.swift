//
//  HomeBottomSheetView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import SwiftUI

struct HomeBottomSheetView: View {
    let featuredPhoto: TravelPhoto?
    let relatedPhotos: [TravelPhoto]
    let locationCount: Int
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(spacing: 10) {
                Capsule()
                    .fill(Color.white.opacity(0.42))
                    .frame(width: 42, height: 5)

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sheetTitle)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.white)

                        Text(sheetSubtitle)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.84))
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.88))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityLabel(isExpanded ? "收起地点信息" : "展开地点信息")
            .accessibilityHint("查看当前选中地点的照片和地图摘要")

            if isExpanded {
                if relatedPhotos.isEmpty == false {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(relatedPhotos) { photo in
                                FeaturedPhotoCardView(photo: photo)
                                    .frame(width: 244)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                } else if let featuredPhoto {
                    FeaturedPhotoCardView(photo: featuredPhoto)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.82))

                        Text("没有找到匹配的地点")
                            .font(.system(.headline, design: .rounded, weight: .medium))
                            .foregroundStyle(Color.white)

                        Text("换个地名试试，或者稍后把新的旅行照片上传进来。")
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.white.opacity(0.82))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("已收录 \(locationCount) 个地点")
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture {
            isExpanded.toggle()
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
    }

    private var sheetTitle: String {
        featuredPhoto?.locationName ?? "没有匹配地点"
    }

    private var sheetSubtitle: String {
        if let featuredPhoto {
            return "\(featuredPhoto.regionName) · \(featuredPhoto.captureDate)"
        }

        return "换个关键词继续搜索"
    }
}
