//
//  PopoverRootView.swift
//  CaffeLatte
//
//  Racine du contenu du popover (fenêtre MenuBarExtra) :
//  vue principale ⇄ réglages, fond thémé, overlay onboarding.
//

import SwiftUI

struct PopoverRootView: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        ZStack {
            Group {
                if state.settingsOpen {
                    SettingsView()
                        .transition(.opacity)
                } else {
                    MainView()
                        .transition(.opacity)
                }
            }
            .padding(16)
            .padding(.top, 2)

            if state.showOnboarding {
                OnboardingOverlay()
            }
        }
        .frame(width: 312)
        .background(
            // Vibrancy « menu » + voile teinté léger : on garde l'identité
            // crème/expresso tout en laissant transparaître le flou du bureau.
            VisualEffectView()
                .overlay(state.palette.popBg.opacity(0.72))
                .ignoresSafeArea()
        )
        .preferredColorScheme(state.theme == .milk ? .light : .dark)
        .animation(.easeOut(duration: 0.22), value: state.settingsOpen)
        .animation(.easeOut(duration: 0.3), value: state.showOnboarding)
    }
}
