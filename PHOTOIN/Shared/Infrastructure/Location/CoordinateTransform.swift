//
//  CoordinateTransform.swift
//  PHOTOIN
//
//  Created by Codex on 2026/8/2.
//

import CoreLocation
import Foundation

enum CoordinateTransform {
    private static let pi = Double.pi
    private static let axis = 6_378_245.0
    private static let eccentricity = 0.006_693_421_622_965_943

    /// Converts the app's canonical WGS84 coordinate into GCJ-02 for mainland China map display.
    static func wgs84ToGCJ02(_ coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        guard usesGCJ02Display(for: coordinate) else {
            return coordinate
        }

        let delta = delta(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude + delta.latitude,
            longitude: coordinate.longitude + delta.longitude
        )
    }

    /// 判断坐标在国内地图展示时是否需要使用 GCJ-02。
    static func usesGCJ02Display(for coordinate: CLLocationCoordinate2D) -> Bool {
        isValid(coordinate) && isInChina(coordinate)
    }

    /// Returns whether a coordinate is inside the region where the GCJ-02 transform applies.
    private static func isInChina(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.longitude >= 72.004 && coordinate.longitude <= 137.8347
            && coordinate.latitude >= 0.8293 && coordinate.latitude <= 55.8271
    }

    /// Rejects invalid coordinates before the transform to keep map annotations well-defined.
    private static func isValid(_ coordinate: CLLocationCoordinate2D) -> Bool {
        CLLocationCoordinate2DIsValid(coordinate)
    }

    /// Calculates the latitude and longitude offset used by the GCJ-02 projection.
    private static func delta(latitude: Double, longitude: Double) -> (latitude: Double, longitude: Double) {
        let latitudeOffset = transformLatitude(x: longitude - 105.0, y: latitude - 35.0)
        let longitudeOffset = transformLongitude(x: longitude - 105.0, y: latitude - 35.0)
        let radians = latitude / 180.0 * pi
        let magic = 1.0 - eccentricity * sin(radians) * sin(radians)
        let sqrtMagic = sqrt(magic)

        return (
            latitude: latitudeOffset * 180.0 / ((axis * (1.0 - eccentricity)) / (magic * sqrtMagic) * pi),
            longitude: longitudeOffset * 180.0 / (axis / sqrtMagic * cos(radians) * pi)
        )
    }

    private static func transformLatitude(x: Double, y: Double) -> Double {
        var value = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        value += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        value += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
        value += (160.0 * sin(y / 12.0 * pi) + 320.0 * sin(y * pi / 30.0)) * 2.0 / 3.0
        return value
    }

    private static func transformLongitude(x: Double, y: Double) -> Double {
        var value = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        value += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        value += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
        value += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0
        return value
    }
}
