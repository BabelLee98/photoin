//
//  InMemoryHikeRouteHistoryRepository.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/26.
//

import Foundation

@MainActor
final class InMemoryHikeRouteHistoryRepository: HikeRouteHistoryRepository {
    private var recordedRoutes: [HikeRoute] = []

    /// Returns the completed routes accumulated during the current app session.
    func fetchRecordedRoutes() -> [HikeRoute] {
        recordedRoutes
    }

    /// Keeps the newest completed route at the front of the in-memory session history.
    func saveRecordedRoute(_ route: HikeRoute) {
        recordedRoutes.insert(route, at: 0)
    }
}
