//
//  TravelPhotoImporting.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/26.
//

protocol TravelPhotoImporting {
    /// Converts a picker selection count into session-ready travel photos for the home map.
    func importTravelPhotos(selectionCount: Int, startingAt existingPhotoCount: Int) async throws -> [TravelPhoto]
}
