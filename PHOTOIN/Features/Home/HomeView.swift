//
//  HomeView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.95, blue: 0.93),
                    Color(red: 0.9, green: 0.92, blue: 0.91)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 7) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color(red: 0.45, green: 0.49, blue: 0.51))

                            TextField("搜索地点", text: $viewModel.searchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.75))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        }
                    }
                    .padding(.top, 20)

                    ZStack {
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(Color.white.opacity(0.34))
                            .frame(height: 460)
                            .overlay {
                                RoundedRectangle(cornerRadius: 36, style: .continuous)
                                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
                            }

                        VStack(spacing: 7) {
                            TravelGlobeView(
                                photos: viewModel.filteredPhotos,
                                highlightedPhotoID: viewModel.featuredPhoto?.id,
                                rotation: $viewModel.globeRotation
                            )
                            .frame(height: 340)

                            if let featuredPhoto = viewModel.featuredPhoto {
                                FeaturedPhotoCardView(photo: featuredPhoto)
                                    .padding(.horizontal, 18)
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "location.slash")
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundStyle(Color(red: 0.48, green: 0.52, blue: 0.54))

                                    Text("没有找到匹配的地点")
                                        .font(.system(.headline, design: .rounded, weight: .medium))
                                        .foregroundStyle(Color(red: 0.28, green: 0.31, blue: 0.34))

                                    Text("换个地名试试，或者稍后把新的旅行照片上传进来。")
                                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(Color(red: 0.46, green: 0.5, blue: 0.53))
                                }
                                .padding(.horizontal, 32)
                            }
                        }
                        .padding(.vertical, 10)
                    }

                    Button {
                        viewModel.presentUploadPrompt()
                    } label: {
                        Label("上传", systemImage: "square.and.arrow.up")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(red: 0.24, green: 0.31, blue: 0.34))
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("已收录 \(viewModel.filteredPhotos.count) 个地点")
                            .font(.system(.headline, design: .rounded, weight: .medium))
                            .foregroundStyle(Color(red: 0.22, green: 0.25, blue: 0.28))

                        Text("先用示例照片把交互搭起来。后面我们可以接真实照片权限、定位提取和地图详情页。")
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .foregroundStyle(Color(red: 0.43, green: 0.47, blue: 0.49))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.55))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPhotosIfNeeded()
        }
        .alert("上传功能稍后接入", isPresented: $viewModel.isUploadPromptPresented) {
            Button("知道了", role: .cancel) {
                viewModel.dismissUploadPrompt()
            }
        } message: {
            Text("这一版先把首页交互搭起来，下一步可以接系统照片库和位置信息。")
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: AppDependencies.live().makeHomeViewModel())
    }
}
