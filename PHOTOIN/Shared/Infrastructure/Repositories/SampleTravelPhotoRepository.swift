//
//  SampleTravelPhotoRepository.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import CoreLocation
import Foundation

final class SampleTravelPhotoRepository: TravelPhotoRepository {
    private static let currentPlaceSummaryVersion = 2

    private let persistence = ImportedTravelPhotoStore()
    private let placeSummaryResolver = PhotoPlaceSummaryResolver()
    private var photos: [TravelPhoto] = []
    private var placeSummaryVersions: [TravelPhoto.ID: Int] = [:]

    init() {
        let persistedPhotos = persistence.loadImportedPhotos()
        photos = persistedPhotos.map(\.photo)
        placeSummaryVersions = Dictionary(uniqueKeysWithValues: persistedPhotos.map { ($0.photo.id, $0.placeSummaryVersion ?? 0) })
    }

    /// Returns the photos imported by the user and restored from local persistence.
    func fetchTravelPhotos() async -> [TravelPhoto] {
        await refreshLegacyPlaceSummariesIfNeeded()
        return photos
    }

    /// Appends imported photos to the session store and persists them so the next app launch can restore the same home map state.
    func saveImportedTravelPhotos(_ photos: [TravelPhoto]) async {
        self.photos = photos + self.photos
        for photo in photos {
            placeSummaryVersions[photo.id] = Self.currentPlaceSummaryVersion
        }
        persistence.saveImportedPhotos(self.photos, placeSummaryVersions: placeSummaryVersions)
    }

    /// Removes a persisted imported photo and updates the local photo store.
    func deleteImportedTravelPhoto(id: TravelPhoto.ID) async -> Bool {
        guard photos.contains(where: { $0.id == id }) else {
            return false
        }

        photos.removeAll { $0.id == id }
        placeSummaryVersions[id] = nil
        persistence.saveImportedPhotos(photos, placeSummaryVersions: placeSummaryVersions)
        return true
    }

    /// 旧版导入数据已持久化旧地名，这里在首次读取时用新的地图坐标语境刷新一次。
    private func refreshLegacyPlaceSummariesIfNeeded() async {
        guard photos.contains(where: { (placeSummaryVersions[$0.id] ?? 0) < Self.currentPlaceSummaryVersion }) else {
            return
        }

        var didUpdateStoredData = false
        var refreshedPhotos: [TravelPhoto] = []
        for (index, photo) in photos.enumerated() {
            guard (placeSummaryVersions[photo.id] ?? 0) < Self.currentPlaceSummaryVersion,
                  isUnlocatedPlaceholder(photo) == false else {
                refreshedPhotos.append(photo)
                placeSummaryVersions[photo.id] = Self.currentPlaceSummaryVersion
                didUpdateStoredData = true
                continue
            }

            guard let placeSummary = await placeSummaryResolver.reverseGeocodeSummary(
                for: photo.coordinate,
                sequence: index + 1
            ) else {
                refreshedPhotos.append(photo)
                continue
            }

            refreshedPhotos.append(
                TravelPhoto(
                    id: photo.id,
                    locationName: placeSummary.locationName,
                    regionName: placeSummary.regionName,
                    captureDate: photo.captureDate,
                    coordinate: photo.coordinate,
                    previewImageData: photo.previewImageData
                )
            )
            placeSummaryVersions[photo.id] = Self.currentPlaceSummaryVersion
            didUpdateStoredData = true
        }

        photos = refreshedPhotos
        if didUpdateStoredData {
            persistence.saveImportedPhotos(photos, placeSummaryVersions: placeSummaryVersions)
        }
    }

    private func isUnlocatedPlaceholder(_ photo: TravelPhoto) -> Bool {
        photo.regionName == "未定位" || photo.locationName.hasPrefix("待整理地点")
    }
}

private struct ImportedTravelPhotoStore {
    struct LoadedTravelPhoto {
        let photo: TravelPhoto
        let placeSummaryVersion: Int?
    }

    private struct PersistedTravelPhoto: Codable {
        let id: UUID
        let locationName: String
        let regionName: String
        let captureDate: String
        let latitude: Double
        let longitude: Double
        let previewImageData: Data?
        let placeSummaryVersion: Int?
    }

    private let fileManager = FileManager.default

    /// Loads persisted imports from Application Support so previously uploaded photos survive relaunches.
    func loadImportedPhotos() -> [LoadedTravelPhoto] {
        guard let data = try? Data(contentsOf: storageURL()),
              let persistedPhotos = try? JSONDecoder().decode([PersistedTravelPhoto].self, from: data) else {
            return []
        }

        return persistedPhotos.map {
            LoadedTravelPhoto(
                photo: TravelPhoto(
                    id: $0.id,
                    locationName: $0.locationName,
                    regionName: $0.regionName,
                    captureDate: $0.captureDate,
                    coordinate: .init(latitude: $0.latitude, longitude: $0.longitude),
                    previewImageData: $0.previewImageData
                ),
                placeSummaryVersion: $0.placeSummaryVersion
            )
        }
    }

    /// Saves imported photos into Application Support so the home collection can be reconstructed on the next launch.
    func saveImportedPhotos(_ photos: [TravelPhoto], placeSummaryVersions: [TravelPhoto.ID: Int]) {
        let persistedPhotos = photos.map {
            PersistedTravelPhoto(
                id: $0.id,
                locationName: $0.locationName,
                regionName: $0.regionName,
                captureDate: $0.captureDate,
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                previewImageData: $0.previewImageData,
                placeSummaryVersion: placeSummaryVersions[$0.id]
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
