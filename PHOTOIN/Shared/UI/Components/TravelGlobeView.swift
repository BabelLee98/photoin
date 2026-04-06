//
//  TravelGlobeView.swift
//  PHOTOIN
//
//  Created by Codex on 2026/4/6.
//

import SwiftUI

struct TravelGlobeView: View {
    let photos: [TravelPhoto]
    let highlightedPhotoID: TravelPhoto.ID?
    @Binding var rotation: Double

    @State private var dragStartRotation = 0.0
    @State private var autoRotationStartDate = Date()
    @State private var isDragging = false

    private let autoRotationDegreesPerSecond = 2.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isDragging)) { context in
            let displayedRotation = currentDisplayedRotation(at: context.date)
            let highlightPulse = currentHighlightPulse(at: context.date)

            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let radius = size * 0.42
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.33, green: 0.40, blue: 0.46),
                                    Color(red: 0.15, green: 0.19, blue: 0.23)
                                ],
                                center: .init(x: 0.34, y: 0.28),
                                startRadius: 12,
                                endRadius: radius * 1.9
                            )
                        )
                        .overlay {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.18),
                                            Color.clear,
                                            Color.black.opacity(0.16)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.14), lineWidth: 1.2)
                        }
                        .frame(width: radius * 2, height: radius * 2)

                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 16)
                        .blur(radius: 8)
                        .frame(width: radius * 2.1, height: radius * 2.1)

                    GlobeGridOverlay(
                        rotation: displayedRotation,
                        radius: radius,
                        center: center
                    )

                    ForEach(photos) { photo in
                        let projection = GlobeMarkerProjection(
                            coordinate: photo.coordinate,
                            rotation: displayedRotation,
                            radius: radius,
                            center: center
                        )

                        if projection.isVisible {
                            GlobeMarkerView(
                                photo: photo,
                                isHighlighted: photo.id == highlightedPhotoID,
                                depth: projection.depth,
                                pulseProgress: highlightPulse
                            )
                            .position(projection.point)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    if isDragging == false {
                        beginDragging(at: Date())
                    }
                    rotation = dragStartRotation + (value.translation.width * 0.35)
                }
                .onEnded { _ in
                    dragStartRotation = rotation
                    autoRotationStartDate = Date()
                    isDragging = false
                }
        )
        .onAppear {
            dragStartRotation = rotation
            autoRotationStartDate = Date()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("旅行地球")
        .accessibilityHint("地球会缓慢自转，左右滑动可以切换不同地点的照片")
    }

    /// Returns the angle currently shown on screen, including the slow idle auto-rotation.
    private func currentDisplayedRotation(at date: Date) -> Double {
        guard isDragging == false else {
            return rotation
        }

        return rotation + date.timeIntervalSince(autoRotationStartDate) * autoRotationDegreesPerSecond
    }

    /// Converts the current time into a soft pulse so the selected photo marker stands out without flashing.
    private func currentHighlightPulse(at date: Date) -> Double {
        let wave = sin(date.timeIntervalSinceReferenceDate * 2.4)
        return (wave + 1) / 2
    }

    /// Locks the current auto-rotated angle into the bound rotation before a manual drag begins.
    private func beginDragging(at date: Date) {
        let displayedRotation = currentDisplayedRotation(at: date)
        rotation = displayedRotation
        dragStartRotation = displayedRotation
        autoRotationStartDate = date
        isDragging = true
    }
}

private struct GlobeMarkerView: View {
    let photo: TravelPhoto
    let isHighlighted: Bool
    let depth: Double
    let pulseProgress: Double

