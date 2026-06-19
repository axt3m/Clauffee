//
//  ClauffeeApp.swift
//  Clauffee
//
//  Point d'entrée : MenuBarExtra (style .window). Crée et injecte les objets
//  partagés (SettingsStore, AppRouter, BrewViewModel). AppDelegate : mode
//  accessory (pas d'icône Dock) + filet de sécurité à la terminaison.
//

import AppKit
import SwiftUI

@main
struct ClauffeeApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var settings: SettingsStore
    @StateObject private var router: AppRouter
    @StateObject private var brew: BrewViewModel

    init() {
        let settings = SettingsStore()
        let router = AppRouter()
        _settings = StateObject(wrappedValue: settings)
        _router = StateObject(wrappedValue: router)
        _brew = StateObject(wrappedValue: BrewViewModel(settings: settings, router: router))
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environmentObject(settings)
                .environmentObject(router)
                .environmentObject(brew)
        } label: {
            MenuBarLabel(isBrewing: brew.isBrewing, elapsed: brew.elapsed)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Tasse (vide/pleine) + temps de brew dans la barre de menus.
struct MenuBarLabel: View {
    let isBrewing: Bool
    let elapsed: TimeInterval

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: isBrewing ? "cup.and.saucer.fill" : "cup.and.saucer")
            if isBrewing {
                Text(formatClock(elapsed))
                    .font(.system(size: 11.5, weight: .semibold))
                    .monospacedDigit()
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Pas d'icône Dock — équivalent LSUIElement, sans toucher l'Info.plist.
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // La veille normale est TOUJOURS rétablie, quoi qu'il arrive.
        BrewViewModel.emergencyCleanup()
        UserDefaults.standard.synchronize()
    }
}
