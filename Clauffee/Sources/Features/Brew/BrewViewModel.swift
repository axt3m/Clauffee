//
//  BrewViewModel.swift
//  Clauffee
//
//  Cycle de vie de l'infusion : démarrage/arrêt, minuteur, monitors (Claude,
//  capot), contrôle de la veille (pmset), verrouillage écran, toasts et
//  notifications. État transient (≠ réglages persistés → SettingsStore).
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class BrewViewModel: ObservableObject {

    private struct Constants {
        static let secondsPerHour: TimeInterval = 3600
        static let heatThresholdHours: Double = 5      // ≥ : avertissement chauffe
        static let tickInterval: TimeInterval = 1
    }

    enum EndReason {
        case manual      // toggle, footer, notification « Arrêter »
        case autoOff     // limite d'infusion atteinte
        case claudeDone  // dernière session Claude Code terminée
        case quit        // fermeture de l'app
    }

    // MARK: État de session

    @Published var isBrewing = false
    @Published var sessionUnlimited = false      // override « pour cette session », reset à l'arrêt
    @Published var elapsed: TimeInterval = 0
    @Published var claudeSessionCount = 0
    @Published var sudoersError = false
    @Published var drainTrigger = 0              // incrémenté à chaque vidage → anime la tasse

    private(set) var lastBrewDuration: TimeInterval = 0

    // MARK: Dépendances

    private let settings: SettingsStore
    private let router: AppRouter

    // MARK: Privé

    private var brewStart: Date?
    private var tickTimer: Timer?
    private var pendingSummaryDuration: TimeInterval?
    private var lastToastIndex = -1

    private let claudeMonitor = ClaudeSessionMonitor()
    private let lidMonitor = LidMonitor()

    init(settings: SettingsStore, router: AppRouter) {
        self.settings = settings
        self.router = router
        wireCallbacks()

        // Sécurité : si un disablesleep traîne d'un crash précédent, on nettoie.
        if PowerManager.isSleepDisabled() {
            Task.detached { try? PowerManager.setSleepDisabled(false) }
        }
    }

    // MARK: Dérivés

    var effectiveUnlimited: Bool { settings.allUnlimited || sessionUnlimited }
    var remaining: TimeInterval { max(0, settings.limitHours * Constants.secondsPerHour - elapsed) }

    /// Suffixe gris « · 1 h / Illimité » (affiché uniquement à l'arrêt).
    var limitSuffix: String { effectiveUnlimited ? settings.strings.unlimitedWord : settings.limitLabel }

    private func wireCallbacks() {
        // Compteur de sessions Claude affiché pendant l'infusion (info seulement,
        // plus d'arrêt auto : peu fiable, retiré à la demande).
        claudeMonitor.onCount = { [weak self] count in
            self?.claudeSessionCount = count
        }
        lidMonitor.onLidOpened = { [weak self] in self?.handleLidOpened() }
        lidMonitor.onLidClosed = { [weak self] in self?.handleLidClosed() }
        Notifier.shared.onStopRequested = { [weak self] in self?.endBrew(.manual) }
    }

    // MARK: - Cycle de vie

    func toggleBrew() {
        isBrewing ? endBrew(.manual) : requestStart()
    }

    /// Toggle ON. Ordre des préalables : règle sudoers → onboarding → infusion.
    /// Si un préalable manque, on affiche l'onglet correspondant et on s'arrête
    /// là : l'infusion ne démarre QUE quand tout est OK au moment du toggle.
    func requestStart() {
        Task { @MainActor in
            guard await sudoersReady() else { return }   // affiche l'onglet d'erreur si absent
            guard settings.firstRunSeen else {
                router.showOnboarding = true             // onboarding, pas d'infusion
                return
            }
            startBrew()
        }
    }

    /// « Réessayer » après l'ajout de la règle sudoers. Re-sonde puis route vers
    /// l'onboarding (1ᵉ lancement) ou la vue normale — SANS lancer l'infusion.
    func retryAfterSudoersFix() {
        Task { @MainActor in
            guard await sudoersReady() else { return }
            if !settings.firstRunSeen { router.showOnboarding = true }
        }
    }

    /// Vérifie la règle sudoers (sonde non destructive, hors main thread) et
    /// met à jour `sudoersError`. Renvoie true si la règle est en place.
    private func sudoersReady() async -> Bool {
        let ok = await Task.detached { PowerManager.sudoersRuleInstalled() }.value
        sudoersError = !ok
        return ok
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

            if effectiveUnlimited || settings.limitHours >= Constants.heatThresholdHours {
                showHeatToast()
            } else if settings.funToasts {
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
            if settings.funToasts {
                let toast = settings.strings.autoOffToast(settings.limitLabel)
                ToastPresenter.shared.show(emoji: toast.emoji, text: toast.text, palette: settings.palette)
            }
            if lidClosed { pendingSummaryDuration = lastBrewDuration }
        case .claudeDone:
            let toast = settings.strings.claudeOffToast
            ToastPresenter.shared.show(emoji: toast.emoji, text: toast.text, palette: settings.palette)
            if lidClosed { pendingSummaryDuration = lastBrewDuration }
        case .manual, .quit:
            break
        }

        // Le monitor de capot reste actif si un résumé est en attente.
        if pendingSummaryDuration == nil { lidMonitor.stop() }

        brewStart = nil
        elapsed = 0

        Task.detached { try? PowerManager.setSleepDisabled(false) }
    }

    // MARK: - Capot

    /// Capot fermé pendant l'infusion : on verrouille TOUJOURS l'écran (la
    /// machine reste éveillée grâce à disablesleep). Systématique, non configurable.
    private func handleLidClosed() {
        guard isBrewing else { return }
        Task.detached { ScreenLocker.lock() }
    }

    private func handleLidOpened() {
        if isBrewing {
            if settings.lidNotification {
                Notifier.shared.notifyAsk(strings: settings.strings)
            }
        } else if let duration = pendingSummaryDuration {
            Notifier.shared.notifyDone(duration: formatClock(duration), strings: settings.strings)
            pendingSummaryDuration = nil
            lidMonitor.stop()
        }
    }

    // MARK: - Tick (1 s)

    private func startTick() {
        stopTick()
        let t = Timer(timeInterval: Constants.tickInterval, repeats: true) { [weak self] _ in
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
    // `settings.funToasts` coupe TOUTES les bulles quand désactivé.

    func showFunToast() {
        guard settings.funToasts else { return }
        let toasts = settings.strings.toasts
        guard !toasts.isEmpty else { return }
        var index: Int
        repeat {
            index = Int.random(in: 0..<toasts.count)
        } while index == lastToastIndex && toasts.count > 1
        lastToastIndex = index
        let toast = toasts[index]
        ToastPresenter.shared.show(emoji: toast.emoji, text: toast.text, palette: settings.palette)
    }

    func showHeatToast() {
        guard settings.funToasts else { return }
        let toast = settings.strings.heatToast
        ToastPresenter.shared.show(emoji: toast.emoji, text: toast.text, palette: settings.palette)
    }

    /// Bascule de l'override « pour cette session » (footer).
    func toggleSessionUnlimited() {
        guard !settings.allUnlimited else { return }
        sessionUnlimited.toggle()
        if sessionUnlimited { showHeatToast() }
    }

    /// Bascule du réglage global « pour toutes les sessions ».
    func setAllUnlimited(_ value: Bool) {
        settings.allUnlimited = value
        if value {
            sessionUnlimited = false
            showHeatToast()
        }
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
        settings.flush()
        NSApp.terminate(nil)
    }

    /// Filet de sécurité appelé par l'AppDelegate (Cmd+Q, logout…).
    nonisolated static func emergencyCleanup() {
        if PowerManager.isSleepDisabled() {
            try? PowerManager.setSleepDisabled(false)
        }
    }

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
}
