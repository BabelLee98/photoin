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
            timestamp: Date(timeIntervalSince1970: 1_050),
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
        let startedRoute = service.startRoute(activityType: .hike, at: Date(timeIntervalSince1970: 1_000))
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
        #expect(finishedRoute.activityType == .hike)
        #expect(finishedRoute.isRecording == false)
        #expect(finishedRoute.endedAt != nil)
    }

    @Test func appendLocationCapturesShortWalkingSegments() async throws {
        let startedRoute = service.startRoute(activityType: .hike, at: Date(timeIntervalSince1970: 2_000))
        let firstSample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.2304, longitude: 121.4737),
            timestamp: Date(timeIntervalSince1970: 2_010),
            horizontalAccuracy: 6
        )
        let shortWalkSample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.230435, longitude: 121.473735),
            timestamp: Date(timeIntervalSince1970: 2_020),
            horizontalAccuracy: 6
        )

        let firstUpdate = service.appendLocation(firstSample, to: startedRoute)
        let walkingUpdate = service.appendLocation(shortWalkSample, to: firstUpdate)

        #expect(firstUpdate.points.count == 1)
        #expect(walkingUpdate.points.count == 2)
        #expect(walkingUpdate.totalDistance > 0)
    }

    @Test func appendLocationIgnoresSuddenGPSJumps() async throws {
        let startedRoute = service.startRoute(activityType: .hike, at: Date(timeIntervalSince1970: 3_000))
        let firstSample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.2304, longitude: 121.4737),
            timestamp: Date(timeIntervalSince1970: 3_010),
            horizontalAccuracy: 6
        )
        let jumpSample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.2504, longitude: 121.4937),
            timestamp: Date(timeIntervalSince1970: 3_020),
            horizontalAccuracy: 8
        )

        let firstUpdate = service.appendLocation(firstSample, to: startedRoute)
        let ignoredUpdate = service.appendLocation(jumpSample, to: firstUpdate)

        #expect(firstUpdate.points.count == 1)
        #expect(ignoredUpdate.points.count == 1)
        #expect(ignoredUpdate.totalDistance == 0)
    }

    @Test func appendLocationIgnoresCachedSamplesBeforeRecordingStarts() async throws {
        let startedRoute = service.startRoute(activityType: .hike, at: Date(timeIntervalSince1970: 4_000))
        let cachedSample = HikeLocationSample(
            coordinate: HikeCoordinate(latitude: 31.2304, longitude: 121.4737),
            timestamp: Date(timeIntervalSince1970: 3_990),
            horizontalAccuracy: 6
        )

        let updatedRoute = service.appendLocation(cachedSample, to: startedRoute)

        #expect(updatedRoute.points.isEmpty)
        #expect(updatedRoute.totalDistance == 0)
    }
}
