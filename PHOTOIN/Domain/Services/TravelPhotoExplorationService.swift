//
//  TravelPhotoExplorationService.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import CoreLocation
import Foundation

struct TravelPhotoExplorationService {
    /// Returns the photos that match the user's place query while preserving the original ordering.
    func filteredPhotos(from photos: [TravelPhoto], query: String) -> [TravelPhoto] {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

        guard normalizedQuery.isEmpty == false else {
            return photos
        }

        return photos.filter { photo in
            let searchableText = [
                photo.title,
                photo.locationName,
                photo.regionName
            ]
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

            return searchableText.contains(normalizedQuery)
        }
    }

    /// Returns the photo that is closest to the front-facing side of the globe for the current rotation.
    func featuredPhoto(from photos: [TravelPhoto], rotation: Double) -> TravelPhoto? {
        photos.max { lhs, rhs in
            visibilityScore(for: lhs, rotation: rotation) < visibilityScore(for: rhs, rotation: rotation)
        }
    }

    /// Scores how visible a photo marker is on the front hemisphere so the UI can highlight the nearest item.
    private func visibilityScore(for photo: TravelPhoto, rotation: Double) -> Double {
        let latitude = photo.coordinate.latitude * .pi / 180
        let longitude = (photo.coordinate.longitude + rotation) * .pi / 180
        return cos(latitude) * cos(longitude)
    }
}
