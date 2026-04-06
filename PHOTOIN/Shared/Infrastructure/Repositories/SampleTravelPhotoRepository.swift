//
//  SampleTravelPhotoRepository.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import Foundation

struct SampleTravelPhotoRepository: TravelPhotoRepository {
    /// Returns the sample travel photos used until the real photo import pipeline is connected.
    func fetchTravelPhotos() async -> [TravelPhoto] {
        SampleTravelPhotos.all
    }
}
