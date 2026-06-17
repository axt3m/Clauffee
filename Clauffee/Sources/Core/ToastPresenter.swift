//
//  ToastPresenter.swift
//  Clauffee
//
//  La bulle : NSPanel sans bordure, level .statusBar (au-dessus de TOUT,
//  Xcode inclus), .canJoinAllSpaces. Apparition 0,25 s, maintien ~3,5 s,
//  fondu 2,5 s.
//

import AppKit
import SwiftUI

@MainActor
final class ToastPresenter {

    static let shared = ToastPresenter()
    private init() {}

    private var panel: NSPanel?
    private var fadeWorkItem: DispatchWorkItem?

    func show(emoji: String, text: String, palette: Palette) {
        dismiss()

        // ToastView a une largeur FIXE (voir sa def) : toutes les bulles font
        // la même taille → position parfaitement constante d'un toast à l'autre.
        let hosting = NSHostingView(rootView: ToastView(emoji: emoji,
                                                        text: text,
                                                        palette: palette))
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize
        hosting.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.contentView = hosting

        // Écran PRINCIPAL (barre de menus) — pas NSScreen.main, qui suit la
        // fenêtre active. On ancre le bord HAUT à une position ABSOLUE
        // (frame, pas visibleFrame) : visibleFrame change selon que la barre
        // de menus est visible (fenêtré) ou masquée (plein écran), ce qui
        // faisait sauter le toast verticalement. frame.maxY est constant.
        // Écran principal (celui qui porte la barre de menus / l'encoche),
        // repéré par son origine (0,0) — robuste en multi-écrans.
        let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero })
            ?? NSScreen.main ?? NSScreen.screens.first
        if let screen = primary {
            let x = screen.frame.midX - size.width / 2
            let topY = screen.frame.maxY - 44   // centré, juste sous l'encoche
            panel.setFrameTopLeftPoint(NSPoint(x: x, y: topY))
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 1
        }

        self.panel = panel

        let fade = DispatchWorkItem { [weak self, weak panel] in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 2.5
                panel?.animator().alphaValue = 0
            }, completionHandler: {
                panel?.orderOut(nil)
                // Le completion handler s'exécute sur le main thread :
                // on peut supposer l'isolation MainActor pour toucher `panel`.
                MainActor.assumeIsolated {
                    if self?.panel === panel { self?.panel = nil }
                }
            })
        }
        fadeWorkItem = fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8, execute: fade)
    }

    func dismiss() {
        fadeWorkItem?.cancel()
        fadeWorkItem = nil
        panel?.orderOut(nil)
        panel = nil
    }
}

// MARK: - Vue de la bulle

struct ToastView: View {
    let emoji: String
    let text: String
    let palette: Palette

    var body: some View {
        HStack(spacing: 9) {
            Text(emoji).font(.system(size: 16))
            Text(text)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(palette.text1)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.leading, 13)
        .padding(.trailing, 17)
        .padding(.vertical, 10)
        // Largeur fixe : la bulle ne change jamais de taille ni de position.
        .frame(width: 300, alignment: .leading)
        .background(
            Capsule()
                .fill(palette.popBg)
                .overlay(Capsule().strokeBorder(palette.cardBorder, lineWidth: 1))
                .shadow(color: .black.opacity(0.30), radius: 16, y: 8)
        )
        .padding(12) // marge pour l'ombre dans le panel
    }
}
