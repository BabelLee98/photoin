//
//  PersistentHikeRouteHistoryRepository.swift
//  PHOTOIN
//
//  Created by Codex on 2026/6/14.
//

import Foundation

@MainActor
final class PersistentHikeRouteHistoryRepository: HikeRouteHistoryRepository {
    private let storage = HikeRouteHistoryStore()
    private var recordedRoutes: [HikeRoute]

    init() {
        recordedRoutes = storage.loadRoutes()
    }

    /// Returns the completed routes restored from local storage and updated during the current session.
    func fetchRecordedRoutes() -> [HikeRoute] {
        recordedRoutes
    }

    /// Saves the newest completed route to local storage so profile and home summaries survive relaunches.
    func saveRecordedRoute(_ route: HikeRoute) {
        recordedRoutes.removeAll { $0.id == route.id }
        recordedRoutes.insert(route, at: 0)
        storage.saveRoutes(recordedRoutes)
    }
}

private struct HikeRouteHistoryStore {
    private struct PersistedRoute: Codable {
        struct PersistedPoint: Codable {
            let id: UUID
            let latitude: Double
            let longitude: Double
            let timestamp: Date
        }

        struct PersistedCheckpoint: Codable {
            let id: UUID
            let title: String
            let latitude: Double
            let longitude: Double
            let timestamp: Date
        }

        let id: UUID
        let activityType: String
        let startedAt: Date?
        let endedAt: Date?
        let points: [PersistedPoint]
        let checkpoints: [PersistedCheckpoint]
        let totalDistance: Double
    }

    private let fileManager = FileManager.default

    /// Loads persisted routes from Application Support so completed trail history is available across launches.
    func loadRoutes() -> [HikeRoute] {
        guard let data = try? Data(contentsOf: storageURL()),
              let persistedRoutes = try? JSONDecoder().decode([PersistedRoute].self, from: data) else {
            return []
        }

        return persistedRoutes.compactMap { route(from: $0) }
    }

    /// Writes the current route history to Application Support using a lightweight JSON snapshot.
    func saveRoutes(_ routes: [HikeRoute]) {
        let persistedRoutes = routes.map(persistedRoute(from:))
        guard let data = try? JSONEncoder().encode(persistedRoutes) else {
            return
        }

        let directoryURL = storageURL().deletingLastPathComponent()
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        try? data.write(to: storageURL(), options: .atomic)
    }

    /// Rebuilds a domain route from its persisted representation.
    private func route(from persistedRoute: PersistedRoute) -> HikeRoute? {
        guard let activityType = HikeRoute.ActivityType(rawValue: persistedRoute.activityType) else {
            return nil
        }

        return HikeRoute(
            id: persistedRoute.id,
            activityType: activityType,
            startedAt: persistedRoute.startedAt,
            endedAt: persistedRoute.endedAt,
            points: persistedRoute.points.map {
                HikeRoute.Point(
                    id: $0.id,
                    coordinate: HikeCoordinate(latitude: $0.latitude, longitude: $0.longitude),
                    timestamp: $0.timestamp
                )
            },
            checkpoints: persistedRoute.checkpoints.map {
                HikeRoute.Checkpoint(
                    id: $0.id,
                    title: $0.title,
                    coordinate: HikeCoordinate(latitude: $0.latitude, longitude: $0.longitude),
                    timestamp: $0.timestamp
                )
            },
            totalDistance: persistedRoute.totalDistance
        )
    }

    /// Converts a domain route into a JSON-safe payload for long-term storage.
    private func persistedRoute(from route: HikeRoute) -> PersistedRoute {
        PersistedRoute(
            id: route.id,
            activityType: route.activityType.rawValue,
            startedAt: route.startedAt,
            endedAt: route.endedAt,
            points: route.points.map {
                PersistedRoute.PersistedPoint(
                    id: $0.id,
                    latitude: $0.coordinate.latitude,
                    longitude: $0.coordinate.longitude,
                    timestamp: $0.timestamp
                )
            },
            checkpoints: route.checkpoints.map {
                PersistedRoute.PersistedCheckpoint(
                    id: $0.id,
                    title: $0.title,
                    latitude: $0.coordinate.latitude,
                    longitude: $0.coordinate.longitude,
                    timestamp: $0.timestamp
                )
            },
            totalDistance: route.totalDistance
        )
    }

    /// Returns the JSON file used to keep completed route history between launches.
    private func storageURL() -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("PHOTOIN", isDirectory: true)
            .appendingPathComponent("recorded_hike_routes.json")
    }
}
