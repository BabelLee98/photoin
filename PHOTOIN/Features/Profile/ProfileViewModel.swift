//
//  ProfileViewModel.swift
//  PHOTOIN
//
//  Created by Codex on 2026/6/14.
//

import CoreLocation
import Foundation
import Observation
import Photos
import SwiftUI
import UniformTypeIdentifiers
@MainActor
@Observable
final class ProfileViewModel {
    struct LocationGroup: Identifiable {
        let id: String
        let locationName: String
        let regionName: String
        let photoCount: Int
        let latestCaptureDate: String
        let coordinate: CLLocationCoordinate2D
    }

    enum ExportError: LocalizedError {
        case noContent

        var errorDescription: String? {
            switch self {
            case .noContent:
                "还没有可导出的照片或路线记录。"
            }
        }
    }

    var photos: [TravelPhoto] = []
    var routes: [HikeRoute] = []
    var exportDocument: ExportDocument?
    var exportErrorMessage: String?
    var deleteFeedbackMessage: String?

    private let travelPhotoRepository: any TravelPhotoRepository
    private let hikeRouteHistoryRepository: any HikeRouteHistoryRepository
    private var hasLoadedContent = false

    init(
        travelPhotoRepository: any TravelPhotoRepository,
        hikeRouteHistoryRepository: any HikeRouteHistoryRepository
    ) {
        self.travelPhotoRepository = travelPhotoRepository
        self.hikeRouteHistoryRepository = hikeRouteHistoryRepository
    }

    var totalPhotoCount: Int {
        photos.count
    }

    var totalLocationCount: Int {
        groupedLocations.count
    }

    var totalRouteCount: Int {
        routes.count
    }

    var groupedLocations: [LocationGroup] {
        let groups = Dictionary(grouping: photos) { "\($0.locationName)|\($0.regionName)" }

        return groups.values.compactMap { groupedPhotos in
            guard let leadPhoto = groupedPhotos.first else {
                return nil
            }

            let latestCaptureDate = groupedPhotos
                .map(\.captureDate)
                .sorted(by: >)
                .first ?? leadPhoto.captureDate

            return LocationGroup(
                id: "\(leadPhoto.locationName)|\(leadPhoto.regionName)",
                locationName: leadPhoto.locationName,
                regionName: leadPhoto.regionName,
                photoCount: groupedPhotos.count,
                latestCaptureDate: latestCaptureDate,
                coordinate: leadPhoto.coordinate
            )
        }
        .sorted { lhs, rhs in
            if lhs.latestCaptureDate == rhs.latestCaptureDate {
                return lhs.locationName < rhs.locationName
            }

            return lhs.latestCaptureDate > rhs.latestCaptureDate
        }
    }

    var photoPermissionSummary: String {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            return "已允许访问照片"
        case .denied, .restricted:
            return "照片权限未开启"
        case .notDetermined:
            return "尚未决定照片权限"
        @unknown default:
            return "照片权限状态未知"
        }
    }

    var locationPermissionSummary: String {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            return "定位始终允许"
        case .authorizedWhenInUse:
            return "定位使用时允许"
        case .denied, .restricted:
            return "定位权限未开启"
        case .notDetermined:
            return "尚未决定定位权限"
        @unknown default:
            return "定位权限状态未知"
        }
    }

    /// Loads the persisted profile content once so the tabs can share the same repositories without duplicate work.
    func loadContentIfNeeded() async {
        guard hasLoadedContent == false else {
            return
        }

        await reloadContent()
        hasLoadedContent = true
    }

    /// Refreshes photos and route history after imports or completed recordings.
    func reloadContent() async {
        photos = await travelPhotoRepository.fetchTravelPhotos()
        routes = hikeRouteHistoryRepository.fetchRecordedRoutes()
    }

    /// Deletes one imported photo and refreshes profile aggregates so gallery, locations, and counts stay aligned.
    func deleteImportedPhoto(id: TravelPhoto.ID) async {
        let didDelete = await travelPhotoRepository.deleteImportedTravelPhoto(id: id)
        guard didDelete else {
            deleteFeedbackMessage = "这张照片不是导入内容，暂时不能删除。"
            return
        }

        await reloadContent()
    }

    /// Builds a shareable JSON snapshot of the current photos and hiking history.
    func prepareExportDocument() async {
        await reloadContent()

        guard photos.isEmpty == false || routes.isEmpty == false else {
            exportErrorMessage = ExportError.noContent.localizedDescription
            return
        }

        let snapshot = ExportSnapshot(
            exportedAt: .now,
            photoCount: photos.count,
            routeCount: routes.count,
            photos: photos.map {
                ExportSnapshot.PhotoSnapshot(
                    id: $0.id,
                    locationName: $0.locationName,
                    regionName: $0.regionName,
                    captureDate: $0.captureDate,
                    latitude: $0.coordinate.latitude,
                    longitude: $0.coordinate.longitude
                )
            },
            routes: routes.map {
                ExportSnapshot.RouteSnapshot(
                    id: $0.id,
                    activityType: $0.activityType.displayName,
                    startedAt: $0.startedAt,
                    endedAt: $0.endedAt,
                    totalDistance: $0.totalDistance,
                    pointCount: $0.points.count,
                    checkpointCount: $0.checkpoints.count
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(snapshot) else {
            exportErrorMessage = "生成备份文件失败，请稍后再试。"
            return
        }

        exportDocument = ExportDocument(
            fileName: "PHOTOIN-Backup-\(exportDateLabel(from: .now)).json",
            data: data
        )
        exportErrorMessage = nil
    }

    /// Clears the one-shot export feedback after the user dismisses the alert.
    func dismissExportError() {
        exportErrorMessage = nil
    }

    /// Clears the one-shot delete feedback after the user acknowledges it.
    func dismissDeleteFeedback() {
        deleteFeedbackMessage = nil
    }

    /// Releases the generated export document after the file exporter finishes.
    func clearExportDocument() {
        exportDocument = nil
    }

    /// Formats a backup-friendly timestamp for exported filenames.
    private func exportDateLabel(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let fileName: String
    let data: Data

    init(fileName: String, data: Data) {
        self.fileName = fileName
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        fileName = "PHOTOIN-Backup.json"
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct ExportSnapshot: Codable {
    struct PhotoSnapshot: Codable {
        let id: UUID
        let locationName: String
        let regionName: String
        let captureDate: String
        let latitude: Double
        let longitude: Double
    }

    struct RouteSnapshot: Codable {
        let id: UUID
        let activityType: String
        let startedAt: Date?
        let endedAt: Date?
        let totalDistance: Double
        let pointCount: Int
        let checkpointCount: Int
    }

    let exportedAt: Date
    let photoCount: Int
    let routeCount: Int
    let photos: [PhotoSnapshot]
    let routes: [RouteSnapshot]
}
