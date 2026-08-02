//
//  CoordinateTransformTests.swift
//  PHOTOINTests
//
//  Created by Codex on 2026/8/2.
//

import CoreLocation
import Testing
@testable import PHOTOIN

struct CoordinateTransformTests {
    @Test func transformsCoordinatesInsideChina() async throws {
        let wgs84 = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
        let gcj02 = CoordinateTransform.wgs84ToGCJ02(wgs84)

        #expect(gcj02.latitude != wgs84.latitude)
        #expect(gcj02.longitude != wgs84.longitude)
        #expect(CLLocationCoordinate2DIsValid(gcj02))
    }

    @Test func leavesCoordinatesOutsideChinaUnchanged() async throws {
        let wgs84 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

        let transformed = CoordinateTransform.wgs84ToGCJ02(wgs84)

        #expect(transformed.latitude == wgs84.latitude)
        #expect(transformed.longitude == wgs84.longitude)
    }
}
