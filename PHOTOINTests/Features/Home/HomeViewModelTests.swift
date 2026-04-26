//
//  HomeViewModelTests.swift
//  PHOTOINTests
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Testing
@testable import PHOTOIN

@MainActor
struct HomeViewModelTests {
    @Test func featuredPhotoDefaultsToFirstFilteredResultAfterLoad() async throws {
        let photos = [
            TravelPhoto(
                locationName: "Seoul",
                regionName: "Korea",
                captureDate: "2026.04.01",
                coordinate: .init(latitude: 37.5665, longitude: 126.9780)
            ),
            TravelPhoto(
                locationName: "Busan",
                regionName: "Korea",
                captureDate: "2026.04.02",
                coordinate: .init(latitude: 35.1796, longitude: 129.0756)
            )
        ]
        let viewModel = HomeViewModel(
            repository: MockTravelPhotoRepository(photos: photos),
            explorationService: TravelPhotoExplorationService(),
            hikeRouteHistoryRepository: MockHikeRouteHistoryRepository(routes: [])
        )

        await viewModel.loadPhotosIfNeeded()

        #expect(viewModel.featuredPhoto?.id == photos.first?.id)
    }

    @Test func selectingMapMarkerUpdatesFeaturedPhoto() async throws {
        let photos = [
            TravelPhoto(
                locationName: "Seoul",
                regionName: "Korea",
                captureDate: "2026.04.01",
                coordinate: .init(latitude: 37.5665, longitude: 126.9780)
            ),
            TravelPhoto(
                locationName: "Busan",
                regionName: "Korea",
                captureDate: "2026.04.02",
                coordinate: .init(latitude: 35.1796, longitude: 129.0756)
            )
        ]
        let viewModel = HomeViewModel(
            repository: MockTravelPhotoRepository(photos: photos),
            explorationService: TravelPhotoExplorationService(),
            hikeRouteHistoryRepository: MockHikeRouteHistoryRepository(routes: [])
        )

        await viewModel.loadPhotosIfNeeded()
        viewModel.selectPhoto(id: photos[1].id)

        #expect(viewModel.featuredPhoto?.id == photos[1].id)
    }

    @Test func summaryMetricsReflectAvailablePhotoData() async throws {
        let photos = [
            TravelPhoto(
                locationName: "Mount Cook",
                regionName: "New Zealand",
                captureDate: "2026.04.01",
                coordinate: .init(latitude: -43.5950, longitude: 170.1418)
            ),
            TravelPhoto(
                locationName: "Hallstatt",
                regionName: "Austria",
                captureDate: "2026.04.01",
                coordinate: .init(latitude: 47.5622, longitude: 13.6493)
            ),
            TravelPhoto(
                locationName: "Seoul",
                regionName: "Korea",
                captureDate: "2026.04.02",
                coordinate: .init(latitude: 37.5665, longitude: 126.9780)
            )
        ]
        let viewModel = HomeViewModel(
            repository: MockTravelPhotoRepository(photos: photos),
            explorationService: TravelPhotoExplorationService(),
            hikeRouteHistoryRepository: MockHikeRouteHistoryRepository(
                routes: [
                    HikeRoute(
                        activityType: .mountainClimb,
                        startedAt: Date(timeIntervalSince1970: 1_000),
                        endedAt: Date(timeIntervalSince1970: 1_200),
                        points: [],
                        checkpoints: [],
                        totalDistance: 0
                    ),
                    HikeRoute(
                        activityType: .hike,
                        startedAt: Date(timeIntervalSince1970: 2_000),
                        endedAt: Date(timeIntervalSince1970: 2_300),
                        points: [],
                        checkpoints: [],
                        totalDistance: 0
                    )
                ]
            )
        )

        await viewModel.loadPhotosIfNeeded()

        #expect(viewModel.totalVisitedCityCount == 3)
        #expect(viewModel.totalClimbedMountainCount == 1)
        #expect(viewModel.totalHikeCount == 1)
        #expect(viewModel.totalPhotoCount == 3)
    }
}

private struct MockTravelPhotoRepository: TravelPhotoRepository {
    let photos: [TravelPhoto]

    /// Returns a predictable photo list for HomeViewModel tests.
    func fetchTravelPhotos() async -> [TravelPhoto] {
        photos
    }
}

@MainActor
private final class MockHikeRouteHistoryRepository: HikeRouteHistoryRepository {
    private var routes: [HikeRoute]

    init(routes: [HikeRoute]) {
        self.routes = routes
    }

    /// Returns a stable in-memory route list for home summary assertions.
    func fetchRecordedRoutes() -> [HikeRoute] {
        routes
    }

    /// Stores a completed route in memory so tests can simulate shared history.
    func saveRecordedRoute(_ route: HikeRoute) {
        routes.insert(route, at: 0)
    }
}
