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

private struct Constants {
    // Timings
    static let appearDuration: TimeInterval = 0.25
    static let fadeDuration: TimeInterval = 2.5
    static let holdDuration: TimeInterval = 3.8   // avant de lancer le fondu
    // Position
    static let topInset: CGFloat = 44             // sous l'encoche
    // Bulle
    static let maxBubbleWidth: CGFloat = 320      // plafond : au-delà, le texte passe à la ligne
    static let hSpacing: CGFloat = 9
    static let emojiFontSize: CGFloat = 16
    static let textFontSize: CGFloat = 12.5
    static let hPadding: CGFloat = 16             // padding gauche = droite
    static let verticalPadding: CGFloat = 10
    static let outerPadding: CGFloat = 12         // marge pour l'ombre
    static let borderWidth: CGFloat = 1
    static let shadowOpacity: Double = 0.30
    static let shadowRadius: CGFloat = 16
    static let shadowY: CGFloat = 8
}

@MainActor
final class ToastPresenter {

    static let shared = ToastPresenter()
    private init() {}

    /// Durées exposées pour synchroniser d'autres disparitions (ex. la
    /// fermeture du popover, qui doit fondre en même temps que la bulle).
    static let holdDuration: TimeInterval = Constants.holdDuration
    static let fadeDuration: TimeInterval = Constants.fadeDuration

    private var panel: NSPanel?
    private var fadeWorkItem: DispatchWorkItem?

    func show(emoji: String, text: String, palette: Palette) {
        dismiss()

        // La bulle épouse son contenu, plafonnée à maxBubbleWidth. Mesure en
        // deux passes : (1) largeur idéale sur une ligne, (2) hauteur réelle une
        // fois la largeur bornée (pour que les longs messages passent à la
        // ligne au lieu d'être tronqués). On recentre ensuite à l'écran à partir
        // de la largeur réelle (voir plus bas).
        let probe = NSHostingView(rootView: ToastView(emoji: emoji, text: text,
                                                      palette: palette, fixedWidth: nil))
        probe.layoutSubtreeIfNeeded()
        let idealBubble = probe.fittingSize.width - Constants.outerPadding * 2
        let bubbleWidth = min(idealBubble, Constants.maxBubbleWidth)

        let hosting = NSHostingView(rootView: ToastView(emoji: emoji, text: text,
                                                        palette: palette, fixedWidth: bubbleWidth))
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
            let topY = screen.frame.maxY - Constants.topInset   // centré, juste sous l'encoche
            panel.setFrameTopLeftPoint(NSPoint(x: x, y: topY))
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = Constants.appearDuration
            panel.animator().alphaValue = 1
        }

        self.panel = panel

        let fade = DispatchWorkItem { [weak self, weak panel] in
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = Constants.fadeDuration
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
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.holdDuration, execute: fade)
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
    /// nil → la bulle épouse le contenu (passe de mesure). Sinon largeur imposée
    /// (le texte passe à la ligne à l'intérieur). Voir ToastPresenter.show().
    var fixedWidth: CGFloat? = nil

    var body: some View {
        HStack(spacing: Constants.hSpacing) {
            Text(emoji).font(.system(size: Constants.emojiFontSize))
            Text(text)
                .font(.system(size: Constants.textFontSize, weight: .semibold))
                .foregroundStyle(palette.text1)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Constants.hPadding)
        .padding(.vertical, Constants.verticalPadding)
        // nil = épouse le contenu (petit message → petite bulle) ; valeur =
        // largeur bornée pour le passage à la ligne des longs messages.
        .frame(width: fixedWidth)
        .background(
            Capsule()
                .fill(palette.popBg)
                .overlay(Capsule().strokeBorder(palette.cardBorder, lineWidth: Constants.borderWidth))
                .shadow(color: .black.opacity(Constants.shadowOpacity), radius: Constants.shadowRadius, y: Constants.shadowY)
        )
        .padding(Constants.outerPadding) // marge pour l'ombre dans le panel
    }
}
