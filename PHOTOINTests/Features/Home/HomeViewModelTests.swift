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
            hikeRouteHistoryRepository: MockHikeRouteHistoryRepository(routes: []),
            travelPhotoImporter: MockTravelPhotoImporter()
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
            hikeRouteHistoryRepository: MockHikeRouteHistoryRepository(routes: []),
            travelPhotoImporter: MockTravelPhotoImporter()
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
            ),
            travelPhotoImporter: MockTravelPhotoImporter()
        )

        await viewModel.loadPhotosIfNeeded()

        #expect(viewModel.totalVisitedCityCount == 3)
        #expect(viewModel.totalClimbedMountainCount == 1)
        #expect(viewModel.totalHikeCount == 1)
        #expect(viewModel.totalPhotoCount == 3)
    }

    @Test func importingPhotosRefreshesHomeCollectionAndFeedback() async throws {
        let repository = MockTravelPhotoRepository(
            photos: [
                TravelPhoto(
                    locationName: "Seoul",
                    regionName: "Korea",
                    captureDate: "2026.04.01",
                    coordinate: .init(latitude: 37.5665, longitude: 126.9780)
                )
            ]
        )
        let importedPhotos = [
            TravelPhoto(
                locationName: "待整理地点 2",
                regionName: "未定位",
                captureDate: "2026.04.26",
                coordinate: .init(latitude: 39.9042, longitude: 116.4074)
            ),
            TravelPhoto(
                locationName: "待整理地点 3",
                regionName: "未定位",
                captureDate: "2026.04.26",
                coordinate: .init(latitude: 39.9222, longitude: 116.4254)
            )
        ]
        let viewModel = HomeViewModel(
            repository: repository,
            explorationService: TravelPhotoExplorationService(),
            hikeRouteHistoryRepository: MockHikeRouteHistoryRepository(routes: []),
            travelPhotoImporter: MockTravelPhotoImporter(importedPhotos: importedPhotos)
        )

        await viewModel.loadPhotosIfNeeded()
        await viewModel.importSelectedPhotos([
            TravelPhotoImportItem(imageData: Data([0x01]), assetIdentifier: "asset-1"),
            TravelPhotoImportItem(imageData: Data([0x02]), assetIdentifier: "asset-2")
        ])

        #expect(viewModel.totalPhotoCount == 3)
        #expect(viewModel.featuredPhoto?.id == importedPhotos.first?.id)
        #expect(viewModel.uploadFeedbackMessage == "已导入 2 张照片。")
    }

    @Test func importingPhotosAtSameLocationKeepsBothPhotos() async throws {
        let existingPhoto = TravelPhoto(
            locationName: "上海外滩",
            regionName: "中国",
            captureDate: "2026.04.01",
            coordinate: .init(latitude: 31.2400, longitude: 121.4900)
        )
        let importedPhoto = TravelPhoto(
            locationName: "上海外滩",
            regionName: "中国",
            captureDate: "2026.04.02",
            coordinate: .init(latitude: 31.2400, longitude: 121.4900)
        )
        let viewModel = HomeViewModel(
            repository: MockTravelPhotoRepository(photos: [existingPhoto]),
            explorationService: TravelPhotoExplorationService(),
            hikeRouteHistoryRepository: MockHikeRouteHistoryRepository(routes: []),
            travelPhotoImporter: MockTravelPhotoImporter(importedPhotos: [importedPhoto])
        )

        await viewModel.loadPhotosIfNeeded()
        await viewModel.importSelectedPhotos([TravelPhotoImportItem(imageData: Data([0x03]), assetIdentifier: "asset-3")])

        #expect(viewModel.totalPhotoCount == 2)
        #expect(viewModel.filteredPhotos.filter { $0.locationName == "上海外滩" }.count == 2)
    }
}

@MainActor
private final class MockTravelPhotoRepository: TravelPhotoRepository {
    private var photos: [TravelPhoto]

    init(photos: [TravelPhoto]) {
        self.photos = photos
    }

    /// Returns a predictable photo list for HomeViewModel tests.
    func fetchTravelPhotos() async -> [TravelPhoto] {
        photos
    }

    /// Stores imported photos in front of the existing list so tests can assert immediate home refresh behavior.
    func saveImportedTravelPhotos(_ photos: [TravelPhoto]) async {
        self.photos = photos + self.photos
    }

    /// Removes a photo from the mock repository when tests need to simulate user-deleted imports.
    func deleteImportedTravelPhoto(id: TravelPhoto.ID) async -> Bool {
        guard photos.contains(where: { $0.id == id }) else {
            return false
        }

        photos.removeAll { $0.id == id }
        return true
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

private struct MockTravelPhotoImporter: TravelPhotoImporting {
    let importedPhotos: [TravelPhoto]

    init(importedPhotos: [TravelPhoto] = []) {
        self.importedPhotos = importedPhotos
    }

    /// Returns a deterministic imported collection so tests can validate the home upload flow.
    func importTravelPhotos(from items: [TravelPhotoImportItem], startingAt existingPhotoCount: Int) async throws -> [TravelPhoto] {
        importedPhotos
    }
}
