//
//  OnboardingViewModel.swift
//  Clauffee
//
//  État de la feuille d'onboarding : case « Remote Control = true » cochée,
//  et fin de l'onboarding (mémorise firstRunSeen, ferme la feuille).
//

import Combine
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {

    /// Étape de l'overlay : choix du compte, puis écran de bienvenue.
    enum Phase { case choice, welcome }

    /// Type de compte choisi (radio). Détermine ce qui s'affiche et la
    /// condition de validation.
    enum AccountKind { case none, apiKey, pro }

    @Published var phase: Phase = .choice
    @Published var account: AccountKind = .none
    /// Case « J'ai activé Remote Control… » — pertinente uniquement en .pro.
    @Published var remoteConfirmed = false

    /// Validation : clé API → tout de suite ; Pro → case Remote Control cochée.
    var canStart: Bool {
        switch account {
        case .none: return false
        case .apiKey: return true
        case .pro: return remoteConfirmed
        }
    }

    /// Permission + style d'alerte notifications. Étape OPTIONNELLE (ne bloque
    /// jamais la fin de l'onboarding, contrairement aux chemins ci-dessus).
    @Published var notifState: Notifier.Permission = .notDetermined
    @Published var notifAlertStyle: Notifier.AlertStyle = .unknown

    /// Le rappel d'arrêt sera-t-il efficace ? Seul le style « Persistant »
    /// (.alert) garde la notif à l'écran. Pilote le wording de l'écran welcome.
    var reminderEnabled: Bool { notifState == .authorized && notifAlertStyle == .alert }

    private let settings: SettingsStore
    private let router: AppRouter

    init(settings: SettingsStore, router: AppRouter) {
        self.settings = settings
        self.router = router
    }

    /// Sélection d'un radio. Quitter le chemin Pro réinitialise la case
    /// Remote Control (pour ne pas valider par une coche fantôme).
    func selectAccount(_ kind: AccountKind) {
        account = kind
        if kind != .pro { remoteConfirmed = false }
    }

    /// Case « J'ai activé Remote Control… » (chemin Pro).
    func toggleRemote() { remoteConfirmed.toggle() }

    /// Reflète l'état courant (permission + style d'alerte) à l'affichage.
    func refreshNotifState() {
        Notifier.shared.status { [weak self] perm, style in
            self?.notifState = perm
            self?.notifAlertStyle = style
        }
    }

    /// Tap sur la rangée « rappel d'arrêt » : demande la permission (1ʳᵉ fois),
    /// sinon ouvre les Réglages Système (pour changer le style ou désactiver —
    /// l'app ne peut pas révoquer l'autorisation elle-même).
    func tapNotif() {
        switch notifState {
        case .notDetermined:
            Notifier.shared.requestPermission { [weak self] _ in self?.refreshNotifState() }
        case .authorized, .denied:
            Notifier.shared.openSystemSettings()
        }
    }

    /// Fin de l'écran de choix. `start` = bouton « C'est noté » (mémorise),
    /// sinon « Me le rappeler plus tard » (ne mémorise pas). Dans les deux cas
    /// on passe à l'écran de bienvenue — l'overlay ne se ferme pas encore.
    func complete(start: Bool) {
        if start { settings.firstRunSeen = true }
        phase = .welcome
    }

    /// Bouton de l'écran de bienvenue : ferme l'overlay, révèle la vue normale.
    func finishWelcome() {
        router.showOnboarding = false
    }

    /// Retour de l'écran de bienvenue vers le choix.
    func backToChoice() {
        phase = .choice
    }

    /// « Retour » depuis l'écran de choix : referme l'onboarding sans le marquer
    /// comme vu (il réapparaîtra au prochain Start Brew).
    func dismiss() {
        router.showOnboarding = false
    }
}
