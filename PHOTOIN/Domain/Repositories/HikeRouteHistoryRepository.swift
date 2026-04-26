//
//  HikeRouteHistoryRepository.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/26.
//

import Foundation

@MainActor
protocol HikeRouteHistoryRepository {
    /// Returns the completed hiking routes currently available to the app.
    func fetchRecordedRoutes() -> [HikeRoute]

    /// Stores a completed route so other features can summarize it later.
    func saveRecordedRoute(_ route: HikeRoute)
}
