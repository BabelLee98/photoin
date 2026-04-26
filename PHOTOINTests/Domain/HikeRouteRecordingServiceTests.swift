//
//  HikeRouteRecordingServiceTests.swift
//  PHOTOINTests
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Foundation
import Testing
@testable import PHOTOIN

struct HikeRouteRecordingServiceTests {
    private let service = HikeRouteRecordingService()

    @Test func startRouteCreatesAnEmptyRecordingSession() async throws {
        let route = service.startRoute(activityType: .hike, at: Date(timeIntervalSince1970: 1_000))

        #expect(route.isRecording)
        #expect(route.activityType == .hike)
        #expect(route.points.isEmpty)
        #expect(route.checkpoints.isEmpty)
        #expect(route.totalDistance == 0)
    }

    @Test func appendLocationIgnoresInaccurateSamplesAndAddsMeaningfulMovement() async throws {
        let startedRoute = service.startRoute(activityType: .hike, at: Date(timeIntervalSince1970: 1_000))
        let firstSample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.2304, longitude: 121.4737),
            timestamp: Date(timeIntervalSince1970: 1_010),
            horizontalAccuracy: 12
        )
        let poorAccuracySample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.2309, longitude: 121.4742),
            timestamp: Date(timeIntervalSince1970: 1_020),
            horizontalAccuracy: 120
        )
        let movingSample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.2314, longitude: 121.4752),
            timestamp: Date(timeIntervalSince1970: 1_030),
            horizontalAccuracy: 10
        )

        let firstUpdate = service.appendLocation(firstSample, to: startedRoute)
        let ignoredUpdate = service.appendLocation(poorAccuracySample, to: firstUpdate)
        let movingUpdate = service.appendLocation(movingSample, to: ignoredUpdate)

        #expect(firstUpdate.points.count == 1)
        #expect(ignoredUpdate.points.count == 1)
        #expect(movingUpdate.points.count == 2)
        #expect(movingUpdate.totalDistance > 0)
    }

    @Test func addCheckpointCreatesManualMarkerAndFinishingStopsRecording() async throws {
        let startedRoute = service.startRoute(activityType: .mountainClimb, at: Date(timeIntervalSince1970: 1_000))
        let sample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 34.3416, longitude: 108.9398),
            timestamp: Date(timeIntervalSince1970: 1_015),
            horizontalAccuracy: 8
        )

        let routeWithCheckpoint = service.addCheckpoint(using: sample, to: startedRoute)
        let finishedRoute = service.finishRoute(routeWithCheckpoint, at: Date(timeIntervalSince1970: 1_100))

        #expect(routeWithCheckpoint.checkpoints.count == 1)
        #expect(routeWithCheckpoint.points.count == 1)
        #expect(routeWithCheckpoint.checkpoints.first?.title == "记录点 1")
        #expect(finishedRoute.activityType == .mountainClimb)
        #expect(finishedRoute.isRecording == false)
        #expect(finishedRoute.endedAt != nil)
    }
}
