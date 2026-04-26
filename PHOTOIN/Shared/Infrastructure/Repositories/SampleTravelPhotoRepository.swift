//
//  SampleTravelPhotoRepository.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import Foundation

final class SampleTravelPhotoRepository: TravelPhotoRepository {
    private var photos = SampleTravelPhotos.all

    /// Returns the sample travel photos used until the real photo import pipeline is connected.
    func fetchTravelPhotos() async -> [TravelPhoto] {
        photos
    }

    /// Appends imported photos to the session store so the home map can refresh immediately.
    func saveImportedTravelPhotos(_ photos: [TravelPhoto]) async {
        self.photos = photos + self.photos
    }
}
