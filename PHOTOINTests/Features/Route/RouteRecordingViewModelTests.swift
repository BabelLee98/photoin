//
//  RouteRecordingViewModelTests.swift
//  PHOTOINTests
//
//  Created by Codex on 2026/4/26.
//

import CoreLocation
import Foundation
import Testing
@testable import PHOTOIN

@MainActor
struct RouteRecordingViewModelTests {
    @Test func finishedMountainRouteIsSavedIntoSharedHistory() async throws {
        let historyRepository = MockRouteHistoryRepository()
        let viewModel = RouteRecordingViewModel(
            locationTracker: MockHikeLocationTracker(),
            recordingService: HikeRouteRecordingService(),
            hikeRouteHistoryRepository: historyRepository
        )

        viewModel.updateSelectedActivityType(.mountainClimb)
        viewModel.toggleRecording()

        let sample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.2304, longitude: 121.4737),
            timestamp: Date(),
            horizontalAccuracy: 6
        )

        viewModel.latestSample = sample
        viewModel.route = HikeRouteRecordingService().appendLocation(sample, to: viewModel.route)
        viewModel.toggleRecording()

        #expect(historyRepository.fetchRecordedRoutes().count == 1)
        #expect(historyRepository.fetchRecordedRoutes().first?.activityType == .mountainClimb)
    }
}

@MainActor
private final class MockRouteHistoryRepository: HikeRouteHistoryRepository {
    private var routes: [HikeRoute] = []

    /// Returns the routes recorded during the current test execution.
    func fetchRecordedRoutes() -> [HikeRoute] {
        routes
    }

    /// Stores completed routes in-memory so the feature can share them with home summaries.
    func saveRecordedRoute(_ route: HikeRoute) {
        routes.insert(route, at: 0)
    }
}

@MainActor
private struct MockHikeLocationTracker: HikeLocationTracking {
    /// Always reports granted permissions so the feature can begin recording immediately in tests.
    func authorizationStatus() -> CLAuthorizationStatus {
        .authorizedWhenInUse
    }

    /// Returns an empty stream because these tests inject location samples manually.
    func startTracking() -> AsyncStream<HikeLocationTrackingEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    /// No-op stop used by tests that do not maintain a live tracking stream.
    func stopTracking() {}
}
