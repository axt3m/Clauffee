//
//  VisualEffectView.swift
//  CaffeLatte
//
//  Translucidité « menu macOS » (vibrancy) pour le popover et les feuilles.
//  Enveloppe un NSVisualEffectView en blending .behindWindow et rend la
//  fenêtre hôte non opaque — sinon le flou du bureau ne traverse pas.
//

import AppKit
import SwiftUI

struct VisualEffectView: NSViewRepresentable {

    var material: NSVisualEffectView.Material = .menu
    // .withinWindow : la vibrancy se compose DANS la fenêtre, sans exiger une
    // fenêtre transparente. On évite ainsi de toucher `window.isOpaque`, qui
    // cassait la composition des overlays (onboarding) sur le MenuBarExtra.
    var blending: NSVisualEffectView.BlendingMode = .withinWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blending
        view.state = .active
    }
}
