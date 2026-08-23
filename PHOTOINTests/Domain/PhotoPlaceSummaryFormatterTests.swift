//
//  PhotoPlaceSummaryFormatterTests.swift
//  PHOTOINTests
//
//  Created by Codex on 2026/8/23.
//

import CoreLocation
import Testing
@testable import PHOTOIN

struct PhotoPlaceSummaryFormatterTests {
    @Test func mainlandChinaSummaryPrefersDistrictOverNearbyPointOfInterest() {
        let formatter = PhotoPlaceSummaryFormatter()
        let summary = formatter.summary(
            from: .init(
                name: "附近咖啡店",
                locality: "上海市",
                subLocality: "黄浦区",
                administrativeArea: "上海市",
                country: "中国",
                isoCountryCode: "CN"
            ),
            sequence: 1,
            displayCoordinate: .init(latitude: 31.2450, longitude: 121.4950)
        )

        #expect(summary.locationName == "黄浦区")
        #expect(summary.regionName == "上海市 · 中国")
    }

    @Test func summaryFallsBackToDisplayCoordinateWhenPlacemarkHasNoRegion() {
        let formatter = PhotoPlaceSummaryFormatter()
        let summary = formatter.summary(
            from: .init(),
            sequence: 4,
            displayCoordinate: .init(latitude: 31.245012, longitude: 121.495078)
        )

        #expect(summary.locationName == "已定位照片 4")
        #expect(summary.regionName == "31.2450, 121.4951")
    }
}
