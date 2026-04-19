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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("徒步路线")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.2))

                    Text(viewModel.statusText())
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(Color(red: 0.38, green: 0.42, blue: 0.44))
                }

                HikeRouteMapView(
                    route: viewModel.route,
                    latestSample: viewModel.latestSample,
                    showsUserLocation: viewModel.permissionState == .ready
                )
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text(viewModel.infoMessage)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Color(red: 0.33, green: 0.37, blue: 0.39))

                    HStack(spacing: 12) {
                        metricCard(title: "距离", value: viewModel.formattedDistance())
                        metricCard(title: "时长", value: viewModel.formattedDuration())
                        metricCard(title: "记录点", value: "\(viewModel.route.checkpoints.count)")
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
                .padding(20)
                .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("途中记录点")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.2))

                    if viewModel.route.checkpoints.isEmpty {
                        Text("开始记录后，可以在途中手动打一个记录点，方便回看停留位置。")
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .foregroundStyle(Color(red: 0.4, green: 0.44, blue: 0.46))
                    } else {
                        ForEach(viewModel.route.checkpoints) { checkpoint in
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color(red: 0.37, green: 0.43, blue: 0.46))
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(checkpoint.title)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.2))

                                    Text("\(formattedCoordinate(checkpoint.coordinate)) · \(formattedTime(checkpoint.timestamp))")
                                        .font(.system(.footnote, design: .rounded, weight: .medium))
                                        .foregroundStyle(Color(red: 0.42, green: 0.46, blue: 0.48))
                                }

                                Spacer(minLength: 0)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.94),
                    Color(red: 0.89, green: 0.9, blue: 0.89)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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

    /// Renders a compact metric card used in the route summary area.
    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(Color(red: 0.43, green: 0.47, blue: 0.49))

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(red: 0.15, green: 0.18, blue: 0.2))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(red: 0.93, green: 0.93, blue: 0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
