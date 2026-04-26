//
//  HomeView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import PhotosUI
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var isBottomPanelExpanded = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

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

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        statLine(prefix: "目前去了", value: viewModel.totalVisitedCityCount, suffix: "个城市")
                        statLine(prefix: "爬了", value: viewModel.totalClimbedMountainCount, suffix: "座山")
                        statLine(prefix: "徒步了", value: viewModel.totalHikeCount, suffix: "次")
                        statLine(prefix: "上传了", value: viewModel.totalPhotoCount, suffix: "张照片")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    Spacer(minLength: 0)
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)

                Spacer()

                HStack(alignment: .bottom, spacing: 0) {
                    HomeBottomSheetView(
                        featuredPhoto: viewModel.featuredPhoto,
                        locationCount: viewModel.filteredPhotos.count,
                        isExpanded: $isBottomPanelExpanded
                    )
                    .frame(maxWidth: isBottomPanelExpanded ? 312 : 278, alignment: .leading)
                    .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isBottomPanelExpanded)

                    Spacer(minLength: 88)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 22)
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: 20,
                        matching: .images
                    ) {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 58, height: 58)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isImportingPhotos)
                    .opacity(viewModel.isImportingPhotos ? 0.72 : 1)
                    .accessibilityLabel("上传照片")
                    .accessibilityHint("将选中的照片导入到当前地图会话")
                    .padding(.trailing, 18)
                    .padding(.bottom, isBottomPanelExpanded ? 84 : 54)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadPhotosIfNeeded()
        }
        .onAppear {
            viewModel.refreshRecordedRoutes()
        }
        .onChange(of: selectedPhotoItems.count) { _, newCount in
            guard newCount > 0 else {
                return
            }

            let importedCount = selectedPhotoItems.count
            Task {
                await viewModel.importSelectedPhotos(selectionCount: importedCount)
                await MainActor.run {
                    selectedPhotoItems.removeAll()
                }
            }
        }
        .alert("上传结果", isPresented: Binding(
            get: { viewModel.uploadFeedbackMessage != nil },
            set: { if $0 == false { viewModel.dismissUploadFeedback() } }
        )) {
            Button("知道了", role: .cancel) {
                viewModel.dismissUploadFeedback()
            }
        } message: {
            Text(viewModel.uploadFeedbackMessage ?? "")
        }
    }

    /// Builds a compact headline-style stat line so the metric reads first without breaking the quiet visual tone.
    private func statLine(prefix: String, value: Int, suffix: String) -> some View {
        (
            Text(prefix)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.78))
            + Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            + Text(suffix)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.78))
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: AppDependencies.live().makeHomeViewModel())
    }
}
