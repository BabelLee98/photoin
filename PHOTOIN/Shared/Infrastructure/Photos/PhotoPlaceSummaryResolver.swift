//
//  PhotoPlaceSummaryResolver.swift
//  PHOTOIN
//
//  Created by Codex on 2026/8/23.
//

import CoreLocation
import Foundation

struct PhotoPlaceSummaryResolver {
    private let formatter = PhotoPlaceSummaryFormatter()

    /// 使用地图展示坐标反查地点名称，让照片气泡标题和地图落点保持一致。
    func resolve(
        for coordinate: CLLocationCoordinate2D,
        sequence: Int,
        hasLocation: Bool
    ) async -> (locationName: String, regionName: String) {
        guard hasLocation else {
            return ("待整理地点 \(sequence)", "未定位")
        }

        if let summary = await reverseGeocodeSummary(for: coordinate, sequence: sequence) {
            return summary
        }

        let displayCoordinate = CoordinateTransform.wgs84ToGCJ02(coordinate)
        return ("已定位照片 \(sequence)", formatter.coordinateSummary(for: displayCoordinate))
    }

    /// 只在系统反查成功时返回地名摘要，避免迁移旧数据时用兜底名称覆盖有效旧名称。
    func reverseGeocodeSummary(
        for coordinate: CLLocationCoordinate2D,
        sequence: Int
    ) async -> (locationName: String, regionName: String)? {
        let displayCoordinate = CoordinateTransform.wgs84ToGCJ02(coordinate)
        let location = CLLocation(latitude: displayCoordinate.latitude, longitude: displayCoordinate.longitude)
        let geocoder = CLGeocoder()

        if let placemark = try? await geocoder.reverseGeocodeLocation(
            location,
            preferredLocale: Locale(identifier: "zh_CN")
        ).first {
            return formatter.summary(
                from: PhotoPlaceSummaryFormatter.Components(placemark: placemark),
                sequence: sequence,
                displayCoordinate: displayCoordinate
            )
        }

        return nil
    }
}
