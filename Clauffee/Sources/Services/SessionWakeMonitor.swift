//
//  SessionWakeMonitor.swift
//  Clauffee
//
//  Détecte le retour de l'utilisateur INDÉPENDAMMENT du capot : réveil
//  système (bouton power) et déverrouillage de session. Complète LidMonitor
//  pour les cas sans transition de capot — réveil clavier/power, écran
//  externe en clamshell, ou simple verrouillage sans fermeture du capot.
//
//  Les deux centres de notification utilisés délivrent sur le main thread,
//  donc `onWake` est appelé sur le main thread.
//

import AppKit
import Foundation

final class SessionWakeMonitor {

    /// Appelé sur le main thread au réveil de la machine ou au déverrouillage
    /// de la session.
    var onWake: (() -> Void)?

    private var observing = false

    var isRunning: Bool { observing }

    func start() {
        guard !observing else { return }
        observing = true

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handle),
            name: NSWorkspace.didWakeNotification,
            object: nil)

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handle),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil)
    }

    func stop() {
        guard observing else { return }
        observing = false
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func handle() {
        onWake?()
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
