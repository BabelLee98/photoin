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
    var isUploadPromptPresented = false
    private(set) var photos: [TravelPhoto] = []
    private(set) var recordedRoutes: [HikeRoute] = []
    private var selectedPhotoID: TravelPhoto.ID?

    private let repository: any TravelPhotoRepository
    private let explorationService: TravelPhotoExplorationService
    private let hikeRouteHistoryRepository: any HikeRouteHistoryRepository
    private var hasLoadedPhotos = false

    init(
        repository: any TravelPhotoRepository,
        explorationService: TravelPhotoExplorationService,
        hikeRouteHistoryRepository: any HikeRouteHistoryRepository
    ) {
        self.repository = repository
        self.explorationService = explorationService
        self.hikeRouteHistoryRepository = hikeRouteHistoryRepository
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

        photos = await repository.fetchTravelPhotos()
        refreshRecordedRoutes()
        if selectedPhotoID == nil {
            selectedPhotoID = photos.first?.id
        }
        hasLoadedPhotos = true
    }

    /// Refreshes the session route history so the home summary can reflect newly completed recordings.
    func refreshRecordedRoutes() {
        recordedRoutes = hikeRouteHistoryRepository.fetchRecordedRoutes()
    }

    /// Updates the currently featured photo when the user taps a map marker.
    func selectPhoto(id: TravelPhoto.ID) {
        selectedPhotoID = id
    }

    /// Presents the upload placeholder prompt from the home screen.
    func presentUploadPrompt() {
        isUploadPromptPresented = true
    }

    /// Dismisses the upload placeholder prompt after the user acknowledges it.
    func dismissUploadPrompt() {
        isUploadPromptPresented = false
    }
}
