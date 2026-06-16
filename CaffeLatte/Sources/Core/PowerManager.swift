//
//  PowerManager.swift
//  CaffeLatte
//
//  Pilote `pmset -a disablesleep` via sudo -n (non-interactif).
//  Nécessite une règle sudoers — une seule fois, en une seule commande :
//
//      echo '%admin ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0' | sudo tee /etc/sudoers.d/caffelatte
//
//  ⚠️ App Sandbox doit être DÉSACTIVÉ (Process + pgrep + IOKit).
//

import Foundation

enum PowerError: Error {
    case sudoersMissing
}

// `nonisolated` : ces méthodes font des appels bloquants (Process / waitUntilExit)
// et doivent pouvoir tourner hors du main actor (Task.detached, emergencyCleanup).
nonisolated enum PowerManager {

    static let sudoersLine = "%admin ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0"

    /// Commande unique copier-coller : crée la règle sudoers d'un seul tee.
    /// Les quotes simples protègent `%` et `,` de l'interprétation par zsh.
    static let sudoersInstall = "echo '\(sudoersLine)' | sudo tee /etc/sudoers.d/caffelatte"

    /// Active/désactive disablesleep. Lève `PowerError.sudoersMissing`
    /// si sudo -n échoue (règle absente ou invalide).
    static func setSleepDisabled(_ disabled: Bool) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["-n", "/usr/bin/pmset", "-a", "disablesleep", disabled ? "1" : "0"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            throw PowerError.sudoersMissing
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PowerError.sudoersMissing
        }
    }

    /// True si la règle sudoers NOPASSWD est en place, SANS exécuter pmset
    /// ni changer l'état de veille. `sudo -n -l <cmd>` renvoie 0 quand la
    /// commande est autorisée sans mot de passe — sinon échoue (règle absente).
    static func sudoersRuleInstalled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["-n", "-l", "/usr/bin/pmset", "-a", "disablesleep", "1"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return false
        }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    /// Lit l'état actuel via `pmset -g` (ligne "SleepDisabled  1").
    static func isSleepDisabled() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return false
        }
        process.waitUntilExit()

        let data = out.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return false }

        for line in text.split(separator: "\n") where line.contains("SleepDisabled") {
            return line.trimmingCharacters(in: .whitespaces).hasSuffix("1")
        }
        return false
    }
}
