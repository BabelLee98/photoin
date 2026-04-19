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
                title: "Alpha",
                locationName: "Seoul",
                regionName: "Korea",
                captureDate: "2026.04.01",
                coordinate: .init(latitude: 37.5665, longitude: 126.9780)
            ),
            TravelPhoto(
                title: "Beta",
                locationName: "Busan",
                regionName: "Korea",
                captureDate: "2026.04.02",
                coordinate: .init(latitude: 35.1796, longitude: 129.0756)
            )
        ]
        let viewModel = HomeViewModel(
            repository: MockTravelPhotoRepository(photos: photos),
            explorationService: TravelPhotoExplorationService()
        )

        await viewModel.loadPhotosIfNeeded()

        #expect(viewModel.featuredPhoto?.id == photos.first?.id)
    }

    @Test func selectingMapMarkerUpdatesFeaturedPhoto() async throws {
        let photos = [
            TravelPhoto(
                title: "Alpha",
                locationName: "Seoul",
                regionName: "Korea",
                captureDate: "2026.04.01",
                coordinate: .init(latitude: 37.5665, longitude: 126.9780)
            ),
            TravelPhoto(
                title: "Beta",
                locationName: "Busan",
                regionName: "Korea",
                captureDate: "2026.04.02",
                coordinate: .init(latitude: 35.1796, longitude: 129.0756)
            )
        ]
        let viewModel = HomeViewModel(
            repository: MockTravelPhotoRepository(photos: photos),
            explorationService: TravelPhotoExplorationService()
        )

        await viewModel.loadPhotosIfNeeded()
        viewModel.selectPhoto(id: photos[1].id)

        #expect(viewModel.featuredPhoto?.id == photos[1].id)
    }
}

private struct MockTravelPhotoRepository: TravelPhotoRepository {
    let photos: [TravelPhoto]

    /// Returns a predictable photo list for HomeViewModel tests.
    func fetchTravelPhotos() async -> [TravelPhoto] {
        photos
    }
}
