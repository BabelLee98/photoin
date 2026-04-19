//
//  HikeLocationTracking.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Foundation

enum HikeLocationTrackingEvent {
    case authorizationChanged(CLAuthorizationStatus)
    case locationUpdated(HikeLocationSample)
    case failed(String)
}

@MainActor
protocol HikeLocationTracking {
    /// Returns the current authorization state so the feature can decide whether recording may start.
    func authorizationStatus() -> CLAuthorizationStatus

    /// Starts producing authorization and location events for the current foreground recording session.
    func startTracking() -> AsyncStream<HikeLocationTrackingEvent>

    /// Stops the active foreground recording session and ends the current event stream.
    func stopTracking()
}
