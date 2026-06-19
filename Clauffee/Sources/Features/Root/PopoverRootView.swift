//
//  PopoverRootView.swift
//  Clauffee
//
//  Racine du contenu du popover (fenêtre MenuBarExtra) :
//  vue principale ⇄ réglages, fond thémé, overlay onboarding.
//  Construit les ViewModels d'écran à partir des objets partagés injectés.
//

import SwiftUI

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
            .padding(16)
            .padding(.top, 2)

            if router.showOnboarding {
                OnboardingView(vm: OnboardingViewModel(settings: settings, router: router))
            }
        }
        .frame(width: 312)
        .background(
            // Vibrancy « menu » + voile teinté léger : on garde l'identité
            // crème/expresso tout en laissant transparaître le flou du bureau.
            VisualEffectView()
                .overlay(settings.palette.popBg.opacity(0.72))
                .ignoresSafeArea()
        )
        .preferredColorScheme(settings.theme == .milk ? .light : .dark)
        .animation(.easeOut(duration: 0.22), value: router.settingsOpen)
        .animation(.easeOut(duration: 0.3), value: router.showOnboarding)
    }
}
