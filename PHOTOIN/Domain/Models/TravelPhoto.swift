//
//  TravelPhoto.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import CoreLocation
import Foundation

struct TravelPhoto: Identifiable {
    let id: UUID
    let title: String
    let locationName: String
    let regionName: String
    let captureDate: String
    let coordinate: CLLocationCoordinate2D

    init(
        id: UUID = UUID(),
        title: String,
        locationName: String,
        regionName: String,
        captureDate: String,
        coordinate: CLLocationCoordinate2D
    ) {
        self.id = id
        self.title = title
        self.locationName = locationName
        self.regionName = regionName
        self.captureDate = captureDate
        self.coordinate = coordinate
    }
}
