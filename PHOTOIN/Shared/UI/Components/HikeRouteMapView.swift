//
//  HikeRouteMapView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import MapKit
import SwiftUI

struct HikeRouteMapView: UIViewRepresentable {
    let route: HikeRoute
    let latestSample: HikeLocationSample?
    let mapType: MKMapType
    let showsUserLocation: Bool

    private static let shanghaiCenter = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.overrideUserInterfaceStyle = .dark
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsTraffic = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.setRegion(defaultRegion(), animated: false)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Coordinator.checkpointReuseIdentifier)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }
        mapView.showsUserLocation = showsUserLocation
        context.coordinator.showsUserLocation = showsUserLocation
        context.coordinator.shouldCenterOnUserLocationWhenEmpty = route.points.isEmpty && route.checkpoints.isEmpty && latestSample == nil
        syncRoute(on: mapView, coordinator: context.coordinator)
        syncCheckpoints(on: mapView, coordinator: context.coordinator)
        updateVisibleRegion(on: mapView, coordinator: context.coordinator)
        updateDefaultRegionIfNeeded(on: mapView, coordinator: context.coordinator)
    }

    /// Keeps the polyline overlay aligned with the current route points.
    private func syncRoute(on mapView: MKMapView, coordinator: Coordinator) {
        guard coordinator.lastPointCount != route.points.count else {
            return
        }

        mapView.removeOverlays(mapView.overlays)

        if route.points.count > 1 {
            let coordinates = route.points.map { $0.coordinate.clCoordinate }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
        }

        coordinator.lastPointCount = route.points.count
    }

    /// Keeps checkpoint markers aligned with the route summary list.
    private func syncCheckpoints(on mapView: MKMapView, coordinator: Coordinator) {
        guard coordinator.lastCheckpointCount != route.checkpoints.count else {
            return
        }

        let existingAnnotations = mapView.annotations.compactMap { $0 as? HikeCheckpointAnnotation }
        mapView.removeAnnotations(existingAnnotations)
        mapView.addAnnotations(route.checkpoints.map(HikeCheckpointAnnotation.init(checkpoint:)))
        coordinator.lastCheckpointCount = route.checkpoints.count
    }

    /// Recenters the initial viewport around the latest route content without fighting the user's own dragging.
    private func updateVisibleRegion(on mapView: MKMapView, coordinator: Coordinator) {
        if coordinator.lastRouteID != route.id {
            coordinator.lastRouteID = route.id
            coordinator.didFocusCurrentRoute = false
            coordinator.emptyStateCenter = nil
        }

        let contentCount = route.points.count + route.checkpoints.count
        guard coordinator.didFocusCurrentRoute == false,
              contentCount > 0 else {
            return
        }

        coordinator.didFocusCurrentRoute = true
        coordinator.emptyStateCenter = nil

        if route.points.count > 1 {
            let polylineBoundingRect = MKPolyline(
                coordinates: route.points.map { $0.coordinate.clCoordinate },
                count: route.points.count
            ).boundingMapRect

            let paddedRect = mapView.mapRectThatFits(
                polylineBoundingRect,
                edgePadding: UIEdgeInsets(top: 70, left: 40, bottom: 70, right: 40)
            )
            mapView.setVisibleMapRect(paddedRect, animated: true)
            return
        }

        if let coordinate = route.points.first?.coordinate ?? latestSample?.coordinate {
            mapView.setRegion(Self.region(around: coordinate.clCoordinate), animated: true)
        }
    }

    /// Applies the empty-state center rule: user location when authorized, otherwise Shanghai.
    private func updateDefaultRegionIfNeeded(on mapView: MKMapView, coordinator: Coordinator) {
        guard route.points.isEmpty, route.checkpoints.isEmpty, latestSample == nil else {
            return
        }

        if showsUserLocation,
           let coordinate = mapView.userLocation.location?.coordinate,
           coordinator.emptyStateCenter != .userLocation {
            mapView.setRegion(Self.region(around: coordinate), animated: true)
            coordinator.emptyStateCenter = .userLocation
            return
        }

        guard coordinator.emptyStateCenter != .shanghai else {
            return
        }

        mapView.setRegion(Self.region(around: Self.shanghaiCenter), animated: false)
        coordinator.emptyStateCenter = .shanghai
    }

    /// Builds the initial 3-kilometer region used before the map has enough route content to fit.
    private func defaultRegion() -> MKCoordinateRegion {
        let center = route.latestCoordinate?.clCoordinate
            ?? Self.shanghaiCenter

        return Self.region(around: center)
    }

    /// Returns a nearby region spanning roughly 3 kilometers around the provided center coordinate.
    private static func region(around coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 3_000,
            longitudinalMeters: 3_000
        )
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        static let checkpointReuseIdentifier = "HikeCheckpointMarker"

        enum EmptyStateCenter {
            case shanghai
            case userLocation
        }

        var lastPointCount = 0
        var lastCheckpointCount = 0
        var lastRouteID: UUID?
        var didFocusCurrentRoute = false
        var showsUserLocation = false
        var shouldCenterOnUserLocationWhenEmpty = true
        var emptyStateCenter: EmptyStateCenter?

        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(red: 0.52, green: 0.58, blue: 0.61, alpha: 0.9)
            renderer.lineWidth = 5
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard let checkpointAnnotation = annotation as? HikeCheckpointAnnotation else {
                return nil
            }

            let markerView = mapView.dequeueReusableAnnotationView(
                withIdentifier: Self.checkpointReuseIdentifier,
                for: checkpointAnnotation
            ) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(
                annotation: checkpointAnnotation,
                reuseIdentifier: Self.checkpointReuseIdentifier
            )

            markerView.annotation = checkpointAnnotation
            markerView.canShowCallout = true
            markerView.animatesWhenAdded = true
            markerView.markerTintColor = UIColor(red: 0.44, green: 0.49, blue: 0.53, alpha: 1)
            markerView.glyphImage = UIImage(systemName: "flag.fill")
            markerView.glyphTintColor = .white
            markerView.displayPriority = .required
            markerView.layer.shadowColor = UIColor.black.cgColor
            markerView.layer.shadowOpacity = 0.18
            markerView.layer.shadowRadius = 8
            markerView.layer.shadowOffset = CGSize(width: 0, height: 4)
            return markerView
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard showsUserLocation,
                  shouldCenterOnUserLocationWhenEmpty,
                  emptyStateCenter != .userLocation,
                  let coordinate = userLocation.location?.coordinate else {
                return
            }

            mapView.setRegion(HikeRouteMapView.region(around: coordinate), animated: true)
            emptyStateCenter = .userLocation
        }
    }
}

private final class HikeCheckpointAnnotation: NSObject, MKAnnotation {
    let checkpoint: HikeRoute.Checkpoint

    nonisolated var coordinate: CLLocationCoordinate2D {
        checkpoint.coordinate.clCoordinate
    }

    nonisolated var title: String? {
        checkpoint.title
    }

    nonisolated var subtitle: String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: checkpoint.timestamp)
    }

    nonisolated init(checkpoint: HikeRoute.Checkpoint) {
        self.checkpoint = checkpoint
    }
}

#Preview {
    HikeRouteMapView(
        route: .empty,
        latestSample: nil,
        mapType: .mutedStandard,
        showsUserLocation: false
    )
    .frame(height: 360)
}
