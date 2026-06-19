//
//  BrewView.swift
//  Clauffee
//
//  Vue principale du popover : header (tasse animée, statut, ⚙︎),
//  carte (toggle brew, minuteur, sessions Claude, erreur sudoers),
//  footer adaptatif (override session / texte illimité) + Quitter.
//

import AppKit
import SwiftUI

struct BrewView: View {

    @EnvironmentObject private var brew: BrewViewModel
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var router: AppRouter
    @State private var copyConfirmed = false

    private var p: Palette { settings.palette }
    private var s: Strings { settings.strings }

    var body: some View {
        VStack(spacing: 0) {
            header
            card
            footer
        }
        .animation(.smooth(duration: 0.5), value: brew.isBrewing)
        .animation(.easeOut(duration: 0.25), value: brew.sudoersError)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: brew.isBrewing ? p.badgeOn : p.badgeOff,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(p.cardBorder, lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.4), value: brew.isBrewing)
                CupView(isBrewing: brew.isBrewing,
                        drainTrigger: brew.drainTrigger,
                        palette: p)
                    .frame(width: 40, height: 40)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 1) {
                Text("Clauffee")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(p.text1)
                Text(brew.isBrewing ? s.statusOn : s.statusOff)
                    .font(.system(size: 12, weight: brew.isBrewing ? .semibold : .regular))
                    .foregroundStyle(brew.isBrewing
                                     ? (settings.theme == .milk ? p.caramelDeep : p.crema)
                                     : p.text2)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 14)
        .overlay(alignment: .topTrailing) {
            Button {
                router.settingsOpen = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(p.text2)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(s.settingsTitle)
        }
    }

    // MARK: - Carte centrale

    private var card: some View {
        VStack(spacing: 0) {
            if brew.sudoersError {
                errorCard
            } else {
                brewRow
                if brew.isBrewing {
                    divider
                    timerRow
                    divider
                    sessionsRow
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(p.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(p.cardBorder, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var divider: some View {
        Rectangle().fill(p.divider).frame(height: 1)
    }

    private var brewRow: some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 1) {
                // Suffixe « · 1 h / Illimité » uniquement à l'arrêt —
                // pendant l'infusion, l'info vit dans la ligne minuteur.
                if brew.isBrewing {
                    Text(s.brewingTitle)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(p.text1)
                } else {
                    (Text(s.brewTitle).foregroundColor(p.text1)
                     + Text(" · \(brew.limitSuffix)")
                        .foregroundColor(p.text2)
                        .fontWeight(.regular))
                        .font(.system(size: 13.5, weight: .semibold))
                }
                Text(brew.isBrewing ? s.brewSubOn : s.brewSubOff)
                    .font(.system(size: 11.5))
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(
                get: { brew.isBrewing },
                set: { _ in brew.toggleBrew() }
            ))
            .labelsHidden()
            .toggleStyle(CaramelToggleStyle(palette: p))
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
    }

    private var timerRow: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(p.caramel.opacity(0.16))
                .frame(width: 24, height: 24)
                .overlay(Text("⏱").font(.system(size: 12)))
            VStack(alignment: .leading, spacing: 1) {
                Text(s.awake(formatClock(brew.elapsed)))
                    .font(.system(size: 13.5, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(p.text1)
                Text(brew.effectiveUnlimited
                     ? s.noLimit
                     : s.autoOff(formatClock(brew.remaining)))
                    .font(.system(size: 11.5))
                    .monospacedDigit()
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .transition(.opacity)
    }

    private var sessionsRow: some View {
        HStack(spacing: 11) {
            PulsingDot(active: brew.claudeSessionCount > 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(s.sessions(brew.claudeSessionCount))
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(p.text1)
                Text(brew.claudeSessionCount > 0 ? s.sessionsSubActive : s.sessionsSubIdle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 12)
        .transition(.opacity)
    }

    // MARK: - Erreur sudoers

    private var errorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Text("⚠️").font(.system(size: 13))
                Text(s.errTitle)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(p.text1)
            }
            Text(s.errBody)
                .font(.system(size: 11.5))
                .foregroundStyle(p.text2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Image(systemName: "terminal")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(p.kbdText.opacity(0.55))
                    Spacer(minLength: 0)
                    Button {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(PowerManager.sudoersInstall, forType: .string)
                        copyConfirmed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            copyConfirmed = false
                        }
                    } label: {
                        Text(copyConfirmed ? s.copied : s.copy)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(p.kbdText.opacity(0.16), in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(p.kbdText)
                    }
                    .buttonStyle(.plain)
                }

                Text(PowerManager.sudoersInstall)
                    .font(.system(size: 10.2, design: .monospaced))
                    .foregroundStyle(p.kbdText)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(p.kbdBg))

            Button {
                brew.retryAfterSudoersFix()
            } label: {
                Text(s.retry)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(p.caramelGradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding(13)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            if settings.allUnlimited {
                // Illimité global : pas de toggle, juste le texte.
                Text(s.unlimitedFooter)
                    .font(.system(size: 11.5))
                    .foregroundStyle(p.text2)
            } else {
                Toggle("", isOn: Binding(
                    get: { brew.sessionUnlimited },
                    set: { _ in brew.toggleSessionUnlimited() }
                ))
                .labelsHidden()
                .toggleStyle(CaramelToggleStyle(palette: p, small: true))
                Text(s.sessionUnlimitedLabel)
                    .font(.system(size: 11.5))
                    .foregroundStyle(p.text2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button {
                brew.quit()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "power")
                        .font(.system(size: 10.5, weight: .semibold))
                    Text(s.quit)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(p.text2)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }
}

// MARK: - Point pulsant (sessions Claude)

struct PulsingDot: View {
    let active: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(active ? Color(hex: 0x4FA868) : Color(hex: 0xB7A28D))
            .frame(width: 7, height: 7)
            .overlay {
                if active {
                    Circle()
                        .stroke(Color(hex: 0x4FA868).opacity(0.45), lineWidth: 2)
                        .scaleEffect(pulse ? 2.6 : 1)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1.8).repeatForever(autoreverses: false),
                                   value: pulse)
                }
            }
            .onAppear { pulse = true }
    }
}
