//
//  TravelPhotoMapView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/19.
//

import MapKit
import SwiftUI

struct TravelPhotoMapView: UIViewRepresentable {
    let photos: [TravelPhoto]
    let mapType: MKMapType
    let selectedPhotoID: TravelPhoto.ID?
    let onSelectPhoto: (TravelPhoto.ID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectPhoto: onSelectPhoto)
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
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: Coordinator.annotationReuseIdentifier)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.onSelectPhoto = onSelectPhoto
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }
        syncAnnotations(on: mapView, coordinator: context.coordinator)
        syncSelection(on: mapView, coordinator: context.coordinator)
    }

    /// Keeps the map annotations aligned with the currently visible travel photos.
    private func syncAnnotations(on mapView: MKMapView, coordinator: Coordinator) {
        let newPhotoIDs = photos.map(\.id)
        let existingAnnotations = mapView.annotations.compactMap { $0 as? TravelPhotoAnnotation }
        let existingPhotoIDs = existingAnnotations.map(\.photo.id)

        guard newPhotoIDs != existingPhotoIDs else {
            return
        }

        mapView.removeAnnotations(existingAnnotations)

        let annotations = photos.map(TravelPhotoAnnotation.init(photo:))
        mapView.addAnnotations(annotations)
        coordinator.lastRenderedPhotoIDs = newPhotoIDs
        updateVisibleRegion(on: mapView, using: annotations)
    }

    /// Syncs the selected annotation so marker emphasis follows the featured photo state.
    private func syncSelection(on mapView: MKMapView, coordinator: Coordinator) {
        let annotations = mapView.annotations.compactMap { $0 as? TravelPhotoAnnotation }

        guard let selectedPhotoID else {
            annotations.forEach { annotation in
                mapView.deselectAnnotation(annotation, animated: true)
            }
            coordinator.selectedPhotoID = nil
            return
        }

        guard coordinator.selectedPhotoID != selectedPhotoID else {
            return
        }

        annotations.forEach { annotation in
            if annotation.photo.id == selectedPhotoID {
                mapView.selectAnnotation(annotation, animated: true)
            } else {
                mapView.deselectAnnotation(annotation, animated: true)
            }
        }

        coordinator.selectedPhotoID = selectedPhotoID
    }

    /// Re-centers the map around the current results so search updates stay visible without manual repositioning.
    private func updateVisibleRegion(on mapView: MKMapView, using annotations: [TravelPhotoAnnotation]) {
        guard annotations.isEmpty == false else {
            return
        }

        guard annotations.count > 1 else {
            let coordinate = annotations[0].coordinate
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
            )
            mapView.setRegion(region, animated: true)
            return
        }

        let mapRect = annotations
            .map { annotation in
                MKMapRect(
                    origin: MKMapPoint(annotation.coordinate),
                    size: MKMapSize(width: 0, height: 0)
                )
            }
            .reduce(MKMapRect.null) { partialResult, rect in
                partialResult.union(rect)
            }

        let edgePadding = UIEdgeInsets(top: 120, left: 70, bottom: 220, right: 70)
        mapView.setVisibleMapRect(mapRect, edgePadding: edgePadding, animated: true)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        static let annotationReuseIdentifier = "TravelPhotoMarker"

        var onSelectPhoto: (TravelPhoto.ID) -> Void
        var selectedPhotoID: TravelPhoto.ID?
        var lastRenderedPhotoIDs: [TravelPhoto.ID] = []
        private var thumbnailCache: [String: UIImage] = [:]

        init(onSelectPhoto: @escaping (TravelPhoto.ID) -> Void) {
            self.onSelectPhoto = onSelectPhoto
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            guard let travelPhotoAnnotation = annotation as? TravelPhotoAnnotation else {
                return nil
            }

            let markerView = mapView.dequeueReusableAnnotationView(
                withIdentifier: Self.annotationReuseIdentifier,
                for: travelPhotoAnnotation
            ) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(
                annotation: travelPhotoAnnotation,
                reuseIdentifier: Self.annotationReuseIdentifier
            )

            markerView.annotation = travelPhotoAnnotation
            configure(markerView, for: travelPhotoAnnotation.photo, isSelected: travelPhotoAnnotation.photo.id == selectedPhotoID)
            return markerView
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? TravelPhotoAnnotation else {
                return
            }

            selectedPhotoID = annotation.photo.id
            configureSelectionState(in: mapView)
            onSelectPhoto(annotation.photo.id)
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard view.annotation is TravelPhotoAnnotation else {
                return
            }

            configureSelectionState(in: mapView)
        }

        /// Refreshes annotation visuals after selection changes so the active location reads more clearly.
        private func configureSelectionState(in mapView: MKMapView) {
            let annotationViews = mapView.annotations.compactMap { annotation -> MKMarkerAnnotationView? in
                guard let photoAnnotation = annotation as? TravelPhotoAnnotation,
                      let view = mapView.view(for: photoAnnotation) as? MKMarkerAnnotationView else {
                    return nil
                }

                configure(view, for: photoAnnotation.photo, isSelected: photoAnnotation.photo.id == selectedPhotoID)
                return view
            }

            if annotationViews.isEmpty {
                return
            }
        }

        /// Applies the current visual style for photo markers while keeping selected locations more prominent.
        private func configure(_ markerView: MKMarkerAnnotationView, for photo: TravelPhoto, isSelected: Bool) {
            let markerStyle = HomePhotoMarkerStyleProvider.style(for: photo)
            let configuration = UIImage.SymbolConfiguration(pointSize: isSelected ? 15 : 13, weight: .semibold)
            let photoGlyphImage = thumbnailImage(for: photo, isSelected: isSelected)

            markerView.canShowCallout = false
            markerView.animatesWhenAdded = true
            markerView.markerTintColor = UIColor(markerStyle.accentColor)
            markerView.glyphImage = photoGlyphImage ?? UIImage(systemName: markerStyle.symbolName, withConfiguration: configuration)
            markerView.glyphTintColor = photoGlyphImage == nil ? .white : nil
            markerView.displayPriority = isSelected ? .required : .defaultHigh
            markerView.transform = isSelected ? CGAffineTransform(scaleX: 1.14, y: 1.14) : .identity
            markerView.layer.shadowColor = UIColor.black.cgColor
            markerView.layer.shadowOpacity = isSelected ? 0.24 : 0.14
            markerView.layer.shadowRadius = isSelected ? 10 : 6
            markerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        }

        /// Builds a small circular photo glyph so imported photos are visible directly inside their map bubbles.
        private func thumbnailImage(for photo: TravelPhoto, isSelected: Bool) -> UIImage? {
            let cacheKey = "\(photo.id.uuidString)-\(isSelected ? "selected" : "normal")"
            if let cachedImage = thumbnailCache[cacheKey] {
                return cachedImage
            }

            guard let previewImageData = photo.previewImageData,
                  let sourceImage = UIImage(data: previewImageData) else {
                return nil
            }

            let sideLength = isSelected ? 30.0 : 26.0
            let size = CGSize(width: sideLength, height: sideLength)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                UIBezierPath(ovalIn: rect).addClip()

                let scale = max(size.width / sourceImage.size.width, size.height / sourceImage.size.height)
                let drawSize = CGSize(width: sourceImage.size.width * scale, height: sourceImage.size.height * scale)
                let drawOrigin = CGPoint(
                    x: (size.width - drawSize.width) / 2,
                    y: (size.height - drawSize.height) / 2
                )
                sourceImage.draw(in: CGRect(origin: drawOrigin, size: drawSize))

                UIColor.white.withAlphaComponent(0.9).setStroke()
                context.cgContext.setLineWidth(2)
                context.cgContext.strokeEllipse(in: rect.insetBy(dx: 1, dy: 1))
            }
            .withRenderingMode(.alwaysOriginal)

            thumbnailCache[cacheKey] = image
            return image
        }
    }
}

private final class TravelPhotoAnnotation: NSObject, MKAnnotation {
    let photo: TravelPhoto

    nonisolated var coordinate: CLLocationCoordinate2D {
        photo.coordinate
    }

    nonisolated var title: String? {
        photo.locationName
    }

    nonisolated var subtitle: String? {
        photo.regionName
    }

    nonisolated init(photo: TravelPhoto) {
        self.photo = photo
    }
}

#Preview {
    TravelPhotoMapView(
        photos: SampleTravelPhotos.all,
        mapType: .mutedStandard,
        selectedPhotoID: SampleTravelPhotos.all.first?.id,
        onSelectPhoto: { _ in }
    )
    .frame(height: 340)
    .padding()
}
