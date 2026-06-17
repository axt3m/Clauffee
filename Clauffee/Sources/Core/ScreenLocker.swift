//
//  ScreenLocker.swift
//  Clauffee
//
//  Verrouille l'écran SANS endormir la machine. Quand `disablesleep` est
//  actif, fermer le capot garde le Mac éveillé mais déverrouillé : on
//  verrouille nous-mêmes pour combler le trou de sécurité.
//
//  Mécanisme principal : `SACLockScreenImmediate` de login.framework
//  (API privée, mais stable et sans permission supplémentaire — l'app
//  n'est pas sandboxée). Repli : `pmset displaysleepnow` (le verrou dépend
//  alors du réglage « demander le mot de passe »).
//

import Foundation

nonisolated enum ScreenLocker {

    private typealias LockFn = @convention(c) () -> Int32

    /// Verrouille l'écran immédiatement, machine maintenue éveillée.
    static func lock() {
        if lockViaLoginFramework() { return }
        displaySleepFallback()
    }

    /// dlopen login.framework → SACLockScreenImmediate. True si appelée.
    private static func lockViaLoginFramework() -> Bool {
        let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
        guard let handle = dlopen(path, RTLD_LAZY) else { return false }
        defer { dlclose(handle) }
        guard let sym = dlsym(handle, "SACLockScreenImmediate") else { return false }
        let fn = unsafeBitCast(sym, to: LockFn.self)
        return fn() == 0
    }

    /// Repli : endort l'affichage. La machine reste éveillée (disablesleep).
    private static func displaySleepFallback() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
    }
}
