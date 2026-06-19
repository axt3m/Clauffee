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

    @Published var remoteConfirmed = false

    private let settings: SettingsStore
    private let router: AppRouter

    init(settings: SettingsStore, router: AppRouter) {
        self.settings = settings
        self.router = router
    }

    /// Fin de l'onboarding. `start` = bouton « C'est noté » (mémorise),
    /// sinon « Me le rappeler plus tard » (ne mémorise pas). Aucun démarrage
    /// auto — l'infusion ne part qu'au toggle ON.
    func complete(start: Bool) {
        router.showOnboarding = false
        if start { settings.firstRunSeen = true }
    }
}
