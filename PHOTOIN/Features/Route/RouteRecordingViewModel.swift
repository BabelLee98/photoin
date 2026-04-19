//
//  RouteRecordingViewModel.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class RouteRecordingViewModel {
    enum PermissionState: Equatable {
        case unknown
        case ready
        case denied
    }

    var route: HikeRoute = .empty
    var latestSample: HikeLocationSample?
    var permissionState: PermissionState = .unknown
    var infoMessage = "点击开始后会记录徒步路线，你也可以在途中手动添加记录点。"
    var locationErrorMessage: String?

    private let locationTracker: any HikeLocationTracking
    private let recordingService: HikeRouteRecordingService
    private var trackingTask: Task<Void, Never>?

    init(
        locationTracker: any HikeLocationTracking,
        recordingService: HikeRouteRecordingService
    ) {
        self.locationTracker = locationTracker
        self.recordingService = recordingService
        updatePermissionState(from: locationTracker.authorizationStatus())
    }

    /// Keeps the permission banner aligned with the latest Core Location state.
    func refreshPermissionState() {
        updatePermissionState(from: locationTracker.authorizationStatus())
    }

    /// Starts or stops the current hike depending on the existing recording state.
    func toggleRecording() {
        route.isRecording ? stopRecording() : startRecording()
    }

    /// Adds a manual checkpoint at the latest known location so the user can mark a moment on the trail.
    func addCheckpoint() {
        let updatedRoute = recordingService.addCheckpoint(using: latestSample, to: route)

        guard updatedRoute != route else {
            locationErrorMessage = "还没有可用定位，稍等几秒再添加记录点。"
            return
        }

        route = updatedRoute
        infoMessage = "已添加 \(updatedRoute.checkpoints.last?.title ?? "记录点")。"
    }

    /// Clears the current one-shot error prompt after the user acknowledges it.
    func dismissLocationError() {
        locationErrorMessage = nil
    }

    /// Returns a short, human-readable distance string for the route summary card.
    func formattedDistance() -> String {
        if route.totalDistance >= 1000 {
            return String(format: "%.2f km", route.totalDistance / 1000)
        }

        return "\(Int(route.totalDistance.rounded())) m"
    }

    /// Returns a compact duration summary for the current or completed recording session.
    func formattedDuration(referenceDate: Date = .now) -> String {
        guard let startedAt = route.startedAt else {
            return "00:00"
        }

        let endDate = route.endedAt ?? referenceDate
        let duration = max(0, endDate.timeIntervalSince(startedAt))
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return String(format: "%02d:%02d", hours, minutes)
        }

        return String(format: "%02d:%02d", minutes, Int(duration) % 60)
    }

    /// Describes the current recording state for the header and control area.
    func statusText() -> String {
        switch permissionState {
        case .denied:
            return "需要开启定位权限后才能记录路线。"
        case .unknown:
            return route.isRecording ? "正在等待定位权限或首个定位点。" : "点击开始后即可记录徒步路线。"
        case .ready:
            return route.isRecording ? "正在记录路线，可随时添加记录点。" : "准备就绪，点击开始即可追踪徒步路线。"
        }
    }

    /// Drives the main CTA title so the button always reflects the next available action.
    func primaryActionTitle() -> String {
        route.isRecording ? "结束记录" : "开始记录"
    }

    /// Indicates whether the checkpoint control should be enabled.
    func canAddCheckpoint() -> Bool {
        route.isRecording && latestSample != nil
    }

    /// Indicates whether the current route already contains content worth showing on the map.
    func hasRecordedContent() -> Bool {
        route.points.isEmpty == false || route.checkpoints.isEmpty == false
    }

    /// Begins a new foreground tracking session and consumes location events on the main actor.
    private func startRecording() {
        let authorizationStatus = locationTracker.authorizationStatus()
        updatePermissionState(from: authorizationStatus)

        guard authorizationStatus != .denied,
              authorizationStatus != .restricted else {
            locationErrorMessage = "定位权限未开启，请先允许 App 使用定位。"
            return
        }

        route = recordingService.startRoute()
        latestSample = nil
        infoMessage = "路线记录已开始，等待定位点接入。"
        trackingTask?.cancel()

        let stream = locationTracker.startTracking()
        trackingTask = Task { [weak self] in
            guard let self else {
                return
            }

            for await event in stream {
                self.handle(event)
            }
        }
    }

    /// Stops the active tracking task and freezes the route summary.
    private func stopRecording() {
        locationTracker.stopTracking()
        trackingTask?.cancel()
        trackingTask = nil
        route = recordingService.finishRoute(route)
        infoMessage = route.points.isEmpty ? "这次路线还没有留下有效轨迹。" : "路线记录已结束。"
    }

    /// Applies authorization and location events from the live tracker into view-friendly feature state.
    private func handle(_ event: HikeLocationTrackingEvent) {
        switch event {
        case let .authorizationChanged(status):
            updatePermissionState(from: status)
            if permissionState == .denied, route.isRecording {
                locationTracker.stopTracking()
                trackingTask?.cancel()
                trackingTask = nil
                route = route.points.isEmpty ? .empty : recordingService.finishRoute(route)
                infoMessage = "定位权限未开启，暂时无法继续记录路线。"
            }
        case let .locationUpdated(sample):
            latestSample = sample
            route = recordingService.appendLocation(sample, to: route)
            if route.points.count == 1 {
                infoMessage = "已捕捉到首个定位点，开始绘制路线。"
            }
        case let .failed(message):
            locationErrorMessage = message
        }
    }

    /// Converts Core Location authorization into the smaller feature-specific state used by the UI.
    private func updatePermissionState(from status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            permissionState = .ready
        case .denied, .restricted:
            permissionState = .denied
        case .notDetermined:
            permissionState = .unknown
        @unknown default:
            permissionState = .unknown
        }
    }
}
