//
//  PhotoPlaceSummaryFormatter.swift
//  PHOTOIN
//
//  Created by Codex on 2026/8/23.
//

import CoreLocation
import Foundation

struct PhotoPlaceSummaryFormatter {
    struct Components {
        let name: String?
        let locality: String?
        let subLocality: String?
        let administrativeArea: String?
        let country: String?
        let isoCountryCode: String?

        /// 复制 Core Location 反查结果中生成照片地点摘要所需的字段。
        init(placemark: CLPlacemark) {
            self.name = placemark.name
            self.locality = placemark.locality
            self.subLocality = placemark.subLocality
            self.administrativeArea = placemark.administrativeArea
            self.country = placemark.country
            self.isoCountryCode = placemark.isoCountryCode
        }

        /// 构造可控的测试数据，避免单元测试依赖 CLPlacemark 的内部初始化方式。
        init(
            name: String? = nil,
            locality: String? = nil,
            subLocality: String? = nil,
            administrativeArea: String? = nil,
            country: String? = nil,
            isoCountryCode: String? = nil
        ) {
            self.name = name
            self.locality = locality
            self.subLocality = subLocality
            self.administrativeArea = administrativeArea
            self.country = country
            self.isoCountryCode = isoCountryCode
        }
    }

    /// 生成照片地图气泡中展示的地点标题和地区标签。
    func summary(
        from components: Components,
        sequence: Int,
        displayCoordinate: CLLocationCoordinate2D
    ) -> (locationName: String, regionName: String) {
        let titleCandidates = titleCandidates(from: components, displayCoordinate: displayCoordinate)
        let locationName = firstNonEmpty(titleCandidates) ?? "已定位照片 \(sequence)"
        let regionCandidates = [
            components.locality,
            components.administrativeArea,
            components.country
        ]

        let regionParts = deduplicatedNonEmptyValues(regionCandidates)
            .filter { $0 != locationName }
        let regionName = regionParts.isEmpty
            ? coordinateSummary(for: displayCoordinate)
            : regionParts.joined(separator: " · ")

        return (locationName, regionName)
    }

    /// 当反查结果没有可用地名时，用展示坐标生成可读的兜底信息。
    func coordinateSummary(for coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }

    /// 国内地点优先使用行政区划，避免把附近 POI 或详细门牌误当成主标题。
    private func titleCandidates(
        from components: Components,
        displayCoordinate: CLLocationCoordinate2D
    ) -> [String?] {
        if components.isoCountryCode == "CN" || CoordinateTransform.usesGCJ02Display(for: displayCoordinate) {
            return [
                components.subLocality,
                components.locality,
                components.administrativeArea,
                components.name
            ]
        }

        return [
            components.locality,
            components.subLocality,
            components.name,
            components.administrativeArea
        ]
    }

    private func firstNonEmpty(_ values: [String?]) -> String? {
        for value in values {
            guard let value else {
                continue
            }

            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedValue.isEmpty == false else {
                continue
            }

            return trimmedValue
        }

        return nil
    }

    private func deduplicatedNonEmptyValues(_ values: [String?]) -> [String] {
        var seenValues: Set<String> = []
        var result: [String] = []

        for value in values {
            guard let value else {
                continue
            }

            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedValue.isEmpty == false, seenValues.contains(trimmedValue) == false else {
                continue
            }

            seenValues.insert(trimmedValue)
            result.append(trimmedValue)
        }

        return result
    }
}
