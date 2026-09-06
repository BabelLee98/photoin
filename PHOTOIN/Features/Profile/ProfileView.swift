//
//  ProfileView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import Photos
import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
    @State private var viewModel: ProfileViewModel
    @State private var isExporting = false

    init(viewModel: ProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("我的")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.2))

                    Text("这里会集中展示你导入的照片、打卡地点、徒步记录和当前权限状态。")
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))

                    HStack(spacing: 12) {
                        ProfileSummaryChip(title: "照片", value: "\(viewModel.totalPhotoCount)")
                        ProfileSummaryChip(title: "地点", value: "\(viewModel.totalLocationCount)")
                        ProfileSummaryChip(title: "路线", value: "\(viewModel.totalRouteCount)")
                    }
                    .padding(.top, 6)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section("内容") {
                NavigationLink {
                    ProfilePhotoLibraryView(
                        photos: viewModel.photos,
                        onDeleteConfirmed: deleteImportedPhoto
                    )
                } label: {
                    Label("全部照片", systemImage: "photo.on.rectangle.angled")
                }

                NavigationLink {
                    ProfileLocationGroupsView(locationGroups: viewModel.groupedLocations)
                } label: {
                    Label("打卡地点", systemImage: "mappin.and.ellipse")
                }

                NavigationLink {
                    ProfileRouteHistoryView(routes: viewModel.routes)
                } label: {
                    Label("旅行足迹", systemImage: "point.3.connected.trianglepath.dotted")
                }
            }

            Section("设置") {
                NavigationLink {
                    ProfileNotificationSettingsView(
                    )
                } label: {
                    Label("通知与提醒", systemImage: "bell.badge")
                }

                NavigationLink {
                    ProfilePrivacyPermissionsView(
                        photoPermissionSummary: viewModel.photoPermissionSummary,
                        locationPermissionSummary: viewModel.locationPermissionSummary,
                        openSettingsAction: openSystemSettings
                    )
                } label: {
                    Label("隐私与权限", systemImage: "hand.raised")
                }

                NavigationLink {
                    ProfileExportBackupView(
                        photoCount: viewModel.totalPhotoCount,
                        routeCount: viewModel.totalRouteCount,
                        onExport: {
                            Task {
                                await viewModel.prepareExportDocument()
                                if viewModel.exportDocument != nil {
                                    isExporting = true
                                }
                            }
                        }
                    )
                } label: {
                    Label("导出与备份", systemImage: "externaldrive")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.94, green: 0.95, blue: 0.93))
        .navigationTitle("")
        .task {
            await viewModel.loadContentIfNeeded()
        }
        .onAppear {
            Task {
                await viewModel.reloadContent()
            }
        }
        .alert("导出提示", isPresented: Binding(
            get: { viewModel.exportErrorMessage != nil },
            set: { if $0 == false { viewModel.dismissExportError() } }
        )) {
            Button("知道了", role: .cancel) {
                viewModel.dismissExportError()
            }
        } message: {
            Text(viewModel.exportErrorMessage ?? "")
        }
        .alert("删除提示", isPresented: Binding(
            get: { viewModel.deleteFeedbackMessage != nil },
            set: { if $0 == false { viewModel.dismissDeleteFeedback() } }
        )) {
            Button("知道了", role: .cancel) {
                viewModel.dismissDeleteFeedback()
            }
        } message: {
            Text(viewModel.deleteFeedbackMessage ?? "")
        }
        .fileExporter(
            isPresented: $isExporting,
            document: viewModel.exportDocument,
            contentType: .json,
            defaultFilename: viewModel.exportDocument?.fileName ?? "PHOTOIN-Backup.json"
        ) { _ in
            viewModel.clearExportDocument()
        }
    }

    /// Opens the app's Settings screen so the user can change photo and location permissions directly.
    private func openSystemSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }

    /// Deletes a confirmed imported photo from the shared repository used by profile and home.
    private func deleteImportedPhoto(_ photo: TravelPhoto) {
        let photoID = photo.id
        Task {
            await viewModel.deleteImportedPhoto(id: photoID)
        }
    }
}

