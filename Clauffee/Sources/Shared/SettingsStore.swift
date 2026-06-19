//
//  SettingsStore.swift
//  Clauffee
//
//  Source de vérité des RÉGLAGES persistés (thème, langue, limite,
//  illimité, bulles, notif capot, login). Injecté en @EnvironmentObject.
//  Ne connaît rien du cycle de vie du brew (→ BrewViewModel).
//

import AppKit
import Carbon
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {

    // MARK: Réglages persistés (flush au Quitter)

    @Published var theme: Theme { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    @Published var languagePref: LanguagePref {
        didSet {
            defaults.set(languagePref.rawValue, forKey: Keys.language)
            Notifier.shared.configure(strings: strings) // titres d'actions localisés
        }
    }
    @Published var limitHours: Double { didSet { defaults.set(limitHours, forKey: Keys.limitHours) } }
    @Published var allUnlimited: Bool { didSet { defaults.set(allUnlimited, forKey: Keys.allUnlimited) } }
    @Published var funToasts: Bool { didSet { defaults.set(funToasts, forKey: Keys.funToasts) } }
    @Published var lidNotification: Bool { didSet { defaults.set(lidNotification, forKey: Keys.lidNotification) } }
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            Self.setLoginItem(launchAtLogin)
        }
    }
    @Published var firstRunSeen: Bool { didSet { defaults.set(firstRunSeen, forKey: Keys.firstRunSeen) } }

    /// Valeurs sélectionnables du minuteur : 30 min, puis heures entières.
    static let limitOptions: [Double] = [0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9]

    // MARK: Dérivés (purs réglages)

    /// Langue effective (résout « Auto » sur le clavier courant).
    var language: Language { languagePref.resolved }
    var strings: Strings { Strings.for(language) }
    var palette: Palette { Palette.for(theme) }

    /// Étiquette lisible de la limite : « 30 min » ou « N h ».
    var limitLabel: String { limitHours == 0.5 ? "30 min" : "\(Int(limitHours)) h" }

    // MARK: Privé

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let theme = "theme"
        static let language = "language"
        static let limitHours = "limitHours"
        static let allUnlimited = "allUnlimited"
        static let funToasts = "funToasts"
        static let lidNotification = "lidNotification"
        static let launchAtLogin = "launchAtLogin"
        static let firstRunSeen = "firstRunSeen"
    }

    // MARK: Init

    init() {
        // Variable locale : lire `self.defaults` ici accéderait à `self`
        // avant que toutes les propriétés stockées soient initialisées.
        let store = UserDefaults.standard
        theme = Theme(rawValue: store.string(forKey: Keys.theme) ?? "") ?? .milk
        languagePref = LanguagePref(rawValue: store.string(forKey: Keys.language) ?? "") ?? .auto
        let storedLimit = store.double(forKey: Keys.limitHours)
        limitHours = Self.limitOptions.contains(storedLimit) ? storedLimit : 1
        allUnlimited = store.bool(forKey: Keys.allUnlimited)
        funToasts = store.object(forKey: Keys.funToasts) as? Bool ?? true
        lidNotification = store.object(forKey: Keys.lidNotification) as? Bool ?? true
        launchAtLogin = store.bool(forKey: Keys.launchAtLogin)
        firstRunSeen = store.bool(forKey: Keys.firstRunSeen)

        observeKeyboardLanguage()
        Notifier.shared.configure(strings: strings)
    }

    /// Sauvegarde explicite (appelée au Quitter).
    func flush() { defaults.synchronize() }

    /// En mode « Auto », suit les changements de clavier en direct :
    /// rafraîchit l'UI et réenregistre les titres de notifications localisés.
    private func observeKeyboardLanguage() {
        let name = Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)
        DistributedNotificationCenter.default().addObserver(
            forName: name, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.languagePref == .auto else { return }
                self.objectWillChange.send()
                Notifier.shared.configure(strings: self.strings)
            }
        }
    }

    private static func setLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Clauffee: login item error — \(error.localizedDescription)")
        }
    }
}
