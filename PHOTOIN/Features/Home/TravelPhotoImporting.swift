//
//  TravelPhotoImporting.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/26.
//

import Foundation

struct TravelPhotoImportItem: Sendable {
    let imageData: Data
    let assetIdentifier: String?
}

protocol TravelPhotoImporting {
    /// Converts imported image payloads into session-ready travel photos for the home map.
    func importTravelPhotos(from items: [TravelPhotoImportItem], startingAt existingPhotoCount: Int) async throws -> [TravelPhoto]
}
