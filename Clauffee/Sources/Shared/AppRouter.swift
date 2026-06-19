//
//  AppRouter.swift
//  Clauffee
//
//  État de navigation du popover : feuille d'onboarding et écran de réglages.
//  Injecté en @EnvironmentObject ; piloté par les ViewModels (ex. le brew
//  ouvre l'onboarding) et par les vues (bouton réglages / retour).
//

import Combine
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    @Published var showOnboarding = false
    @Published var settingsOpen = false
}