private struct ProfileSummaryChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(Color(red: 0.18, green: 0.21, blue: 0.24))

            Text(title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ProfilePhotoLibraryView: View {
    let photos: [TravelPhoto]
    let onDeleteConfirmed: (TravelPhoto) -> Void
    @State private var photoPendingDeletion: TravelPhoto?
    @State private var isShowingDeleteConfirmation = false
    private let columns = [GridItem(.adaptive(minimum: 144), spacing: 12)]

    var body: some View {
        ScrollView {
            if photos.isEmpty {
                ProfileEmptyStateView(
                    title: "还没有照片",
                    description: "先回到首页导入照片，这里就会按时间顺序汇总展示。"
                )
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(photos) { photo in
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack(alignment: .topTrailing) {
                                ProfilePhotoThumbnail(photo: photo)
                                    .frame(height: 142)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                                if photo.previewImageData != nil {
                                    Button("删除照片", systemImage: "trash", action: { requestPhotoDeletion(photo) })
                                        .labelStyle(.iconOnly)
                                        .font(.system(.caption, design: .rounded, weight: .bold))
                                        .foregroundStyle(Color.white)
                                        .frame(width: 34, height: 34)
                                        .background(.ultraThinMaterial, in: Circle())
                                        .overlay {
                                            Circle()
                                                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                                        }
                                        .padding(8)
                                        .accessibilityHint("从 PHOTOIN 的导入记录中删除这张照片")
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(photo.locationName)
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.2))
                                    .lineLimit(2)

                                Text(photo.regionName)
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))

                                Text(photo.captureDate)
                                    .font(.system(.caption2, design: .rounded, weight: .medium))
                                    .foregroundStyle(Color(red: 0.5, green: 0.54, blue: 0.56))
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                }
                .padding(16)
            }
        }
        .background(Color(red: 0.94, green: 0.95, blue: 0.93))
        .navigationTitle("全部照片")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "删除这张照片？",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除照片", role: .destructive, action: deletePendingPhoto)
            Button("取消", role: .cancel, action: clearPendingDeletion)
        } message: {
            Text("这会从 PHOTOIN 的导入记录中移除照片，不会删除系统相册里的原图。")
        }
    }

    /// Stores the selected imported photo inside this gallery so the confirmation appears on the current screen.
    private func requestPhotoDeletion(_ photo: TravelPhoto) {
        photoPendingDeletion = photo
        isShowingDeleteConfirmation = true
    }

    /// Sends the confirmed photo back to the parent view for repository deletion.
    private func deletePendingPhoto() {
        guard let photoPendingDeletion else {
            return
        }

        onDeleteConfirmed(photoPendingDeletion)
        clearPendingDeletion()
    }

    /// Clears the transient delete selection used by the gallery confirmation dialog.
    private func clearPendingDeletion() {
        photoPendingDeletion = nil
        isShowingDeleteConfirmation = false
    }
}

private struct ProfileLocationGroupsView: View {
    let locationGroups: [ProfileViewModel.LocationGroup]

