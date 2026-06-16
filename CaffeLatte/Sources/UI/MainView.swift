//
//  MainView.swift
//  CaffeLatte
//
//  Vue principale du popover : header (tasse animée, statut, ⚙︎),
//  carte (toggle brew, minuteur, sessions Claude, erreur sudoers),
//  footer adaptatif (override session / texte illimité) + Quitter.
//

import AppKit
import SwiftUI

struct MainView: View {

    @EnvironmentObject private var state: AppState
    @State private var copyConfirmed = false

    private var p: Palette { state.palette }
    private var s: Strings { state.strings }

    var body: some View {
        VStack(spacing: 0) {
            header
            card
            footer
        }
        .animation(.smooth(duration: 0.5), value: state.isBrewing)
        .animation(.easeOut(duration: 0.25), value: state.sudoersError)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: state.isBrewing ? p.badgeOn : p.badgeOff,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(p.cardBorder, lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.4), value: state.isBrewing)
                CupView(isBrewing: state.isBrewing,
                        drainTrigger: state.drainTrigger,
                        palette: p)
                    .frame(width: 40, height: 40)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 1) {
                Text("CaffeLatte")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(p.text1)
                Text(state.isBrewing ? s.statusOn : s.statusOff)
                    .font(.system(size: 12, weight: state.isBrewing ? .semibold : .regular))
                    .foregroundStyle(state.isBrewing
                                     ? (state.theme == .milk ? p.caramelDeep : p.crema)
                                     : p.text2)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 14)
        .overlay(alignment: .topTrailing) {
            Button {
                state.settingsOpen = true
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
            if state.sudoersError {
                errorCard
            } else {
                brewRow
                if state.isBrewing {
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
                // Suffixe « · 2 h / Illimité » uniquement à l'arrêt —
                // pendant l'infusion, l'info vit dans la ligne minuteur.
                if state.isBrewing {
                    Text(s.brewingTitle)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(p.text1)
                } else {
                    (Text(s.brewTitle).foregroundColor(p.text1)
                     + Text(" · \(state.limitSuffix)")
                        .foregroundColor(p.text2)
                        .fontWeight(.regular))
                        .font(.system(size: 13.5, weight: .semibold))
                }
                Text(state.isBrewing ? s.brewSubOn : s.brewSubOff)
                    .font(.system(size: 11.5))
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(
                get: { state.isBrewing },
                set: { _ in state.toggleBrew() }
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
                Text(s.awake(formatClock(state.elapsed)))
                    .font(.system(size: 13.5, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(p.text1)
                Text(state.effectiveUnlimited
                     ? s.noLimit
                     : s.autoOff(formatClock(state.remaining)))
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
            PulsingDot(active: state.claudeSessionCount > 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(s.sessions(state.claudeSessionCount))
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(p.text1)
                Text(state.claudeSessionCount > 0 ? s.sessionsSubActive : s.sessionsSubIdle)
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
                // En-tête du bloc : libellé + Copy, séparés de la commande
                // pour ne jamais recouvrir le texte.
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
                state.retryAfterSudoersFix()
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
            if state.allUnlimited {
                // Illimité global : pas de toggle, juste le texte.
                Text(s.unlimitedFooter)
                    .font(.system(size: 11.5))
                    .foregroundStyle(p.text2)
            } else {
                Toggle("", isOn: Binding(
                    get: { state.sessionUnlimited },
                    set: { _ in state.toggleSessionUnlimited() }
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
                state.quit()
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
