//
//  LidMonitor.swift
//  CaffeLatte
//
//  Sonde l'état du capot (IOKit AppleClamshellState) toutes les 2 s.
//  Détecte la transition fermé → ouvert pour déclencher la notification
//  « Te revoilà ». Tourne pendant l'infusion, et continue après si une
//  infusion s'est terminée capot fermé (pour le résumé à la réouverture).
//
//  Note : après un auto-off capot fermé, le Mac s'endort et l'app est
//  gelée ; au réveil (réouverture), le timer reprend et détecte la
//  transition en ~2 s.
//

import Foundation
import IOKit

final class LidMonitor {

    /// Appelé sur le main thread quand le capot passe de fermé à ouvert.
    var onLidOpened: (() -> Void)?

    /// Appelé sur le main thread quand le capot passe d'ouvert à fermé.
    /// (Le timer continue de tourner car `disablesleep` empêche la veille.)
    var onLidClosed: (() -> Void)?

    private var timer: Timer?
    private var lastClosed: Bool?

    /// État instantané (nil si indisponible, ex. Mac de bureau).
    var isClosed: Bool? { Self.clamshellClosed() }

    var isRunning: Bool { timer != nil }

    func start(interval: TimeInterval = 2) {
        guard timer == nil else { return }
        lastClosed = Self.clamshellClosed()
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.check()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastClosed = nil
    }

    private func check() {
        guard let closed = Self.clamshellClosed() else { return }
        if lastClosed == true && closed == false {
            onLidOpened?()
        } else if lastClosed == false && closed == true {
            onLidClosed?()
        }
        lastClosed = closed
    }

    static func clamshellClosed() -> Bool? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPMrootDomain")
        )
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }

        guard let prop = IORegistryEntryCreateCFProperty(
            service,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else { return nil }

        if let bool = prop as? Bool { return bool }
        if let number = prop as? NSNumber { return number.boolValue }
        return nil
    }
}
