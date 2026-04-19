//
//  HikeCoordinate.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Foundation

struct HikeCoordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    /// Converts the domain coordinate into the Core Location type used by MapKit.
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Builds a domain coordinate from a Core Location coordinate.
    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
