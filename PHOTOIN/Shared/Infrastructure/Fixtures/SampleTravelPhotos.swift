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
            title: "清晨的海岬",
            locationName: "Cape Reinga",
            regionName: "新西兰",
            captureDate: "2026.01.14",
            coordinate: CLLocationCoordinate2D(latitude: -34.4308, longitude: 172.6806)
        ),
        TravelPhoto(
            title: "山口云海",
            locationName: "河口湖",
            regionName: "日本",
            captureDate: "2025.11.02",
            coordinate: CLLocationCoordinate2D(latitude: 35.5170, longitude: 138.7518)
        ),
        TravelPhoto(
            title: "古城黄昏",
            locationName: "布拉格城堡",
            regionName: "捷克",
            captureDate: "2025.09.18",
            coordinate: CLLocationCoordinate2D(latitude: 50.0909, longitude: 14.4005)
        ),
        TravelPhoto(
            title: "雪原终点站",
            locationName: "Hallstatt",
            regionName: "奥地利",
            captureDate: "2025.12.21",
            coordinate: CLLocationCoordinate2D(latitude: 47.5622, longitude: 13.6493)
        ),
        TravelPhoto(
            title: "城市夜色",
            locationName: "上海外滩",
            regionName: "中国",
            captureDate: "2026.03.08",
            coordinate: CLLocationCoordinate2D(latitude: 31.2400, longitude: 121.4900)
        )
    ]
}