    var body: some View {
        List {
            if locationGroups.isEmpty {
                ProfileEmptyStateView(
                    title: "还没有打卡地点",
                    description: "导入带有地点信息的照片后，这里会自动聚合你的拍摄地点、日期和数量。"
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(locationGroups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.locationName)
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.2))

                                Text(group.regionName)
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))
                            }

                            Spacer()

                            Text("\(group.photoCount) 张")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(Color(red: 0.22, green: 0.28, blue: 0.31))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.72), in: Capsule())
                        }

                        Text("最近拍摄：\(group.latestCaptureDate)")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(Color(red: 0.5, green: 0.54, blue: 0.56))

                        Text(String(format: "坐标 %.4f, %.4f", group.coordinate.latitude, group.coordinate.longitude))
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(Color(red: 0.56, green: 0.6, blue: 0.62))
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.white.opacity(0.72))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.94, green: 0.95, blue: 0.93))
        .navigationTitle("打卡地点")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileRouteHistoryView: View {
    let routes: [HikeRoute]

    var body: some View {
        List {
            if routes.isEmpty {
                ProfileEmptyStateView(
                    title: "还没有路线记录",
                    description: "去第二页开始记录徒步路线，完成后这里会自动收集你的足迹。"
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(routes, id: \.id) { route in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(route.activityType.displayName)
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.2))

                            Spacer()

                            Text(formattedDistance(for: route))
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(Color(red: 0.22, green: 0.28, blue: 0.31))
                        }

                        Text(formattedDateRange(for: route))
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))

                        Text("轨迹点 \(route.points.count) 个 · 记录点 \(route.checkpoints.count) 个")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(Color(red: 0.5, green: 0.54, blue: 0.56))
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.white.opacity(0.72))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.94, green: 0.95, blue: 0.93))
        .navigationTitle("旅行足迹")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Formats the stored route distance in either meters or kilometers depending on scale.
    private func formattedDistance(for route: HikeRoute) -> String {
        if route.totalDistance >= 1000 {
            return String(format: "%.2f km", route.totalDistance / 1000)
        }

        return "\(Int(route.totalDistance.rounded())) m"
    }

    /// Formats a concise date span for a completed hiking route.
    private func formattedDateRange(for route: HikeRoute) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"

        let start = route.startedAt.map(formatter.string(from:)) ?? "未开始"
        let end = route.endedAt.map(formatter.string(from:)) ?? "进行中"
        return "\(start) - \(end)"
    }
}

private struct ProfileNotificationSettingsView: View {
    @AppStorage("profile.notifications.photoReminders") private var photoReminderEnabled = true
    @AppStorage("profile.notifications.routeReminders") private var routeReminderEnabled = true
    @AppStorage("profile.notifications.weeklyReview") private var weeklyReviewEnabled = false

    var body: some View {
        List {
            Toggle("照片整理提醒", isOn: $photoReminderEnabled)
            Toggle("路线完成提醒", isOn: $routeReminderEnabled)
            Toggle("每周旅行回顾", isOn: $weeklyReviewEnabled)
        }
        .navigationTitle("通知与提醒")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfilePrivacyPermissionsView: View {
    let photoPermissionSummary: String
    let locationPermissionSummary: String
    let openSettingsAction: () -> Void

    var body: some View {
        List {
            Section("当前状态") {
                permissionRow(title: "照片权限", value: photoPermissionSummary)
                permissionRow(title: "定位权限", value: locationPermissionSummary)
            }

            Section {
                Button("前往系统设置") {
                    openSettingsAction()
                }
            } footer: {
                Text("如果你之前拒绝过授权，iOS 不会再次自动弹窗，需要从系统设置手动修改。")
            }
        }
        .navigationTitle("隐私与权限")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Builds a compact two-column permission row for the current app authorization state.
    private func permissionRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProfileExportBackupView: View {
    let photoCount: Int
    let routeCount: Int
    let onExport: () -> Void

    var body: some View {
        List {
            Section("当前备份范围") {
                HStack {
                    Text("照片记录")
                    Spacer()
                    Text("\(photoCount) 条")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("路线记录")
                    Spacer()
                    Text("\(routeCount) 条")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("导出 JSON 备份") {
                    onExport()
                }
            } footer: {
                Text("会导出照片地点、拍摄日期和路线摘要，方便你先做本地备份。")
            }
        }
        .navigationTitle("导出与备份")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileEmptyStateView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.2))

            Text(description)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ProfilePhotoThumbnail: View {
    let photo: TravelPhoto

    var body: some View {
        if let image = previewImage(for: photo) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [
                    Color(red: 0.24, green: 0.27, blue: 0.29),
                    Color(red: 0.15, green: 0.18, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.76))
            }
        }
    }

    /// Decodes a thumbnail image from the persisted preview bytes so the profile gallery can show real imported photos.
    private func previewImage(for photo: TravelPhoto) -> UIImage? {
        guard let previewImageData = photo.previewImageData else {
            return nil
        }

        return UIImage(data: previewImageData)
    }
}

#Preview {
    NavigationStack {
        ProfileView(viewModel: AppDependencies.live().makeProfileViewModel())
    }
}
