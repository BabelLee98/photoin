//
//  TravelPhotoExplorationServiceTests.swift
//  PHOTOINTests
//
//  Created by Codex on 2026/4/6.
//

import CoreLocation
import Testing
@testable import PHOTOIN

struct TravelPhotoExplorationServiceTests {
    private let service = TravelPhotoExplorationService()

    @Test func searchMatchesLocationAndRegionCaseInsensitively() async throws {
        let results = service.filteredPhotos(from: samplePhotos, query: "hall")

        #expect(results.count == 1)
        #expect(results.first?.locationName == "Hallstatt")
    }

    @Test func emptySearchReturnsAllPhotos() async throws {
        let results = service.filteredPhotos(from: samplePhotos, query: "   ")

        #expect(results.count == samplePhotos.count)
    }

    @Test func featuredPhotoPrefersFrontFacingMarker() async throws {
        let results = [
            TravelPhoto(
                title: "Front",
                locationName: "Front",
                regionName: "Test",
                captureDate: "2026.01.01",
                coordinate: .init(latitude: 0, longitude: 0)
            ),
            TravelPhoto(
                title: "Back",
                locationName: "Back",
                regionName: "Test",
                captureDate: "2026.01.01",
                coordinate: .init(latitude: 0, longitude: 180)
            )
        ]

        let featured = service.featuredPhoto(from: results, rotation: 0)

        #expect(featured?.title == "Front")
    }

    private var samplePhotos: [TravelPhoto] {
        [
            TravelPhoto(
                title: "清晨的海岬",
                locationName: "Cape Reinga",
                regionName: "新西兰",
                captureDate: "2026.01.14",
                coordinate: CLLocationCoordinate2D(latitude: -34.4308, longitude: 172.6806)
            ),
            TravelPhoto(
                title: "雪原终点站",
                locationName: "Hallstatt",
                regionName: "奥地利",
                captureDate: "2025.12.21",
                coordinate: CLLocationCoordinate2D(latitude: 47.5622, longitude: 13.6493)
            )
        ]
    }
}
