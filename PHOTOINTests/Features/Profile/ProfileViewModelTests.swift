//
//  ProfileViewModelTests.swift
//  PHOTOINTests
//
//  Created by Codex on 2026/6/14.
//

import CoreLocation
import Foundation
import Testing
@testable import PHOTOIN

@MainActor
struct ProfileViewModelTests {
    @Test func groupedLocationsMergePhotosFromSamePlace() async throws {
        let photos = [
            TravelPhoto(
                locationName: "东京塔",
                regionName: "东京 · 日本",
                captureDate: "2026.06.14",
                coordinate: CLLocationCoordinate2D(latitude: 35.6586, longitude: 139.7454)
            ),
            TravelPhoto(
                locationName: "东京塔",
                regionName: "东京 · 日本",
                captureDate: "2026.06.12",
                coordinate: CLLocationCoordinate2D(latitude: 35.6586, longitude: 139.7454)
            ),
            TravelPhoto(
                locationName: "南山首尔塔",
                regionName: "首尔 · 韩国",
                captureDate: "2026.06.11",
                coordinate: CLLocationCoordinate2D(latitude: 37.5512, longitude: 126.9882)
            )
        ]
        let viewModel = ProfileViewModel(
            travelPhotoRepository: MockProfileTravelPhotoRepository(photos: photos),
            hikeRouteHistoryRepository: MockProfileRouteHistoryRepository(routes: [])
        )

        await viewModel.reloadContent()

        #expect(viewModel.groupedLocations.count == 2)
        #expect(viewModel.groupedLocations.first?.locationName == "东京塔")
        #expect(viewModel.groupedLocations.first?.photoCount == 2)
        #expect(viewModel.groupedLocations.first?.latestCaptureDate == "2026.06.14")
    }

    @Test func exportDocumentIsGeneratedWhenContentExists() async throws {
        let routes = [
            HikeRoute(
                activityType: .hike,
                startedAt: Date(timeIntervalSince1970: 1_000),
                endedAt: Date(timeIntervalSince1970: 1_600),
                points: [],
                checkpoints: [],
                totalDistance: 1_240
            )
        ]
        let viewModel = ProfileViewModel(
            travelPhotoRepository: MockProfileTravelPhotoRepository(
                photos: [
                    TravelPhoto(
                        locationName: "Hallstatt",
                        regionName: "Austria",
                        captureDate: "2026.06.01",
                        coordinate: CLLocationCoordinate2D(latitude: 47.5622, longitude: 13.6493)
                    )
                ]
            ),
            hikeRouteHistoryRepository: MockProfileRouteHistoryRepository(routes: routes)
        )

        await viewModel.prepareExportDocument()

        #expect(viewModel.exportDocument != nil)
        #expect(viewModel.exportErrorMessage == nil)
    }
}

@MainActor
private final class MockProfileTravelPhotoRepository: TravelPhotoRepository {
    private var photos: [TravelPhoto]

    init(photos: [TravelPhoto]) {
        self.photos = photos
    }

    /// Returns a stable in-memory photo list for profile feature tests.
    func fetchTravelPhotos() async -> [TravelPhoto] {
        photos
    }

    /// Stores imported photos at the beginning of the mock list so feature tests can simulate refresh behavior.
    func saveImportedTravelPhotos(_ photos: [TravelPhoto]) async {
        self.photos = photos + self.photos
    }
}

@MainActor
private final class MockProfileRouteHistoryRepository: HikeRouteHistoryRepository {
    private var routes: [HikeRoute]

    init(routes: [HikeRoute]) {
        self.routes = routes
    }

    /// Returns a stable in-memory route history for profile feature tests.
    func fetchRecordedRoutes() -> [HikeRoute] {
        routes
    }

    /// Stores completed routes in-memory so tests can mimic the shared route history behavior.
    func saveRecordedRoute(_ route: HikeRoute) {
        routes.insert(route, at: 0)
    }
}
