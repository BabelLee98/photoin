//
//  AppDependencies.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import Foundation

struct AppDependencies {
    let travelPhotoRepository: any TravelPhotoRepository
    let hikeLocationTracker: any HikeLocationTracking
    let hikeRouteHistoryRepository: any HikeRouteHistoryRepository

    /// Builds the dependency container used by the current app target.
    static func live() -> AppDependencies {
        AppDependencies(
            travelPhotoRepository: SampleTravelPhotoRepository(),
            hikeLocationTracker: LiveHikeLocationTracker(),
            hikeRouteHistoryRepository: InMemoryHikeRouteHistoryRepository()
        )
    }

    /// Creates the home feature model with the app's current dependencies injected.
    @MainActor
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            repository: travelPhotoRepository,
            explorationService: TravelPhotoExplorationService(),
            hikeRouteHistoryRepository: hikeRouteHistoryRepository
        )
    }

    /// Creates the hiking route recording feature model with the app's live location tracker.
    @MainActor
    func makeRouteRecordingViewModel() -> RouteRecordingViewModel {
        RouteRecordingViewModel(
            locationTracker: hikeLocationTracker,
            recordingService: HikeRouteRecordingService(),
            hikeRouteHistoryRepository: hikeRouteHistoryRepository
        )
    }
}
