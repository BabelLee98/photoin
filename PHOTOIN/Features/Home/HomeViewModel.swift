//
//  HomeViewModel.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var searchText = ""
    var isImportingPhotos = false
    var uploadFeedbackMessage: String?
    private(set) var photos: [TravelPhoto] = []
    private(set) var recordedRoutes: [HikeRoute] = []
    private var selectedPhotoID: TravelPhoto.ID?

    private let repository: any TravelPhotoRepository
    private let explorationService: TravelPhotoExplorationService
    private let hikeRouteHistoryRepository: any HikeRouteHistoryRepository
    private let travelPhotoImporter: any TravelPhotoImporting
    private var hasLoadedPhotos = false

    init(
        repository: any TravelPhotoRepository,
        explorationService: TravelPhotoExplorationService,
        hikeRouteHistoryRepository: any HikeRouteHistoryRepository,
        travelPhotoImporter: any TravelPhotoImporting
    ) {
        self.repository = repository
        self.explorationService = explorationService
        self.hikeRouteHistoryRepository = hikeRouteHistoryRepository
        self.travelPhotoImporter = travelPhotoImporter
    }

    var filteredPhotos: [TravelPhoto] {
        explorationService.filteredPhotos(from: photos, query: searchText)
    }

    var featuredPhoto: TravelPhoto? {
        if let selectedPhotoID,
           let selectedPhoto = filteredPhotos.first(where: { $0.id == selectedPhotoID }) {
            return selectedPhoto
        }

        return filteredPhotos.first
    }

    var selectedFeaturedPhotoID: TravelPhoto.ID? {
        featuredPhoto?.id
    }

    var totalPhotoCount: Int {
        photos.count
    }

    var totalVisitedLocationCount: Int {
        Set(photos.map { "\($0.locationName)|\($0.regionName)" }).count
    }

    var totalVisitedCityCount: Int {
        totalVisitedLocationCount
    }

    var totalClimbedMountainCount: Int {
        recordedRoutes.filter { $0.activityType == .mountainClimb }.count
    }

    var totalHikeCount: Int {
        recordedRoutes.filter { $0.activityType == .hike }.count
    }

    /// Loads the current travel photo collection once so the screen can render without duplicate fetches.
    func loadPhotosIfNeeded() async {
        guard hasLoadedPhotos == false else {
            return
        }

        await reloadPhotos()
        refreshRecordedRoutes()
        if selectedPhotoID == nil {
            selectedPhotoID = photos.first?.id
        }
        hasLoadedPhotos = true
    }

    /// Reloads photo data from the shared repository so home reflects imports and deletes performed in other tabs.
    func reloadPhotos() async {
        photos = await repository.fetchTravelPhotos()
        if let selectedPhotoID,
           photos.contains(where: { $0.id == selectedPhotoID }) == false {
            self.selectedPhotoID = photos.first?.id
        }
    }

    /// Refreshes the session route history so the home summary can reflect newly completed recordings.
    func refreshRecordedRoutes() {
        recordedRoutes = hikeRouteHistoryRepository.fetchRecordedRoutes()
    }

    /// Updates the currently featured photo when the user taps a map marker.
    func selectPhoto(id: TravelPhoto.ID) {
        selectedPhotoID = id
    }

    /// Imports loaded image payloads into the repository and refreshes the home map immediately.
    func importSelectedPhotos(_ items: [TravelPhotoImportItem]) async {
        guard items.isEmpty == false else {
            return
        }

        isImportingPhotos = true
        defer { isImportingPhotos = false }

        do {
            let importedPhotos = try await travelPhotoImporter.importTravelPhotos(
                from: items,
                startingAt: photos.count
            )

            await repository.saveImportedTravelPhotos(importedPhotos)
            photos = await repository.fetchTravelPhotos()
            selectedPhotoID = importedPhotos.first?.id ?? selectedPhotoID
            uploadFeedbackMessage = "已导入 \(importedPhotos.count) 张照片。"
            hasLoadedPhotos = true
        } catch {
            uploadFeedbackMessage = error.localizedDescription.isEmpty ? "导入失败，请稍后再试。" : error.localizedDescription
        }
    }

    /// Clears the transient upload feedback after the user acknowledges it.
    func dismissUploadFeedback() {
        uploadFeedbackMessage = nil
    }
}
