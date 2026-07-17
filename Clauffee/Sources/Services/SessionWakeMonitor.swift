//
//  SessionWakeMonitor.swift
//  Clauffee
//
//  Détecte, INDÉPENDAMMENT du capot, le départ et le retour de l'utilisateur :
//  verrouillage de session (départ), déverrouillage et réveil système (retour).
//  Complète LidMonitor pour les cas sans transition de capot — lock/unlock sans
//  fermeture du capot, réveil clavier/power, écran externe en clamshell.
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

    /// Appelé sur le main thread au verrouillage de la session (sans fermeture
    /// du capot). Traité comme un « départ », au même titre que le capot fermé.
    var onLock: (() -> Void)?

    private var observing = false

    var isRunning: Bool { observing }

    func start() {
        guard !observing else { return }
        observing = true

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil)

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleWake),
            name: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil)

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleLock),
            name: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil)
    }

    func stop() {
        guard observing else { return }
        observing = false
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func handleWake() {
        onWake?()
    }

    @objc private func handleLock() {
        onLock?()
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
