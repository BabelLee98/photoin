//
//  RouteRecordingView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import MapKit
import SwiftUI

struct RouteRecordingView: View {
    @State private var viewModel: RouteRecordingViewModel
    @State private var mapType: MKMapType = .mutedStandard

    init(viewModel: RouteRecordingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            HikeRouteMapView(
                route: viewModel.route,
                latestSample: viewModel.latestSample,
                mapType: mapType,
                showsUserLocation: viewModel.permissionState != .denied
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.28),
                    Color.clear,
                    Color.black.opacity(0.24)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                topOverlay

                HStack(alignment: .firstTextBaseline, spacing: 22) {
                    floatingMetricText(title: "距离", value: viewModel.formattedDistance())
                    floatingMetricText(title: "时长", value: viewModel.formattedDuration())
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)

                HStack(spacing: 10) {
                    floatingMetaText(title: "类型", value: "徒步")
                    floatingMetaText(title: "记录点", value: "\(viewModel.route.checkpoints.count)")
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)

                Spacer()

                bottomOverlay
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            viewModel.refreshPermissionState()
            viewModel.prepareLocationPreview()
        }
        .onDisappear {
            viewModel.suspendLocationPreviewIfNeeded()
        }
        .alert("定位记录暂不可用", isPresented: Binding(
            get: { viewModel.locationErrorMessage != nil },
            set: { if $0 == false { viewModel.dismissLocationError() } }
        )) {
            Button("知道了", role: .cancel) {
                viewModel.dismissLocationError()
            }
        } message: {
            Text(viewModel.locationErrorMessage ?? "请稍后再试。")
        }
    }

    /// Builds the top floating card so type selection and status stay visible without stealing map space.
    private var topOverlay: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("徒步模式")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.white)

                    Text(viewModel.statusText())
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.84))
                }

                Spacer(minLength: 0)

                Button {
                    toggleMapType()
                } label: {
                    HStack(spacing: 6) {
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
            }

        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    /// Builds the bottom floating control card so route actions remain accessible over the full-screen map.
    private var bottomOverlay: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.infoMessage)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.84))

            if let lastCheckpoint = viewModel.route.checkpoints.last {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最近记录点")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.68))

                    Text("\(lastCheckpoint.title) · \(formattedTime(lastCheckpoint.timestamp))")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.white)

                    Text(formattedCoordinate(lastCheckpoint.coordinate))
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.74))
                }
            }

            HStack(spacing: 12) {
                Button(viewModel.primaryActionTitle()) {
                    viewModel.toggleRecording()
                }
                .buttonStyle(RoutePrimaryButtonStyle(isRecording: viewModel.route.isRecording))

                Button("添加定位") {
                    viewModel.addCheckpoint()
                }
                .buttonStyle(RouteSecondaryButtonStyle())
                .disabled(viewModel.canAddCheckpoint() == false)
                .opacity(viewModel.canAddCheckpoint() ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 22)
    }

    /// Renders the prominent floating route metrics without enclosing cards so the map stays visually open.
    private func floatingMetricText(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
        }
    }

    /// Renders lightweight metadata copy directly over the map instead of using pill-shaped containers.
    private func floatingMetaText(title: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.62))

            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.white)
        }
    }

    /// Formats a checkpoint timestamp into a compact clock string for the list.
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    /// Formats coordinates into a compact string for lightweight checkpoint summaries.
    private func formattedCoordinate(_ coordinate: HikeCoordinate) -> String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    /// Toggles the route map between the quiet standard base and the photographic hybrid layer.
    private func toggleMapType() {
        mapType = mapType == .mutedStandard ? .hybrid : .mutedStandard
    }
}

private struct RoutePrimaryButtonStyle: ButtonStyle {
    let isRecording: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isRecording ? Color.white.opacity(0.34) : Color.white.opacity(0.22),
                        lineWidth: 1
                    )
            }
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

private struct RouteSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

#Preview {
    NavigationStack {
        RouteRecordingView(viewModel: AppDependencies.live().makeRouteRecordingViewModel())
    }
}
