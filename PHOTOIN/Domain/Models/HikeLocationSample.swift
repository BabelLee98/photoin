//
//  HikeLocationSample.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Foundation

struct HikeLocationSample: Equatable, Sendable {
    let coordinate: HikeCoordinate
    let timestamp: Date
    let horizontalAccuracy: CLLocationAccuracy

    /// Wraps a CLLocation update into a Sendable domain sample for route recording logic.
    init(location: CLLocation) {
        self.coordinate = HikeCoordinate(location.coordinate)
        self.timestamp = location.timestamp
        self.horizontalAccuracy = location.horizontalAccuracy
    }

    init(
        coordinate: HikeCoordinate,
        timestamp: Date,
        horizontalAccuracy: CLLocationAccuracy
    ) {
        self.coordinate = coordinate
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
    }
}
