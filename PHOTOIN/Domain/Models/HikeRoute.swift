//
//  HikeRoute.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Foundation

struct HikeRoute: Equatable, Sendable {
    struct Point: Identifiable, Equatable, Sendable {
        let id: UUID
        let coordinate: HikeCoordinate
        let timestamp: Date

        init(
            id: UUID = UUID(),
            coordinate: HikeCoordinate,
            timestamp: Date
        ) {
            self.id = id
            self.coordinate = coordinate
            self.timestamp = timestamp
        }
    }

    struct Checkpoint: Identifiable, Equatable, Sendable {
        let id: UUID
        let title: String
        let coordinate: HikeCoordinate
        let timestamp: Date

        init(
            id: UUID = UUID(),
            title: String,
            coordinate: HikeCoordinate,
            timestamp: Date
        ) {
            self.id = id
            self.title = title
            self.coordinate = coordinate
            self.timestamp = timestamp
        }
    }

    let id: UUID
    let startedAt: Date?
    let endedAt: Date?
    let points: [Point]
    let checkpoints: [Checkpoint]
    let totalDistance: CLLocationDistance

    /// Indicates whether the user is currently recording a hike.
    var isRecording: Bool {
        startedAt != nil && endedAt == nil
    }

    /// Returns the latest known coordinate so the UI can enable checkpointing only when possible.
    var latestCoordinate: HikeCoordinate? {
        points.last?.coordinate ?? checkpoints.last?.coordinate
    }

    /// Provides an empty route state before the user starts recording.
    static let empty = HikeRoute(
        id: UUID(),
        startedAt: nil,
        endedAt: nil,
        points: [],
        checkpoints: [],
        totalDistance: 0
    )

    init(
        id: UUID = UUID(),
        startedAt: Date?,
        endedAt: Date?,
        points: [Point],
        checkpoints: [Checkpoint],
        totalDistance: CLLocationDistance
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.points = points
        self.checkpoints = checkpoints
        self.totalDistance = totalDistance
    }
}
