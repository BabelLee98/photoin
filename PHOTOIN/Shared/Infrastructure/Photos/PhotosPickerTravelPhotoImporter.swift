//
//  PhotosPickerTravelPhotoImporter.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/26.
//

import CoreLocation
import Foundation

struct PhotosPickerTravelPhotoImporter: TravelPhotoImporting {
    enum ImportError: LocalizedError {
        case emptySelection

        var errorDescription: String? {
            switch self {
            case .emptySelection:
                "这次还没有选中照片，请重新选择后再试试。"
            }
        }
    }

    /// Converts the current picker selection count into placeholder map-ready photos so the upload flow works before persistence is added.
    func importTravelPhotos(selectionCount: Int, startingAt existingPhotoCount: Int) async throws -> [TravelPhoto] {
        guard selectionCount > 0 else {
            throw ImportError.emptySelection
        }

        var importedPhotos: [TravelPhoto] = []

        for offset in 0..<selectionCount {
            let sequence = existingPhotoCount + offset + 1
            importedPhotos.append(
                TravelPhoto(
                    locationName: "待整理地点 \(sequence)",
                    regionName: "未定位",
                    captureDate: captureDateString(from: .now),
                    coordinate: fallbackCoordinate(for: sequence)
                )
            )
        }

        return importedPhotos
    }

    /// Formats the lightweight imported date label used by the current home card UI.
    private func captureDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    /// Spreads placeholder coordinates around central Beijing so newly imported photos do not stack on the exact same pin.
    private func fallbackCoordinate(for sequence: Int) -> CLLocationCoordinate2D {
        let baseLatitude = 39.9042
        let baseLongitude = 116.4074
        let row = Double((sequence - 1) / 4)
        let column = Double((sequence - 1) % 4)
        let latitudeOffset = (row - 1.5) * 0.018
        let longitudeOffset = (column - 1.5) * 0.018

        return CLLocationCoordinate2D(
            latitude: baseLatitude + latitudeOffset,
            longitude: baseLongitude + longitudeOffset
        )
    }
}
