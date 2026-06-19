//
//  SettingsViewModel.swift
//  Clauffee
//
//  Actions de l'écran Réglages. Les simples bascules persistées sont liées
//  directement au SettingsStore par la vue ; ici on regroupe les actions qui
//  ont des effets de bord (illimité global → reset session + bulle chauffe,
//  via le BrewViewModel) et la navigation de retour.
//

import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {

    private let brew: BrewViewModel
    private let router: AppRouter

    init(brew: BrewViewModel, router: AppRouter) {
        self.brew = brew
        self.router = router
    }

    var limitOptions: [Double] { SettingsStore.limitOptions }

    /// Bascule « Infusion éternelle » (passe par le brew : reset de l'override
    /// session + bulle d'avertissement chauffe).
    func setAllUnlimited(_ value: Bool) { brew.setAllUnlimited(value) }

    /// Retour à la vue principale.
    func close() { router.settingsOpen = false }
}
