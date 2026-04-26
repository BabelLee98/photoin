//
//  HomePhotoMarkerStyle.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import SwiftUI

struct HomePhotoMarkerStyle {
    let accentColor: Color
    let symbolName: String
}

enum HomePhotoMarkerStyleProvider {
    /// Returns the visual marker style used by the home globe for a given travel photo.
    static func style(for photo: TravelPhoto) -> HomePhotoMarkerStyle {
        switch photo.locationName {
        case "Cape Reinga":
            return HomePhotoMarkerStyle(
                accentColor: Color(red: 0.49, green: 0.59, blue: 0.62),
                symbolName: "camera.aperture"
            )
        case "河口湖":
            return HomePhotoMarkerStyle(
                accentColor: Color(red: 0.56, green: 0.56, blue: 0.60),
                symbolName: "mountain.2"
            )
        case "布拉格城堡":
            return HomePhotoMarkerStyle(
                accentColor: Color(red: 0.59, green: 0.52, blue: 0.47),
                symbolName: "building.columns"
            )
        case "Hallstatt":
            return HomePhotoMarkerStyle(
                accentColor: Color(red: 0.63, green: 0.67, blue: 0.70),
                symbolName: "snowflake"
            )
        case "上海外滩":
            return HomePhotoMarkerStyle(
                accentColor: Color(red: 0.35, green: 0.41, blue: 0.46),
                symbolName: "sparkles"
            )
        default:
            return HomePhotoMarkerStyle(
                accentColor: Color(red: 0.44, green: 0.49, blue: 0.53),
                symbolName: "photo"
            )
        }
    }
}
