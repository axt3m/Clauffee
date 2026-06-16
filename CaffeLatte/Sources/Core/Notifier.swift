//
//  Notifier.swift
//  CaffeLatte
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
        content.title = "CaffeLatte"
        content.body = body
        content.categoryIdentifier = category
        content.sound = .default

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
        completionHandler([.banner, .sound])
    }
}
