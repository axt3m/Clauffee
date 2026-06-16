//
//  CupView.swift
//  CaffeLatte
//
//  La tasse animée. Tout est piloté par UN TimelineView (déterministe,
//  pas de conflit withAnimation/TimelineView) :
//   · vagues double couche + bob du liquide
//   · montée (1,7 s) / vidage (1,35 s) avec easing smoothstep
//   · crema qui apparaît en surface
//   · vapeur (3 volutes) dont l'intensité suit le niveau
//   · au vidage : sautillement amorti de la tasse + 3 gouttes éjectées
//

import SwiftUI

struct CupView: View {

    let isBrewing: Bool
    let drainTrigger: Int
    let palette: Palette

    @State private var fillFrom: CGFloat = 0
    @State private var fillTo: CGFloat = 0
    @State private var fillStart: Date = .distantPast
    @State private var fillDuration: Double = 0.01
    @State private var drainStart: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let now = timeline.date
            let t = now.timeIntervalSinceReferenceDate
            let level = currentLevel(at: now)
            let hop = hopValues(at: now)

            ZStack {
                // Liquide, clippé dans la tasse
                ZStack {
                    WaveShape(phase: CGFloat(t) * 1.9, level: level,
                              amplitude: 2.0, surfaceOffset: 0)
                        .fill(LinearGradient(colors: [palette.liquidTop, palette.liquidBottom],
                                             startPoint: .top, endPoint: .bottom))
                    WaveShape(phase: -CGFloat(t) * 1.25 + 1.7, level: level,
                              amplitude: 2.3, surfaceOffset: 1.1)
                        .fill(palette.liquidTop.opacity(0.5))
                    CremaShape(level: level)
                        .fill(palette.cremaSurface)
                        .opacity(cremaOpacity(level))
                }
                .clipShape(CupBodyShape())

                // Contours
                CupBodyShape()
                    .stroke(palette.text1,
                            style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                HandleShape()
                    .stroke(palette.text1,
                            style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                SaucerShape()
                    .stroke(palette.text1,
                            style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

                // Vapeur — suit le niveau du liquide
                ForEach(0..<3, id: \.self) { index in
                    let phase = steamPhase(t: t, index: index)
                    SteamShape(index: index)
                        .stroke(palette.text2,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .opacity(sin(phase * .pi) * 0.85 * Double(level))
                        .offset(y: CGFloat(2 - 6 * phase))
                }

                // Gouttes éjectées au vidage
                if let start = drainStart {
                    let progress = CGFloat(min(1, max(0, now.timeIntervalSince(start) / 0.9)))
                    if progress < 1 {
                        DropsShape(progress: progress)
                            .fill(LinearGradient(colors: [palette.liquidTop, palette.liquidBottom],
                                                 startPoint: .top, endPoint: .bottom))
                            .opacity(dropsOpacity(progress))
                    }
                }
            }
            .rotationEffect(.degrees(hop.rotation), anchor: UnitPoint(x: 0.5, y: 0.8))
            .offset(y: hop.offsetY)
        }
        .onChange(of: isBrewing) { _, brewing in
            let now = Date()
            fillFrom = currentLevel(at: now)
            fillTo = brewing ? 1 : 0
            fillStart = now
            fillDuration = brewing ? 1.7 : 1.35
        }
        .onChange(of: drainTrigger) { _, _ in
            drainStart = Date()
        }
        .onAppear {
            fillFrom = isBrewing ? 1 : 0
            fillTo = fillFrom
        }
    }

    // MARK: - Calculs temporels

    private func currentLevel(at date: Date) -> CGFloat {
        let raw = date.timeIntervalSince(fillStart) / fillDuration
        let clamped = CGFloat(min(1, max(0, raw)))
        let eased = clamped * clamped * (3 - 2 * clamped) // smoothstep
        return fillFrom + (fillTo - fillFrom) * eased
    }

    private func cremaOpacity(_ level: CGFloat) -> Double {
        Double(max(0, (level - 0.86) / 0.14))
    }

    private func steamPhase(t: Double, index: Int) -> Double {
        let cycle = 2.6
        let shifted = t + Double(index) * 0.55
        return shifted.truncatingRemainder(dividingBy: cycle) / cycle
    }

    private func dropsOpacity(_ p: CGFloat) -> Double {
        p < 0.18 ? Double(p / 0.18) : Double(max(0, 1 - (p - 0.18) / 0.82))
    }

    /// Sautillement amorti (rotation + translation) après le déclenchement du vidage.
    private func hopValues(at date: Date) -> (rotation: Double, offsetY: CGFloat) {
        guard let start = drainStart else { return (0, 0) }
        let t = date.timeIntervalSince(start)
        guard t >= 0, t < 1.4 else { return (0, 0) }
        let rotation = -18.5 * exp(-3.2 * t) * sin(6.5 * t)
        let dy = -8.0 * exp(-3.2 * t) * abs(sin(6.5 * t))
        return (rotation, CGFloat(dy))
    }
}

// MARK: - Géométrie (espace 64×64 → rect)

private func unitTransform(in rect: CGRect) -> CGAffineTransform {
    let scale = min(rect.width, rect.height) / 64
    let dx = (rect.width - 64 * scale) / 2
    let dy = (rect.height - 64 * scale) / 2
    return CGAffineTransform(translationX: rect.minX + dx, y: rect.minY + dy)
        .scaledBy(x: scale, y: scale)
}

/// Corps de la tasse — sert de clip pour le liquide ET de contour.
struct CupBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 17, y: 26))
        p.addLine(to: CGPoint(x: 47, y: 26))
        p.addLine(to: CGPoint(x: 44, y: 45))
        p.addQuadCurve(to: CGPoint(x: 37.6, y: 50.4), control: CGPoint(x: 43.2, y: 50.4))
        p.addLine(to: CGPoint(x: 26.4, y: 50.4))
        p.addQuadCurve(to: CGPoint(x: 20, y: 45), control: CGPoint(x: 20.8, y: 50.4))
        p.closeSubpath()
        return p.applying(unitTransform(in: rect))
    }
}

