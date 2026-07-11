//
//  PopoverChrome.swift
//  Clauffee
//
//  Fermeture du popover MenuBarExtra (style .window) par le code. MenuBarExtra
//  n'expose pas d'API de fermeture : on cible la fenêtre clé (le popover est
//  clé tant qu'on clique dedans) et on la ferme après un court fondu. L'alpha
//  est rétabli ensuite car MenuBarExtra réutilise la même fenêtre à la
//  réouverture.
//
//  Comme la fenêtre est RÉUTILISÉE, un fondu retardé doit être annulé si
//  l'utilisateur ferme le popover lui-même entre-temps — sinon on fermerait
//  une réouverture (cf. observer willClose ci-dessous).
//

import AppKit

@MainActor
enum PopoverChrome {

    private static var pending: DispatchWorkItem?
    private static var observer: NSObjectProtocol?

    /// Fait disparaître le popover en fondu puis le ferme. `after` retarde le
    /// départ du fondu (pour le synchroniser avec un toast). La fenêtre clé est
    /// capturée MAINTENANT. Si l'utilisateur ferme le popover avant l'échéance,
    /// le fondu est annulé.
    static func fadeOutAndClose(after delay: TimeInterval = 0, duration: TimeInterval = 0.28) {
        guard let window = NSApp.keyWindow else { return }

        cancelPending()   // une seule fermeture programmée à la fois

        func run() {
            cleanup()
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = duration
                window.animator().alphaValue = 0
            }, completionHandler: {
                MainActor.assumeIsolated {
                    window.close()
                    window.alphaValue = 1   // rétabli pour la prochaine ouverture
                }
            })
        }

        guard delay > 0 else { run(); return }

        // Fermeture manuelle avant l'échéance → on annule (réouverture protégée).
        observer = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification, object: window, queue: .main) { _ in
            MainActor.assumeIsolated { cancelPending() }
        }

        let work = DispatchWorkItem { MainActor.assumeIsolated { run() } }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private static func cancelPending() {
        pending?.cancel()
        pending = nil
        cleanup()
    }

    private static func cleanup() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }
}

/// Ferme le popover en fondu après une période d'INACTIVITÉ (aucun clic,
/// touche, scroll ni mouvement souris dans l'app). Démarré à l'ouverture du
/// popover, arrêté à sa fermeture. Un moniteur d'événements local rafraîchit
/// l'horodatage d'activité ; un timer périodique vérifie le délai.
@MainActor
final class PopoverIdleCloser {

    static let shared = PopoverIdleCloser()
    private init() {}

    private enum Const {
        static let timeout: TimeInterval = 120        // 2 min d'inactivité
        static let checkInterval: TimeInterval = 10
    }

    private var monitor: Any?
    private var timer: Timer?
    private var lastActivity = Date()

    func start() {
        stop()
        lastActivity = Date()
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown,
                       .keyDown, .scrollWheel, .mouseMoved, .leftMouseDragged]
        ) { [weak self] event in
            MainActor.assumeIsolated { self?.lastActivity = Date() }
            return event
        }
        let t = Timer(timeInterval: Const.checkInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func tick() {
        guard Date().timeIntervalSince(lastActivity) >= Const.timeout else { return }
        stop()
        PopoverChrome.fadeOutAndClose()
    }
}
