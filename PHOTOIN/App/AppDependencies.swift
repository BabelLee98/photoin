//
//  AppDependencies.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import Foundation

struct AppDependencies {
    let travelPhotoRepository: any TravelPhotoRepository

    /// Builds the dependency container used by the current app target.
    static func live() -> AppDependencies {
        AppDependencies(
            travelPhotoRepository: SampleTravelPhotoRepository()
        )
    }

    /// Creates the home feature model with the app's current dependencies injected.
    @MainActor
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            repository: travelPhotoRepository,
            explorationService: TravelPhotoExplorationService()
        )
    }
}
