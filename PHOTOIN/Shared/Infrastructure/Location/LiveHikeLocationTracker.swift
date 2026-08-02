//
//  LiveHikeLocationTracker.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import CoreLocation
import Foundation

@MainActor
final class LiveHikeLocationTracker: NSObject, HikeLocationTracking {
    private let locationManager = CLLocationManager()
    private var continuation: AsyncStream<HikeLocationTrackingEvent>.Continuation?
    private var isTracking = false
    private let maximumLocationAge: TimeInterval = 20

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    /// Returns the current Core Location authorization status.
    func authorizationStatus() -> CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    /// Starts an async location event stream and requests permission if the user has not decided yet.
    func startTracking() -> AsyncStream<HikeLocationTrackingEvent> {
        stopTracking()
        isTracking = true

        return AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            self.continuation = continuation
            continuation.yield(.authorizationChanged(self.locationManager.authorizationStatus))
            self.startUpdatesIfPossible()

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.handleStreamTermination()
                }
            }
        }
    }

    /// Stops foreground location updates and completes the current tracking stream.
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        continuation?.finish()
        continuation = nil
    }

    /// Starts updates immediately when authorized, or requests permission when still undecided.
    private func startUpdatesIfPossible() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            continuation?.yield(.authorizationChanged(locationManager.authorizationStatus))
        @unknown default:
            continuation?.yield(.authorizationChanged(locationManager.authorizationStatus))
        }
    }

    /// Clears the active stream state after AsyncStream termination.
    private func handleStreamTermination() {
        locationManager.stopUpdatingLocation()
        continuation = nil
        isTracking = false
    }
}

@MainActor
extension LiveHikeLocationTracker: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        continuation?.yield(.authorizationChanged(manager.authorizationStatus))

        guard isTracking else {
            return
        }

        startUpdatesIfPossible()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { location in
            guard isRecent(location) else {
                return
            }

            continuation?.yield(.locationUpdated(HikeLocationSample(location: location)))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.yield(.failed(error.localizedDescription))
    }

    /// Drops cached or future-skewed Core Location samples before they can pull the route away from the current trail.
    private func isRecent(_ location: CLLocation) -> Bool {
        let age = -location.timestamp.timeIntervalSinceNow
        return age >= 0 && age <= maximumLocationAge
    }
}
