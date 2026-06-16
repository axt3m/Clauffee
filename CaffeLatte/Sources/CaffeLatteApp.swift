//
//  CaffeLatteApp.swift
//  CaffeLatte
//
//  Point d'entrée : MenuBarExtra (style .window), label tasse + timer,
//  AppDelegate pour le mode accessory (pas d'icône Dock) et le filet
//  de sécurité à la terminaison (disablesleep 0, flush des préférences).
//

import AppKit
import SwiftUI

@main
struct CaffeLatteApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environmentObject(state)
        } label: {
            MenuBarLabel(isBrewing: state.isBrewing, elapsed: state.elapsed)
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
        AppState.emergencyCleanup()
        UserDefaults.standard.synchronize()
    }
}