struct HandleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 46.5, y: 30))
        p.addCurve(to: CGPoint(x: 45.5, y: 39),
                   control1: CGPoint(x: 55, y: 29.5),
                   control2: CGPoint(x: 55, y: 39.5))
        return p.applying(unitTransform(in: rect))
    }
}

struct SaucerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 14, y: 56))
        p.addLine(to: CGPoint(x: 50, y: 56))
        return p.applying(unitTransform(in: rect))
    }
}

struct SteamShape: Shape {
    let index: Int
    func path(in rect: CGRect) -> Path {
        let xs: [CGFloat] = [24, 32, 40]
        let x = xs[min(index, 2)]
        var p = Path()
        p.move(to: CGPoint(x: x, y: 16))
        p.addCurve(to: CGPoint(x: x, y: 8),
                   control1: CGPoint(x: x - 2, y: 13),
                   control2: CGPoint(x: x + 2, y: 11.5))
        return p.applying(unitTransform(in: rect))
    }
}

/// Surface du liquide : sinusoïde + bob, niveau 0 (vide) → 1 (plein).
struct WaveShape: Shape {
    var phase: CGFloat
    var level: CGFloat
    var amplitude: CGFloat
    var surfaceOffset: CGFloat

    private var surfaceY: CGFloat {
        let full: CGFloat = 30
        let empty: CGFloat = 56
        let bob = sin(phase * 0.33) * 0.8 * level
        return empty + (full - empty) * level + surfaceOffset + bob
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let y = surfaceY
        let startX: CGFloat = -10
        let width: CGFloat = 84
        let waves: CGFloat = 4

        p.move(to: CGPoint(x: startX, y: y))
        var i: CGFloat = 0
        while i <= 1.0001 {
            let x = startX + width * i
            let yy = y + sin(i * .pi * 2 * waves + phase) * amplitude
            p.addLine(to: CGPoint(x: x, y: yy))
            i += 0.02
        }
        p.addLine(to: CGPoint(x: startX + width, y: 70))
        p.addLine(to: CGPoint(x: startX, y: 70))
        p.closeSubpath()
        return p.applying(unitTransform(in: rect))
    }
}

/// Crema en surface — suit le niveau, fade géré par la vue.
struct CremaShape: Shape {
    var level: CGFloat
    func path(in rect: CGRect) -> Path {
        let full: CGFloat = 30
        let empty: CGFloat = 56
        let cy = empty + (full - empty) * level + 0.6
        var p = Path()
        p.addEllipse(in: CGRect(x: 32 - 13, y: cy - 2.6, width: 26, height: 5.2))
        return p.applying(unitTransform(in: rect))
    }
}

/// Trois gouttes éjectées vers le haut, avec léger décalage entre elles.
struct DropsShape: Shape {
    var progress: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let drops: [(x: CGFloat, y: CGFloat, r: CGFloat, delay: CGFloat)] = [
            (25, 22, 2.0, 0.00),
            (33, 20, 2.4, 0.12),
            (40, 22, 1.8, 0.22),
        ]
        for drop in drops {
            let local = max(0, min(1, (progress - drop.delay) / (1 - drop.delay)))
            let y = drop.y - 18 * local
            p.addEllipse(in: CGRect(x: drop.x - drop.r, y: y - drop.r,
                                    width: drop.r * 2, height: drop.r * 2))
        }
        return p.applying(unitTransform(in: rect))
    }
}
