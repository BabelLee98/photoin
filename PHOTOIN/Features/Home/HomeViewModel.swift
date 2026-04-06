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
    var globeRotation = -20.0
    var isUploadPromptPresented = false
    private(set) var photos: [TravelPhoto] = []

    private let repository: any TravelPhotoRepository
    private let explorationService: TravelPhotoExplorationService
    private var hasLoadedPhotos = false

    init(
        repository: any TravelPhotoRepository,
        explorationService: TravelPhotoExplorationService
    ) {
        self.repository = repository
        self.explorationService = explorationService
    }

    var filteredPhotos: [TravelPhoto] {
        explorationService.filteredPhotos(from: photos, query: searchText)
    }

    var featuredPhoto: TravelPhoto? {
        explorationService.featuredPhoto(from: filteredPhotos, rotation: globeRotation)
    }

    /// Loads the current travel photo collection once so the screen can render without duplicate fetches.
    func loadPhotosIfNeeded() async {
        guard hasLoadedPhotos == false else {
            return
        }

        photos = await repository.fetchTravelPhotos()
        hasLoadedPhotos = true
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
