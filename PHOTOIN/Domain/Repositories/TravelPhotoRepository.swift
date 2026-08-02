//
//  TravelPhotoRepository.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import Foundation

protocol TravelPhotoRepository {
    /// Returns the travel photos currently available to the app.
    func fetchTravelPhotos() async -> [TravelPhoto]

    /// Stores imported travel photos for the current app session.
    func saveImportedTravelPhotos(_ photos: [TravelPhoto]) async

    /// Deletes a user-imported photo when it exists in the local import store.
    func deleteImportedTravelPhoto(id: TravelPhoto.ID) async -> Bool
}
