//
//  SampleTravelPhotoRepository.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import CoreLocation
import Foundation

final class SampleTravelPhotoRepository: TravelPhotoRepository {
    private let persistence = ImportedTravelPhotoStore()
    private var photos: [TravelPhoto] = []

    init() {
        photos = persistence.loadImportedPhotos()
    }

    /// Returns the photos imported by the user and restored from local persistence.
    func fetchTravelPhotos() async -> [TravelPhoto] {
        photos
    }

    /// Appends imported photos to the session store and persists them so the next app launch can restore the same home map state.
    func saveImportedTravelPhotos(_ photos: [TravelPhoto]) async {
        self.photos = photos + self.photos
        persistence.saveImportedPhotos(photos)
    }

    /// Removes a persisted imported photo and updates the local photo store.
    func deleteImportedTravelPhoto(id: TravelPhoto.ID) async -> Bool {
        guard photos.contains(where: { $0.id == id }) else {
            return false
        }

        photos.removeAll { $0.id == id }
        persistence.saveImportedPhotos(photos)
        return true
    }
}

private struct ImportedTravelPhotoStore {
    private struct PersistedTravelPhoto: Codable {
        let id: UUID
        let locationName: String
        let regionName: String
        let captureDate: String
        let latitude: Double
        let longitude: Double
        let previewImageData: Data?
    }

    private let fileManager = FileManager.default

    /// Loads persisted imports from Application Support so previously uploaded photos survive relaunches.
    func loadImportedPhotos() -> [TravelPhoto] {
        guard let data = try? Data(contentsOf: storageURL()),
              let persistedPhotos = try? JSONDecoder().decode([PersistedTravelPhoto].self, from: data) else {
            return []
        }

        return persistedPhotos.map {
            TravelPhoto(
                id: $0.id,
                locationName: $0.locationName,
                regionName: $0.regionName,
                captureDate: $0.captureDate,
                coordinate: .init(latitude: $0.latitude, longitude: $0.longitude),
                previewImageData: $0.previewImageData
            )
        }
    }

    /// Saves imported photos into Application Support so the home collection can be reconstructed on the next launch.
    func saveImportedPhotos(_ photos: [TravelPhoto]) {
        let persistedPhotos = photos.map {
            PersistedTravelPhoto(
                id: $0.id,
                locationName: $0.locationName,
                regionName: $0.regionName,
                captureDate: $0.captureDate,
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                previewImageData: $0.previewImageData
            )
        }

        guard let data = try? JSONEncoder().encode(persistedPhotos) else {
            return
        }

        let directoryURL = storageURL().deletingLastPathComponent()
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        try? data.write(to: storageURL(), options: .atomic)
    }

    /// Returns the single JSON file used to keep imported home photos between launches.
    private func storageURL() -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("PHOTOIN", isDirectory: true)
            .appendingPathComponent("imported_travel_photos.json")
    }
}
