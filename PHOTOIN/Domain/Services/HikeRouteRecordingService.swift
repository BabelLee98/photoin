//
//  HikeRouteRecordingService.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Foundation

struct HikeRouteRecordingService {
    private let minimumPointDistance: CLLocationDistance = 8
    private let maximumAcceptedAccuracy: CLLocationAccuracy = 65

    /// Starts a fresh route session when the user taps the record button.
    func startRoute(at date: Date = .now) -> HikeRoute {
        HikeRoute(
            id: UUID(),
            startedAt: date,
            endedAt: nil,
            points: [],
            checkpoints: [],
            totalDistance: 0
        )
    }

    /// Appends a location update when it is accurate enough and meaningfully extends the route.
    func appendLocation(_ sample: HikeLocationSample, to route: HikeRoute) -> HikeRoute {
        guard route.isRecording else {
            return route
        }

        guard sample.horizontalAccuracy >= 0,
              sample.horizontalAccuracy <= maximumAcceptedAccuracy else {
            return route
        }

        let point = HikeRoute.Point(
            coordinate: sample.coordinate,
            timestamp: sample.timestamp
        )

        guard let lastPoint = route.points.last else {
            return HikeRoute(
                id: route.id,
                startedAt: route.startedAt,
                endedAt: route.endedAt,
                points: [point],
                checkpoints: route.checkpoints,
                totalDistance: route.totalDistance
            )
        }

        let segmentDistance = distance(from: lastPoint.coordinate, to: sample.coordinate)
        guard segmentDistance >= minimumPointDistance else {
            return route
        }

        return HikeRoute(
            id: route.id,
            startedAt: route.startedAt,
            endedAt: route.endedAt,
            points: route.points + [point],
            checkpoints: route.checkpoints,
            totalDistance: route.totalDistance + segmentDistance
        )
    }

    /// Inserts a manual checkpoint at the latest known location so the user can mark moments on the trail.
    func addCheckpoint(using sample: HikeLocationSample?, to route: HikeRoute) -> HikeRoute {
        guard route.isRecording,
              let sample else {
            return route
        }

        let checkpoint = HikeRoute.Checkpoint(
            title: "记录点 \(route.checkpoints.count + 1)",
            coordinate: sample.coordinate,
            timestamp: sample.timestamp
        )

        var updatedRoute = route
        if route.points.last?.coordinate != sample.coordinate {
            updatedRoute = appendManualPoint(from: sample, to: route)
        }

        return HikeRoute(
            id: updatedRoute.id,
            startedAt: updatedRoute.startedAt,
            endedAt: updatedRoute.endedAt,
            points: updatedRoute.points,
            checkpoints: updatedRoute.checkpoints + [checkpoint],
            totalDistance: updatedRoute.totalDistance
        )
    }

    /// Marks the route as finished so the UI can lock the summary and stop consuming updates.
    func finishRoute(_ route: HikeRoute, at date: Date = .now) -> HikeRoute {
        guard route.isRecording else {
            return route
        }

        return HikeRoute(
            id: route.id,
            startedAt: route.startedAt,
            endedAt: date,
            points: route.points,
            checkpoints: route.checkpoints,
            totalDistance: route.totalDistance
        )
    }

    /// Appends the user's explicit manual point without applying the usual distance threshold.
    private func appendManualPoint(from sample: HikeLocationSample, to route: HikeRoute) -> HikeRoute {
        let point = HikeRoute.Point(
            coordinate: sample.coordinate,
            timestamp: sample.timestamp
        )

        let segmentDistance = route.points.last.map { lastPoint in
            distance(from: lastPoint.coordinate, to: sample.coordinate)
        } ?? 0

        return HikeRoute(
            id: route.id,
            startedAt: route.startedAt,
            endedAt: route.endedAt,
            points: route.points + [point],
            checkpoints: route.checkpoints,
            totalDistance: route.totalDistance + segmentDistance
        )
    }

    /// Calculates line-segment distance between two recorded coordinates.
    private func distance(from start: HikeCoordinate, to end: HikeCoordinate) -> CLLocationDistance {
        CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
    }
}
