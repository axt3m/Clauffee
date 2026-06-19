//
//  PopoverRootView.swift
//  Clauffee
//
//  Racine du contenu du popover (fenêtre MenuBarExtra) :
//  vue principale ⇄ réglages, fond thémé, overlay onboarding.
//  Construit les ViewModels d'écran à partir des objets partagés injectés.
//

import SwiftUI

private struct Constants {
    static let popoverWidth: CGFloat = 312
    static let tintOpacity: Double = 0.72
    static let contentPadding: CGFloat = 16
    static let contentTopPadding: CGFloat = 2
    static let settingsAnimation: Double = 0.22
    static let onboardingAnimation: Double = 0.3
}

struct PopoverRootView: View {

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var brew: BrewViewModel

    var body: some View {
        ZStack {
            Group {
                if router.settingsOpen {
                    SettingsView(vm: SettingsViewModel(brew: brew, router: router))
                        .transition(.opacity)
                } else {
                    BrewView()
                        .transition(.opacity)
                }
            }
            .padding(Constants.contentPadding)
            .padding(.top, Constants.contentTopPadding)

            if router.showOnboarding {
                OnboardingView(vm: OnboardingViewModel(settings: settings, router: router))
            }
        }
        .frame(width: Constants.popoverWidth)
        .background(
            // Vibrancy « menu » + voile teinté léger : on garde l'identité
            // crème/expresso tout en laissant transparaître le flou du bureau.
            VisualEffectView()
                .overlay(settings.palette.popBg.opacity(Constants.tintOpacity))
                .ignoresSafeArea()
        )
        .preferredColorScheme(settings.theme == .milk ? .light : .dark)
        .animation(.easeOut(duration: Constants.settingsAnimation), value: router.settingsOpen)
        .animation(.easeOut(duration: Constants.onboardingAnimation), value: router.showOnboarding)
    }
}
