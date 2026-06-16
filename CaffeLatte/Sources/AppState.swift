//
//  AppState.swift
//  CaffeLatte
//
//  Machine à états centrale. Une seule source de vérité pour :
//  réglages persistés, cycle de vie de l'infusion, monitors (Claude, capot),
//  toasts et notifications.
//

import AppKit
import Carbon
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppState: ObservableObject {

    static let shared = AppState()

    enum EndReason {
        case manual      // toggle, footer, notification « Arrêter »
        case autoOff     // limite d'infusion atteinte
        case claudeDone  // dernière session Claude Code terminée
        case quit        // fermeture de l'app
    }

    // MARK: - Réglages (persistés en continu, flush au Quitter)

    @Published var theme: Theme { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    @Published var languagePref: LanguagePref {
        didSet {
            defaults.set(languagePref.rawValue, forKey: Keys.language)
            Notifier.shared.configure(strings: strings) // titres d'actions localisés
        }
    }

    /// Langue effective (résout « Auto » sur le clavier courant).
    var language: Language { languagePref.resolved }
    @Published var limitHours: Int { didSet { defaults.set(limitHours, forKey: Keys.limitHours) } }
    @Published var allUnlimited: Bool {
        didSet {
            defaults.set(allUnlimited, forKey: Keys.allUnlimited)
            if allUnlimited { sessionUnlimited = false }
        }
    }
    @Published var funToasts: Bool { didSet { defaults.set(funToasts, forKey: Keys.funToasts) } }
    @Published var lidNotification: Bool { didSet { defaults.set(lidNotification, forKey: Keys.lidNotification) } }
    @Published var lockOnLidClose: Bool { didSet { defaults.set(lockOnLidClose, forKey: Keys.lockOnLidClose) } }
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            Self.setLoginItem(launchAtLogin)
        }
    }
    @Published var firstRunSeen: Bool { didSet { defaults.set(firstRunSeen, forKey: Keys.firstRunSeen) } }

    // MARK: - État de session

    @Published var isBrewing = false
    @Published var sessionUnlimited = false      // override « pour cette session », reset à l'arrêt
    @Published var elapsed: TimeInterval = 0
    @Published var claudeSessionCount = 0
    @Published var sudoersError = false
    @Published var showOnboarding = false
    @Published var settingsOpen = false
    @Published var drainTrigger = 0              // incrémenté à chaque vidage → anime la tasse

    private(set) var lastBrewDuration: TimeInterval = 0

    // MARK: - Privé

    private var brewStart: Date?
    private var tickTimer: Timer?
    private var pendingSummaryDuration: TimeInterval?
    private var lastToastIndex = -1

    private let claudeMonitor = ClaudeSessionMonitor()
    private let lidMonitor = LidMonitor()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let theme = "theme"
        static let language = "language"
        static let limitHours = "limitHours"
        static let allUnlimited = "allUnlimited"
        static let funToasts = "funToasts"
        static let lidNotification = "lidNotification"
        static let lockOnLidClose = "lockOnLidClose"
        static let launchAtLogin = "launchAtLogin"
        static let firstRunSeen = "firstRunSeen"
    }

    // MARK: - Dérivés

    var strings: Strings { Strings.for(language) }
    var palette: Palette { Palette.for(theme) }
    var effectiveUnlimited: Bool { allUnlimited || sessionUnlimited }
    var remaining: TimeInterval { max(0, Double(limitHours) * 3600 - elapsed) }

    /// Suffixe gris « · 2 h / Illimité » (affiché uniquement à l'arrêt).
    var limitSuffix: String { effectiveUnlimited ? strings.unlimitedWord : "\(limitHours) h" }

    // MARK: - Init

    private init() {
        // Variable locale : lire `self.defaults` ici accéderait à `self`
        // avant que toutes les propriétés stockées soient initialisées.
        let store = UserDefaults.standard
        theme = Theme(rawValue: store.string(forKey: Keys.theme) ?? "") ?? .milk
        languagePref = LanguagePref(rawValue: store.string(forKey: Keys.language) ?? "") ?? .auto
        let storedLimit = store.integer(forKey: Keys.limitHours)
        limitHours = (1...9).contains(storedLimit) ? storedLimit : 2
        allUnlimited = store.bool(forKey: Keys.allUnlimited)
        funToasts = store.object(forKey: Keys.funToasts) as? Bool ?? true
        lidNotification = store.object(forKey: Keys.lidNotification) as? Bool ?? true
        lockOnLidClose = store.object(forKey: Keys.lockOnLidClose) as? Bool ?? true
        launchAtLogin = store.bool(forKey: Keys.launchAtLogin)
        firstRunSeen = store.bool(forKey: Keys.firstRunSeen)

        wireCallbacks()
        observeKeyboardLanguage()
        Notifier.shared.configure(strings: strings)

        // Sécurité : si un disablesleep traîne d'un crash précédent, on nettoie.
        if PowerManager.isSleepDisabled() {
            Task.detached { try? PowerManager.setSleepDisabled(false) }
        }
    }

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

    private func wireCallbacks() {
        // Compteur de sessions Claude affiché pendant l'infusion (info seulement,
        // plus d'arrêt auto : peu fiable, retiré à la demande).
        claudeMonitor.onCount = { [weak self] count in
            self?.claudeSessionCount = count
        }

        lidMonitor.onLidOpened = { [weak self] in
            self?.handleLidOpened()
        }

        lidMonitor.onLidClosed = { [weak self] in
            self?.handleLidClosed()
        }

        Notifier.shared.onStopRequested = { [weak self] in
            self?.endBrew(.manual)
        }
    }

    // MARK: - Cycle de vie de l'infusion

    func toggleBrew() {
        isBrewing ? endBrew(.manual) : requestStart()
    }

    /// Toggle ON. Ordre des préalables : règle sudoers → onboarding → infusion.
    /// Si un préalable manque, on affiche l'onglet correspondant et on s'arrête
    /// là : l'infusion ne démarre QUE quand tout est OK au moment du toggle.
    func requestStart() {
        Task { @MainActor in
            guard await sudoersReady() else { return }   // affiche l'onglet d'erreur si absent
            guard firstRunSeen else {
                showOnboarding = true                    // onboarding, pas d'infusion
                return
            }
            startBrew()
        }
    }

    /// « Réessayer » après l'ajout de la règle sudoers. Re-sonde puis route vers
    /// l'onboarding (1ᵉ lancement) ou la vue normale — SANS lancer l'infusion :
    /// l'utilisateur démarre lui-même via le toggle.
    func retryAfterSudoersFix() {
        Task { @MainActor in
            guard await sudoersReady() else { return }   // règle toujours absente → reste sur l'erreur
            if !firstRunSeen { showOnboarding = true }
        }
    }

    /// Vérifie la règle sudoers (sonde non destructive, hors main thread) et
    /// met à jour `sudoersError`. Renvoie true si la règle est en place.
    private func sudoersReady() async -> Bool {
        let ok = await Task.detached { PowerManager.sudoersRuleInstalled() }.value
        sudoersError = !ok
        return ok
    }

    /// Fin de l'onboarding : on mémorise qu'il a été vu, on ferme la feuille.
    /// Aucun démarrage auto — l'infusion ne part qu'au toggle ON.
    func completeOnboarding(start: Bool) {
        showOnboarding = false
        firstRunSeen = firstRunSeen || start
    }

    func startBrew() {
        guard !isBrewing else { return }
        Task { @MainActor in
            let ok = await Self.setPower(true)
            guard ok else {
                sudoersError = true
                return
            }
            sudoersError = false
            isBrewing = true
            brewStart = Date()
            elapsed = 0
            pendingSummaryDuration = nil

            startTick()
            claudeMonitor.start()
            lidMonitor.start()
            Notifier.shared.requestPermissionIfNeeded()

            if effectiveUnlimited || limitHours >= 5 {
                showHeatToast()
            } else if funToasts {
                showFunToast()
            }
        }
    }

    func endBrew(_ reason: EndReason) {
        guard isBrewing else { return }

        lastBrewDuration = elapsed
        isBrewing = false
        sessionUnlimited = false       // l'override session ne survit pas au brew
        drainTrigger += 1              // anime le vidage de la tasse
        stopTick()
        claudeMonitor.stop()

        let lidClosed = lidMonitor.isClosed == true

        switch reason {
        case .autoOff:
            if funToasts {
                let toast = strings.autoOffToast(limitHours)
                ToastPresenter.shared.show(emoji: toast.emoji, text: toast.text, palette: palette)
            }
            if lidClosed { pendingSummaryDuration = lastBrewDuration }
        case .claudeDone:
            let toast = strings.claudeOffToast
            ToastPresenter.shared.show(emoji: toast.emoji, text: toast.text, palette: palette)
            if lidClosed { pendingSummaryDuration = lastBrewDuration }
        case .manual, .quit:
            break
        }

        // Le monitor de capot reste actif si un résumé est en attente
        // (réouverture après auto-off / fin des sessions Claude).
        if pendingSummaryDuration == nil {
            lidMonitor.stop()
        }

        brewStart = nil
        elapsed = 0

        Task.detached { try? PowerManager.setSleepDisabled(false) }
    }

    // MARK: - Capot

    /// Capot fermé pendant l'infusion : on verrouille l'écran (la machine
    /// reste éveillée grâce à disablesleep) pour ne pas la laisser ouverte.
    private func handleLidClosed() {
        guard isBrewing, lockOnLidClose else { return }
        Task.detached { ScreenLocker.lock() }
    }

    private func handleLidOpened() {
        if isBrewing {
            if lidNotification {
                Notifier.shared.notifyAsk(strings: strings)
            }
        } else if let duration = pendingSummaryDuration {
            Notifier.shared.notifyDone(duration: formatClock(duration), strings: strings)
            pendingSummaryDuration = nil
            lidMonitor.stop()
        }
    }

    // MARK: - Tick (1 s)

    private func startTick() {
        stopTick()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            // Ajouté à RunLoop.main → se déclenche sur le thread principal :
            // on peut supposer l'isolation MainActor sans hop asynchrone.
            MainActor.assumeIsolated { self?.onTick() }
        }
        RunLoop.main.add(t, forMode: .common)
        tickTimer = t
    }

    private func stopTick() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func onTick() {
        guard let start = brewStart else { return }
        elapsed = Date().timeIntervalSince(start)
        if !effectiveUnlimited && remaining <= 0 {
            endBrew(.autoOff)
        }
    }

    // MARK: - Toasts
    // `funToasts` (réglage « Bulles fun ») coupe TOUTES les bulles quand il est
    // désactivé — un seul interrupteur pour tout le toasting.

    func showFunToast() {
        guard funToasts else { return }
        let toasts = strings.toasts
        guard !toasts.isEmpty else { return }
        var index: Int
        repeat {
            index = Int.random(in: 0..<toasts.count)
        } while index == lastToastIndex && toasts.count > 1
        lastToastIndex = index
        let toast = toasts[index]
        ToastPresenter.shared.show(emoji: toast.emoji, text: toast.text, palette: palette)
    }

    func showHeatToast() {
        guard funToasts else { return }
        let toast = strings.heatToast
        ToastPresenter.shared.show(emoji: toast.emoji, text: toast.text, palette: palette)
    }

    /// Bascule de l'override « pour cette session » (footer).
    func toggleSessionUnlimited() {
        guard !allUnlimited else { return }
        sessionUnlimited.toggle()
        if sessionUnlimited { showHeatToast() }
    }

    /// Bascule du réglage global « pour toutes les sessions ».
    func setAllUnlimited(_ value: Bool) {
        allUnlimited = value
        if value { showHeatToast() }
    }

    // MARK: - Quitter

    /// Quitter = arrêt du brew (disablesleep 0) + sauvegarde des préférences.
    func quit() {
        if isBrewing {
            lastBrewDuration = elapsed
            isBrewing = false
            stopTick()
            claudeMonitor.stop()
            lidMonitor.stop()
            try? PowerManager.setSleepDisabled(false) // synchrone : on part proprement
        }
        ToastPresenter.shared.dismiss()
        defaults.synchronize()
        NSApp.terminate(nil)
    }

    /// Filet de sécurité appelé par l'AppDelegate (Cmd+Q, logout…).
    nonisolated static func emergencyCleanup() {
        if PowerManager.isSleepDisabled() {
            try? PowerManager.setSleepDisabled(false)
        }
    }

    // MARK: - Helpers

    private static func setPower(_ on: Bool) async -> Bool {
        await Task.detached(priority: .userInitiated) {
            do {
                try PowerManager.setSleepDisabled(on)
                return true
            } catch {
                return false
            }
        }.value
    }

    private static func setLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("CaffeLatte: login item error — \(error.localizedDescription)")
        }
    }
}
