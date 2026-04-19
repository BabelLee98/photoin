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
    private var selectedPhotoID: TravelPhoto.ID?

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
        if let selectedPhotoID,
           let selectedPhoto = filteredPhotos.first(where: { $0.id == selectedPhotoID }) {
            return selectedPhoto
        }

        return filteredPhotos.first
    }

    var selectedFeaturedPhotoID: TravelPhoto.ID? {
        featuredPhoto?.id
    }

    /// Loads the current travel photo collection once so the screen can render without duplicate fetches.
    func loadPhotosIfNeeded() async {
        guard hasLoadedPhotos == false else {
            return
        }

        photos = await repository.fetchTravelPhotos()
        if selectedPhotoID == nil {
            selectedPhotoID = photos.first?.id
        }
        hasLoadedPhotos = true
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