    var body: some View {
        let markerStyle = HomePhotoMarkerStyleProvider.style(for: photo)
        let clampedDepth = max(0.15, depth)
        let size = isHighlighted ? 36.0 : 24.0 + (clampedDepth * 10)

        ZStack {
            if isHighlighted {
                Circle()
                    .stroke(markerStyle.accentColor.opacity(0.45), lineWidth: 2)
                    .frame(width: size + 14, height: size + 14)
                    .scaleEffect(1.02 + (pulseProgress * 0.18))
                    .opacity(0.28 - (pulseProgress * 0.08))
            }

            Circle()
                .fill(markerStyle.accentColor.opacity(isHighlighted ? 0.95 : 0.82))

            if isHighlighted {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .padding(4)
            }

            Image(systemName: markerStyle.symbolName)
                .font(.system(size: isHighlighted ? 14 : 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.96))
        }
        .overlay {
            Circle()
                .stroke(Color.white.opacity(isHighlighted ? 0.8 : 0.3), lineWidth: isHighlighted ? 1.5 : 1)
        }
        .overlay(alignment: .bottom) {
            if isHighlighted {
                Capsule()
                    .fill(markerStyle.accentColor.opacity(0.9))
                    .frame(width: 4, height: 12)
                    .offset(y: 10)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: isHighlighted ? 10 : 6, y: 3)
        .frame(width: size, height: size)
        .opacity(0.45 + clampedDepth * 0.55)
        .scaleEffect(isHighlighted ? 1.05 : 0.92 + clampedDepth * 0.18)
    }
}

private struct GlobeGridOverlay: View {
    let rotation: Double
    let radius: CGFloat
    let center: CGPoint

    var body: some View {
        Canvas { context, _ in
            for latitude in stride(from: -60.0, through: 60.0, by: 30.0) {
                let path = latitudePath(latitude)
                let isEquator = latitude == 0
                context.stroke(
                    path,
                    with: .color(Color.white.opacity(isEquator ? 0.22 : 0.12)),
                    style: StrokeStyle(lineWidth: isEquator ? 1.4 : 0.9, lineCap: .round)
                )
            }

            for longitude in stride(from: -150.0, through: 180.0, by: 30.0) {
                let path = longitudePath(longitude)
                let isPrimeMeridian = longitude == 0
                context.stroke(
                    path,
                    with: .color(Color.white.opacity(isPrimeMeridian ? 0.18 : 0.1)),
                    style: StrokeStyle(lineWidth: isPrimeMeridian ? 1.2 : 0.8, lineCap: .round)
                )
            }
        }
        .mask {
            Circle()
                .frame(width: radius * 2, height: radius * 2)
                .position(center)
        }
    }

    /// Builds a visible front-hemisphere path for a latitude ring so the user can read north and south positions.
    private func latitudePath(_ latitude: Double) -> Path {
        let projections = stride(from: -180.0, through: 180.0, by: 6.0).map { longitude in
            GlobeMarkerProjection(
                latitude: latitude,
                longitude: longitude,
                rotation: rotation,
                radius: radius,
                center: center
            )
        }

        return visiblePath(from: projections)
    }

    /// Builds a visible front-hemisphere path for a longitude ring so the globe reads as a geographic surface.
    private func longitudePath(_ longitude: Double) -> Path {
        let projections = stride(from: -75.0, through: 75.0, by: 4.0).map { latitude in
            GlobeMarkerProjection(
                latitude: latitude,
                longitude: longitude,
                rotation: rotation,
                radius: radius,
                center: center
            )
        }

        return visiblePath(from: projections)
    }

    /// Keeps only the path segments that sit on the front side of the globe to avoid drawing confusing back-face lines.
    private func visiblePath(from projections: [GlobeMarkerProjection]) -> Path {
        var path = Path()
        var isDrawingSegment = false

        for projection in projections {
            if projection.depth > 0.02 {
                if isDrawingSegment {
                    path.addLine(to: projection.point)
                } else {
                    path.move(to: projection.point)
                    isDrawingSegment = true
                }
            } else {
                isDrawingSegment = false
            }
        }

        return path
    }
}

#Preview {
    TravelGlobeView(
        photos: SampleTravelPhotos.all,
        highlightedPhotoID: SampleTravelPhotos.all.first?.id,
        rotation: .constant(-20)
    )
    .frame(width: 320, height: 320)
    .padding()
    .background(Color(red: 0.93, green: 0.94, blue: 0.92))
}
