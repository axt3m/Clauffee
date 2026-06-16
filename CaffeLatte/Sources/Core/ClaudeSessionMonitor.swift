//
//  ClaudeSessionMonitor.swift
//  CaffeLatte
//
//  Compte les sessions Claude Code actives via pgrep, toutes les ~5 s
//  pendant l'infusion. Sert à la ligne "N sessions actives" et à
//  l'arrêt auto quand la dernière session se termine.
//

import Foundation

final class ClaudeSessionMonitor {

    /// Appelé sur le main thread avec le nombre de process détectés.
    var onCount: ((Int) -> Void)?

    private var timer: Timer?

    func start(interval: TimeInterval = 5) {
        stop()
        poll()
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let count = Self.claudeProcessCount()
            DispatchQueue.main.async {
                self?.onCount?(count)
            }
        }
    }

    /// pgrep -f "(^|/)claude( |$)" :
    /// matche `claude`, `/usr/local/bin/claude --rc`, `claude remote-control`…
    /// sans matcher CaffeLatte ni les binaires contenant "claude" au milieu.
    static func claudeProcessCount() -> Int {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", "(^|/)claude( |$)"]
        let out = Pipe()
        process.standardOutput = out
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return 0
        }
        process.waitUntilExit()

        // pgrep sort avec 1 quand aucun process ne matche.
        guard process.terminationStatus == 0 else { return 0 }

        let data = out.fileHandleForReading.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return 0 }
        return text.split(separator: "\n").count
    }
}
