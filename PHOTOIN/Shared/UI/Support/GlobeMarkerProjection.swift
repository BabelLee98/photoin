//
//  GlobeMarkerProjection.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import CoreGraphics
import CoreLocation
import Foundation

struct GlobeMarkerProjection {
    let point: CGPoint
    let depth: Double
    let isVisible: Bool

    /// Projects a real photo coordinate onto the globe surface for the current rotation.
    init(coordinate: CLLocationCoordinate2D, rotation: Double, radius: CGFloat, center: CGPoint) {
        self.init(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            rotation: rotation,
            radius: radius,
            center: center
        )
    }

    /// Projects any latitude and longitude pair onto the globe so the grid and markers share one math model.
    init(latitude: Double, longitude: Double, rotation: Double, radius: CGFloat, center: CGPoint) {
        let latitude = latitude * .pi / 180
        let longitude = (longitude + rotation) * .pi / 180

        let x = cos(latitude) * sin(longitude)
        let y = sin(latitude)
        let z = cos(latitude) * cos(longitude)

        point = CGPoint(
            x: center.x + radius * CGFloat(x),
            y: center.y - radius * CGFloat(y)
        )
        depth = z
        isVisible = z > -0.08
    }
}
