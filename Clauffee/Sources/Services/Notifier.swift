//
//  Notifier.swift
//  Clauffee
//
//  Deux notifications « Te revoilà » à la réouverture du capot :
//   · BREW_ASK  — infusion encore active → Continuer / Arrêter
//   · BREW_DONE — infusion terminée pendant l'absence → durée + OK
//
//  La permission est demandée au premier brew, pas au lancement.
//

import AppKit
import Foundation
import UserNotifications

final class Notifier: NSObject, UNUserNotificationCenterDelegate {

    /// État simplifié pour l'UI (sans exposer UserNotifications aux vues).
    enum Permission { case notDetermined, authorized, denied }

    /// Style d'affichage choisi par l'utilisateur dans les Réglages Système.
    /// `banner` = Temporaire (auto-dismiss) · `alert` = Persistant (reste).
    enum AlertStyle { case silent, banner, alert, unknown }

    static let shared = Notifier()

    /// Branché par AppState : l'action « Arrêter » coupe l'infusion.
    var onStopRequested: (() -> Void)?

    private let askCategoryID = "BREW_ASK"
    private let doneCategoryID = "BREW_DONE"
    private let keepActionID = "KEEP"
    private let stopActionID = "STOP"
    private let okActionID = "OK"

    private var permissionRequested = false

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// (Ré)enregistre les catégories avec les titres localisés.
    /// À rappeler quand la langue change.
    func configure(strings: Strings) {
        let keep = UNNotificationAction(identifier: keepActionID,
                                        title: strings.keep,
                                        options: [])
        let stop = UNNotificationAction(identifier: stopActionID,
                                        title: strings.off,
                                        options: [])
        let ok = UNNotificationAction(identifier: okActionID,
                                      title: strings.ok,
                                      options: [])

        let ask = UNNotificationCategory(identifier: askCategoryID,
                                         actions: [keep, stop],
                                         intentIdentifiers: [],
                                         options: [])
        let done = UNNotificationCategory(identifier: doneCategoryID,
                                          actions: [ok],
                                          intentIdentifiers: [],
                                          options: [])

        UNUserNotificationCenter.current().setNotificationCategories([ask, done])
    }

    func requestPermissionIfNeeded() {
        guard !permissionRequested else { return }
        permissionRequested = true
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Permission + style d'alerte courants, renvoyés sur le main thread.
    func status(_ completion: @escaping (Permission, AlertStyle) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let perm: Permission
            switch settings.authorizationStatus {
            case .notDetermined: perm = .notDetermined
            case .denied: perm = .denied
            default: perm = .authorized
            }
            let style: AlertStyle
            switch settings.alertStyle {
            case .none: style = .silent
            case .banner: style = .banner
            case .alert: style = .alert
            @unknown default: style = .unknown
            }
            DispatchQueue.main.async { completion(perm, style) }
        }
    }

    /// État courant de la permission, renvoyé sur le main thread.
    func permissionState(_ completion: @escaping (Permission) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let state: Permission
            switch settings.authorizationStatus {
            case .notDetermined: state = .notDetermined
            case .denied: state = .denied
            default: state = .authorized   // authorized, provisional, ephemeral
            }
            DispatchQueue.main.async { completion(state) }
        }
    }

    /// Déclenche le popup système Allow/Don't Allow (1ʳᵉ fois seulement) et
    /// renvoie l'état résultant. Si déjà refusé, ouvre les Réglages Système.
    func requestPermission(_ completion: @escaping (Permission) -> Void) {
        permissionState { [weak self] current in
            switch current {
            case .notDetermined:
                self?.permissionRequested = true
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound]) { granted, _ in
                        DispatchQueue.main.async { completion(granted ? .authorized : .denied) }
                    }
            case .denied:
                self?.openSystemSettings()
                completion(.denied)
            case .authorized:
                completion(.authorized)
            }
        }
    }

    /// Ouvre le volet Notifications des Réglages Système (cas « déjà refusé »).
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    /// « Te revoilà ! 👋 On arrête l'infusion ? » — Continuer / Arrêter
    func notifyAsk(strings: Strings) {
        post(body: strings.notifAsk, category: askCategoryID)
    }

    /// « Te revoilà ! ☕ L'infusion s'est terminée toute seule — X de brew » — OK
    func notifyDone(duration: String, strings: Strings) {
        post(body: strings.notifDone(duration), category: doneCategoryID)
    }

    private func post(body: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = "Clauffee"
        content.body = body
        content.categoryIdentifier = category
        content.sound = .default
        // Plus visible et perce les modes Concentration. Pour qu'elle RESTE
        // affichée jusqu'à réponse, l'utilisateur doit choisir le style
        // « Alertes » dans Réglages Système › Notifications › Clauffee (macOS
        // ne permet pas à l'app de forcer ce choix). Le niveau time-sensitive
        // nécessite l'entitlement com.apple.developer.usernotifications.time-sensitive ;
        // sans lui, le système retombe silencieusement sur .active.
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == stopActionID {
            DispatchQueue.main.async { [weak self] in
                self?.onStopRequested?()
            }
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                    @escaping (UNNotificationPresentationOptions) -> Void) {
        // `.list` garde la notif dans le Centre de notifications jusqu'à
        // réponse (au lieu de disparaître). Ce handler ne s'applique que si
        // l'app est au premier plan ; en tâche de fond (cas normal d'une app
        // de barre de menus), c'est le style « Bannières/Alertes » choisi par
        // l'utilisateur dans les Réglages Système qui décide de la persistance.
        completionHandler([.banner, .list, .sound])
    }
}
