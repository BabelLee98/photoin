//
//  RouteRecordingView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import SwiftUI

struct RouteRecordingView: View {
    @State private var viewModel: RouteRecordingViewModel

    init(viewModel: RouteRecordingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            HikeRouteMapView(
                route: viewModel.route,
                latestSample: viewModel.latestSample,
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

            VStack(spacing: 14) {
                topOverlay

                HStack(spacing: 12) {
                    floatingMetricCard(title: "距离", value: viewModel.formattedDistance())
                    floatingMetricCard(title: "时长", value: viewModel.formattedDuration())
                }
                .padding(.horizontal, 16)

                HStack(spacing: 10) {
                    floatingMetaPill(title: "类型", value: currentActivityType.displayName)
                    floatingMetaPill(title: "记录点", value: "\(viewModel.route.checkpoints.count)")
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
            VStack(alignment: .leading, spacing: 8) {
                Text("徒步路线")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.white)

                Text(viewModel.statusText())
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.84))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("记录类型")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.72))

                Picker(
                    "记录类型",
                    selection: Binding(
                        get: { viewModel.selectedActivityType },
                        set: { viewModel.updateSelectedActivityType($0) }
                    )
                ) {
                    ForEach(HikeRoute.ActivityType.allCases) { activityType in
                        Text(activityType.displayName).tag(activityType)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
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

                Button("添加记录点") {
                    viewModel.addCheckpoint()
                }
                .buttonStyle(RouteSecondaryButtonStyle())
                .disabled(viewModel.canAddCheckpoint() == false)
                .opacity(viewModel.canAddCheckpoint() ? 1 : 0.5)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 22)
    }

    /// Returns the currently active route type, or the next selected type before recording starts.
    private var currentActivityType: HikeRoute.ActivityType {
        viewModel.route.isRecording ? viewModel.route.activityType : viewModel.selectedActivityType
    }

    /// Renders the prominent floating metric cards used for timing and distance on top of the map.
    private func floatingMetricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }

    /// Renders a smaller metadata pill so route type and checkpoint count stay visible but lightweight.
    private func floatingMetaPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.62))

            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
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
                isRecording
                ? Color(red: 0.24, green: 0.28, blue: 0.31)
                : Color(red: 0.18, green: 0.22, blue: 0.24),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

private struct RouteSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(Color(red: 0.2, green: 0.24, blue: 0.26))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.68), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

#Preview {
    NavigationStack {
        RouteRecordingView(viewModel: AppDependencies.live().makeRouteRecordingViewModel())
    }
}
