//
//  HomeView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var isBottomPanelExpanded = false

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            TravelPhotoMapView(
                photos: viewModel.filteredPhotos,
                selectedPhotoID: viewModel.selectedFeaturedPhotoID,
                onSelectPhoto: viewModel.selectPhoto
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.16),
                    Color.clear,
                    Color.black.opacity(0.24)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.white.opacity(0.88))

                    TextField("搜索地点", text: $viewModel.searchText)
                        .foregroundStyle(Color.white)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                }
                .padding(.top, 0)
                .padding(.horizontal, 16)

                Spacer()

                HomeBottomSheetView(
                    featuredPhoto: viewModel.featuredPhoto,
                    locationCount: viewModel.filteredPhotos.count,
                    isExpanded: $isBottomPanelExpanded
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isBottomPanelExpanded)
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button {
                        viewModel.presentUploadPrompt()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("上传照片")
                    .accessibilityHint("后续将用于导入带定位的旅行照片")
                    .padding(.trailing, 20)
                    .padding(.bottom, isBottomPanelExpanded ? 250 : 150)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
