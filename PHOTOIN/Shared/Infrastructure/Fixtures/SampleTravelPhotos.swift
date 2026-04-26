//
//  SampleTravelPhotos.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import CoreLocation
import Foundation

enum SampleTravelPhotos {
    static let all: [TravelPhoto] = [
        TravelPhoto(
            locationName: "Cape Reinga",
            regionName: "新西兰",
            captureDate: "2026.01.14",
            coordinate: CLLocationCoordinate2D(latitude: -34.4308, longitude: 172.6806)
        ),
        TravelPhoto(
            locationName: "河口湖",
            regionName: "日本",
            captureDate: "2025.11.02",
            coordinate: CLLocationCoordinate2D(latitude: 35.5170, longitude: 138.7518)
        ),
        TravelPhoto(
            locationName: "布拉格城堡",
            regionName: "捷克",
            captureDate: "2025.09.18",
            coordinate: CLLocationCoordinate2D(latitude: 50.0909, longitude: 14.4005)
        ),
        TravelPhoto(
            locationName: "Hallstatt",
            regionName: "奥地利",
            captureDate: "2025.12.21",
            coordinate: CLLocationCoordinate2D(latitude: 47.5622, longitude: 13.6493)
        ),
        TravelPhoto(
            locationName: "上海外滩",
            regionName: "中国",
            captureDate: "2026.03.08",
            coordinate: CLLocationCoordinate2D(latitude: 31.2400, longitude: 121.4900)
        )
    ]
}
