//
//  HomeView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import PhotosUI
import MapKit
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var isBottomPanelExpanded = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var mapType: MKMapType = .mutedStandard

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            TravelPhotoMapView(
                photos: viewModel.filteredPhotos,
                mapType: mapType,
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

                    Spacer(minLength: 12)

                    Button {
                        toggleMapType()
                    } label: {
                        HStack(spacing: 0) {
                            Image(systemName: mapType == .mutedStandard ? "square.2.layers.3d.top.filled" : "map")
                                .font(.system(size: 15, weight: .semibold))
                            Text(mapType == .mutedStandard ? "影像" : "地图")
                                .font(.system(.footnote, design: .rounded, weight: .semibold))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("切换地图样式")
                    .accessibilityHint("在普通地图和影像地图之间切换")
                    .padding(.top, -4)
                }
                .padding(.top, -4)
                .padding(.horizontal, 16)

                Spacer()

                HStack(alignment: .bottom, spacing: 0) {
                    HomeBottomSheetView(
                        featuredPhoto: viewModel.featuredPhoto,
                        relatedPhotos: relatedPhotosForCurrentLocation(),
                        locationCount: viewModel.filteredPhotos.count,
                        isExpanded: $isBottomPanelExpanded
                    )
                    .frame(maxWidth: isBottomPanelExpanded ? 312 : 278, alignment: .leading)
                    .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isBottomPanelExpanded)

                    Spacer(minLength: 88)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 22)
                .zIndex(2)
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
            .zIndex(1)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadPhotosIfNeeded()
        }
        .onAppear {
            viewModel.refreshRecordedRoutes()
            Task {
                await viewModel.reloadPhotos()
            }
        }
        .onChange(of: selectedPhotoItems.count) { _, newCount in
            guard newCount > 0 else {
                return
            }

            let itemsToImport = selectedPhotoItems
            Task {
                let importedItems = await loadSelectedImportItems(from: itemsToImport)
                await viewModel.importSelectedPhotos(importedItems)
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

    /// Loads both image payloads and stable asset identifiers so the importer can resolve real photo metadata.
    private func loadSelectedImportItems(from items: [PhotosPickerItem]) async -> [TravelPhotoImportItem] {
        var importedItems: [TravelPhotoImportItem] = []

        for item in items {
            guard let imageData = try? await item.loadTransferable(type: Data.self) else {
                continue
            }

            importedItems.append(
                TravelPhotoImportItem(
                    imageData: imageData,
                    assetIdentifier: item.itemIdentifier
                )
            )
        }

        return importedItems
    }

    /// Toggles the home map between the quiet default style and a more photographic hybrid base layer.
    private func toggleMapType() {
        mapType = mapType == .mutedStandard ? .hybrid : .mutedStandard
    }

    /// Returns every currently filtered photo that belongs to the selected location so the bottom sheet can show a swipeable gallery.
    private func relatedPhotosForCurrentLocation() -> [TravelPhoto] {
        guard let featuredPhoto = viewModel.featuredPhoto else {
            return []
        }

        return viewModel.filteredPhotos.filter {
            $0.locationName == featuredPhoto.locationName &&
            $0.regionName == featuredPhoto.regionName
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: AppDependencies.live().makeHomeViewModel())
    }
}
