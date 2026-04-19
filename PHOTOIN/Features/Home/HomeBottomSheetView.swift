//
//  HomeBottomSheetView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import SwiftUI

struct HomeBottomSheetView: View {
    let featuredPhoto: TravelPhoto?
    let locationCount: Int
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                isExpanded.toggle()
            } label: {
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "收起地点信息" : "展开地点信息")
            .accessibilityHint("查看当前选中地点的照片和地图摘要")

            if isExpanded {
                if let featuredPhoto {
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
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("已收录 \(locationCount) 个地点")
                        .font(.system(.headline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.white)

                    Text("先用示例照片把交互搭起来。后面我们可以接真实照片权限、定位提取和地图详情页。")
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
    }

    private var sheetTitle: String {
        featuredPhoto?.title ?? "没有匹配地点"
    }

    private var sheetSubtitle: String {
        if let featuredPhoto {
            return "\(featuredPhoto.locationName) · \(featuredPhoto.regionName)"
        }

        return "换个关键词继续搜索"
    }
}
