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
    let showsUserLocation: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.mapType = .mutedStandard
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsTraffic = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Coordinator.checkpointReuseIdentifier)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.showsUserLocation = showsUserLocation
        syncRoute(on: mapView, coordinator: context.coordinator)
        syncCheckpoints(on: mapView, coordinator: context.coordinator)
        updateVisibleRegion(on: mapView, coordinator: context.coordinator)
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
        }

        let contentCount = route.points.count + route.checkpoints.count
        guard coordinator.didFocusCurrentRoute == false,
              contentCount > 0 else {
            return
        }

        coordinator.didFocusCurrentRoute = true

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
            let region = MKCoordinateRegion(
                center: coordinate.clCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
            )
            mapView.setRegion(region, animated: true)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        static let checkpointReuseIdentifier = "HikeCheckpointMarker"

        var lastPointCount = 0
        var lastCheckpointCount = 0
        var lastRouteID: UUID?
        var didFocusCurrentRoute = false

        func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(red: 0.18, green: 0.22, blue: 0.24, alpha: 0.94)
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
            markerView.markerTintColor = UIColor(red: 0.39, green: 0.45, blue: 0.49, alpha: 1)
            markerView.glyphImage = UIImage(systemName: "flag.fill")
            markerView.glyphTintColor = .white
            markerView.displayPriority = .required
            return markerView
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
        showsUserLocation: false
    )
    .frame(height: 360)
}
