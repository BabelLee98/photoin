//
//  PhotosPickerTravelPhotoImporter.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/26.
//

import CoreLocation
import Foundation
import ImageIO
import Photos

struct PhotosPickerTravelPhotoImporter: TravelPhotoImporting {
    enum ImportError: LocalizedError {
        case emptySelection
        case noImportableItems

        var errorDescription: String? {
            switch self {
            case .emptySelection:
                "这次还没有选中照片，请重新选择后再试试。"
            case .noImportableItems:
                "这些照片暂时无法导入，请换一组图片再试试。"
            }
        }
    }

    private struct PhotoMetadata {
        let captureDate: Date?
        let coordinate: CLLocationCoordinate2D?
    }

    /// Converts selected photo payloads into map-ready models by reading the asset's real date and location metadata whenever available.
    func importTravelPhotos(from items: [TravelPhotoImportItem], startingAt existingPhotoCount: Int) async throws -> [TravelPhoto] {
        guard items.isEmpty == false else {
            throw ImportError.emptySelection
        }

        var importedPhotos: [TravelPhoto] = []

        for (offset, item) in items.enumerated() {
            let sequence = existingPhotoCount + offset + 1
            let metadata = metadata(for: item)
            let coordinate = metadata.coordinate ?? fallbackCoordinate(for: sequence)
            let placeSummary = await resolvePlaceSummary(for: coordinate, sequence: sequence, hasLocation: metadata.coordinate != nil)

            importedPhotos.append(
                TravelPhoto(
                    locationName: placeSummary.locationName,
                    regionName: placeSummary.regionName,
                    captureDate: captureDateString(from: metadata.captureDate ?? .now),
                    coordinate: coordinate,
                    previewImageData: item.imageData
                )
            )
        }

        guard importedPhotos.isEmpty == false else {
            throw ImportError.noImportableItems
        }

        return importedPhotos
    }

    /// Reads metadata from the Photos asset first, then falls back to the image's embedded EXIF and GPS dictionaries.
    private func metadata(for item: TravelPhotoImportItem) -> PhotoMetadata {
        if let assetIdentifier = item.assetIdentifier,
           let assetMetadata = assetMetadata(for: assetIdentifier) {
            return assetMetadata
        }

        return imageMetadata(from: item.imageData)
    }

    /// Fetches creation date and location from the selected Photos asset when the picker provides a local identifier.
    private func assetMetadata(for assetIdentifier: String) -> PhotoMetadata? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = assets.firstObject else {
            return nil
        }

        return PhotoMetadata(
            captureDate: asset.creationDate,
            coordinate: asset.location?.coordinate
        )
    }

    /// Parses EXIF and GPS dictionaries directly from the imported image payload so metadata still works when an asset lookup is unavailable.
    private func imageMetadata(from imageData: Data) -> PhotoMetadata {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return PhotoMetadata(captureDate: nil, coordinate: nil)
        }

        return PhotoMetadata(
            captureDate: captureDate(from: properties),
            coordinate: coordinate(from: properties)
        )
    }

    /// Formats the lightweight imported date label used by the current home card UI.
    private func captureDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    /// Builds the best human-readable place label we can from reverse geocoding, while keeping a stable fallback for photos without location data.
    private func resolvePlaceSummary(
        for coordinate: CLLocationCoordinate2D,
        sequence: Int,
        hasLocation: Bool
    ) async -> (locationName: String, regionName: String) {
        guard hasLocation else {
            return ("待整理地点 \(sequence)", "未定位")
        }

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            let locationName = [
                placemark.name,
                placemark.locality,
                placemark.subLocality,
                placemark.administrativeArea
            ]
            .compactMap { $0 }
            .first(where: { $0.isEmpty == false }) ?? "已定位照片 \(sequence)"

            let regionCandidates = [
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ]
            .compactMap { value -> String? in
                guard let value, value.isEmpty == false else {
                    return nil
                }
                return value
            }

            let deduplicatedRegion = Array(NSOrderedSet(array: regionCandidates)) as? [String] ?? regionCandidates
            let regionName = deduplicatedRegion.isEmpty ? coordinateSummary(for: coordinate) : deduplicatedRegion.joined(separator: " · ")

            return (locationName, regionName)
        }

        return ("已定位照片 \(sequence)", coordinateSummary(for: coordinate))
    }

    /// Extracts the capture timestamp from EXIF or TIFF properties when the Photos asset metadata is unavailable.
    private func captureDate(from properties: [CFString: Any]) -> Date? {
        let exifDate = (properties[kCGImagePropertyExifDictionary] as? [CFString: Any])?[kCGImagePropertyExifDateTimeOriginal] as? String
        let tiffDate = (properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any])?[kCGImagePropertyTIFFDateTime] as? String
        let rawDate = exifDate ?? tiffDate

        guard let rawDate else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: rawDate)
    }

    /// Extracts GPS coordinates from the image metadata and applies the hemisphere references so western and southern values remain correct.
    private func coordinate(from properties: [CFString: Any]) -> CLLocationCoordinate2D? {
        guard let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude] as? Double else {
            return nil
        }

        let latitudeRef = (gps[kCGImagePropertyGPSLatitudeRef] as? String)?.uppercased()
        let longitudeRef = (gps[kCGImagePropertyGPSLongitudeRef] as? String)?.uppercased()

        let signedLatitude = latitudeRef == "S" ? -latitude : latitude
        let signedLongitude = longitudeRef == "W" ? -longitude : longitude

        return CLLocationCoordinate2D(latitude: signedLatitude, longitude: signedLongitude)
    }

    /// Formats a coordinate pair so located photos still surface useful context when reverse geocoding does not return a place name.
    private func coordinateSummary(for coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    /// Spreads placeholder coordinates around central Beijing only for photos that do not carry any embedded location metadata.
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
