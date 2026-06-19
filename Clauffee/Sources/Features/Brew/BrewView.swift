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

private struct Constants {
    // Animations
    static let brewAnimation: Double = 0.5
    static let sudoersAnimation: Double = 0.25
    static let badgeAnimation: Double = 0.4

    // Header
    static let headerSpacing: CGFloat = 12
    static let badgeCorner: CGFloat = 14
    static let badgeSize: CGFloat = 50
    static let cupSize: CGFloat = 40
    static let titleFontSize: CGFloat = 16
    static let statusFontSize: CGFloat = 12
    static let statusLineLimit: Int = 2
    static let headerBottomPadding: CGFloat = 14
    static let gearFontSize: CGFloat = 14
    static let gearHitSize: CGFloat = 30

    // Carte
    static let cardCorner: CGFloat = 14
    static let borderWidth: CGFloat = 1
    static let dividerHeight: CGFloat = 1

    // Lignes (brew / timer / sessions)
    static let rowSpacing: CGFloat = 11
    static let rowSpacerMin: CGFloat = 8
    static let rowTitleFontSize: CGFloat = 13.5
    static let rowSubFontSize: CGFloat = 11.5
    static let rowHPadding: CGFloat = 13
    static let rowVPadding: CGFloat = 12
    static let timerIconCorner: CGFloat = 7
    static let timerIconSize: CGFloat = 24
    static let timerIconBgOpacity: Double = 0.16
    static let timerIconFontSize: CGFloat = 12

    // Erreur sudoers
    static let errTitleSpacing: CGFloat = 7
    static let errEmojiFontSize: CGFloat = 13
    static let errTitleFontSize: CGFloat = 13.5
    static let errBodyFontSize: CGFloat = 11.5
    static let errBodyTopPadding: CGFloat = 5
    static let errBodyBottomPadding: CGFloat = 10
    static let cmdBlockSpacing: CGFloat = 7
    static let cmdHeaderSpacing: CGFloat = 6
    static let terminalFontSize: CGFloat = 10
    static let terminalOpacity: Double = 0.55
    static let copyFontSize: CGFloat = 10
    static let copyHPadding: CGFloat = 8
    static let copyVPadding: CGFloat = 3
    static let copyBgOpacity: Double = 0.16
    static let copyCorner: CGFloat = 6
    static let copyResetDelay: TimeInterval = 1.6
    static let cmdFontSize: CGFloat = 10.2
    static let cmdBlockPadding: CGFloat = 11
    static let cmdBlockCorner: CGFloat = 9
    static let retryFontSize: CGFloat = 12.5
    static let retryVPadding: CGFloat = 8
    static let retryCorner: CGFloat = 9
    static let retryTopPadding: CGFloat = 10
    static let errorCardPadding: CGFloat = 13

    // Footer
    static let footerSpacing: CGFloat = 8
    static let footerFontSize: CGFloat = 11.5
    static let footerLineLimit: Int = 2
    static let quitSpacing: CGFloat = 5
    static let quitIconFontSize: CGFloat = 10.5
    static let quitFontSize: CGFloat = 12
    static let quitHPadding: CGFloat = 6
    static let quitVPadding: CGFloat = 3
    static let footerHPadding: CGFloat = 4
    static let footerTopPadding: CGFloat = 12
}

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
        .animation(.smooth(duration: Constants.brewAnimation), value: brew.isBrewing)
        .animation(.easeOut(duration: Constants.sudoersAnimation), value: brew.sudoersError)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: Constants.headerSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: Constants.badgeCorner, style: .continuous)
                    .fill(LinearGradient(colors: brew.isBrewing ? p.badgeOn : p.badgeOff,
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.badgeCorner, style: .continuous)
                            .strokeBorder(p.cardBorder, lineWidth: Constants.borderWidth)
                    )
                    .animation(.easeInOut(duration: Constants.badgeAnimation), value: brew.isBrewing)
                CupView(isBrewing: brew.isBrewing,
                        drainTrigger: brew.drainTrigger,
                        palette: p)
                    .frame(width: Constants.cupSize, height: Constants.cupSize)
            }
            .frame(width: Constants.badgeSize, height: Constants.badgeSize)

            VStack(alignment: .leading, spacing: 1) {
                Text("Clauffee")
                    .font(.system(size: Constants.titleFontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(p.text1)
                Text(brew.isBrewing ? s.statusOn : s.statusOff)
                    .font(.system(size: Constants.statusFontSize, weight: brew.isBrewing ? .semibold : .regular))
                    .foregroundStyle(brew.isBrewing
                                     ? (settings.theme == .milk ? p.caramelDeep : p.crema)
                                     : p.text2)
                    .lineLimit(Constants.statusLineLimit)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, Constants.headerBottomPadding)
        .overlay(alignment: .topTrailing) {
            Button {
                router.settingsOpen = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: Constants.gearFontSize))
                    .foregroundStyle(p.text2)
                    .frame(width: Constants.gearHitSize, height: Constants.gearHitSize)
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
            RoundedRectangle(cornerRadius: Constants.cardCorner, style: .continuous)
                .fill(p.card)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.cardCorner, style: .continuous)
                        .strokeBorder(p.cardBorder, lineWidth: Constants.borderWidth)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: Constants.cardCorner, style: .continuous))
    }

    private var divider: some View {
        Rectangle().fill(p.divider).frame(height: Constants.dividerHeight)
    }

    private var brewRow: some View {
        HStack(spacing: Constants.rowSpacing) {
            VStack(alignment: .leading, spacing: 1) {
                // Suffixe « · 1 h / Illimité » uniquement à l'arrêt —
                // pendant l'infusion, l'info vit dans la ligne minuteur.
                if brew.isBrewing {
                    Text(s.brewingTitle)
                        .font(.system(size: Constants.rowTitleFontSize, weight: .semibold))
                        .foregroundStyle(p.text1)
                } else {
                    (Text(s.brewTitle).foregroundColor(p.text1)
                     + Text(" · \(brew.limitSuffix)")
                        .foregroundColor(p.text2)
                        .fontWeight(.regular))
                        .font(.system(size: Constants.rowTitleFontSize, weight: .semibold))
                }
                Text(brew.isBrewing ? s.brewSubOn : s.brewSubOff)
                    .font(.system(size: Constants.rowSubFontSize))
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Constants.rowSpacerMin)
            Toggle("", isOn: Binding(
                get: { brew.isBrewing },
                set: { _ in brew.toggleBrew() }
            ))
            .labelsHidden()
            .toggleStyle(CaramelToggleStyle(palette: p))
        }
        .padding(.horizontal, Constants.rowHPadding)
        .padding(.vertical, Constants.rowVPadding)
    }

    private var timerRow: some View {
        HStack(spacing: Constants.rowSpacing) {
            RoundedRectangle(cornerRadius: Constants.timerIconCorner, style: .continuous)
                .fill(p.caramel.opacity(Constants.timerIconBgOpacity))
                .frame(width: Constants.timerIconSize, height: Constants.timerIconSize)
                .overlay(Text("⏱").font(.system(size: Constants.timerIconFontSize)))
            VStack(alignment: .leading, spacing: 1) {
                Text(s.awake(formatClock(brew.elapsed)))
                    .font(.system(size: Constants.rowTitleFontSize, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(p.text1)
                Text(brew.effectiveUnlimited
                     ? s.noLimit
                     : s.autoOff(formatClock(brew.remaining)))
                    .font(.system(size: Constants.rowSubFontSize))
                    .monospacedDigit()
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Constants.rowHPadding)
        .padding(.vertical, Constants.rowVPadding)
        .transition(.opacity)
    }

    private var sessionsRow: some View {
        HStack(spacing: Constants.rowSpacing) {
            PulsingDot(active: brew.claudeSessionCount > 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(s.sessions(brew.claudeSessionCount))
                    .font(.system(size: Constants.rowTitleFontSize, weight: .semibold))
                    .foregroundStyle(p.text1)
                Text(brew.claudeSessionCount > 0 ? s.sessionsSubActive : s.sessionsSubIdle)
                    .font(.system(size: Constants.rowSubFontSize))
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Constants.rowHPadding)
        .padding(.vertical, Constants.rowVPadding)
        .transition(.opacity)
    }

    // MARK: - Erreur sudoers

    private var errorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Constants.errTitleSpacing) {
                Text("⚠️").font(.system(size: Constants.errEmojiFontSize))
                Text(s.errTitle)
                    .font(.system(size: Constants.errTitleFontSize, weight: .bold))
                    .foregroundStyle(p.text1)
            }
            Text(s.errBody)
                .font(.system(size: Constants.errBodyFontSize))
                .foregroundStyle(p.text2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Constants.errBodyTopPadding)
                .padding(.bottom, Constants.errBodyBottomPadding)

            VStack(alignment: .leading, spacing: Constants.cmdBlockSpacing) {
                HStack(spacing: Constants.cmdHeaderSpacing) {
                    Image(systemName: "terminal")
                        .font(.system(size: Constants.terminalFontSize, weight: .semibold))
                        .foregroundStyle(p.kbdText.opacity(Constants.terminalOpacity))
                    Spacer(minLength: 0)
                    Button {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(PowerManager.sudoersInstall, forType: .string)
                        copyConfirmed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.copyResetDelay) {
                            copyConfirmed = false
                        }
                    } label: {
                        Text(copyConfirmed ? s.copied : s.copy)
                            .font(.system(size: Constants.copyFontSize, weight: .bold))
                            .padding(.horizontal, Constants.copyHPadding)
                            .padding(.vertical, Constants.copyVPadding)
                            .background(p.kbdText.opacity(Constants.copyBgOpacity), in: RoundedRectangle(cornerRadius: Constants.copyCorner))
                            .foregroundStyle(p.kbdText)
                    }
                    .buttonStyle(.plain)
                }

                Text(PowerManager.sudoersInstall)
                    .font(.system(size: Constants.cmdFontSize, design: .monospaced))
                    .foregroundStyle(p.kbdText)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.cmdBlockPadding)
            .background(RoundedRectangle(cornerRadius: Constants.cmdBlockCorner, style: .continuous).fill(p.kbdBg))

            Button {
                brew.retryAfterSudoersFix()
            } label: {
                Text(s.retry)
                    .font(.system(size: Constants.retryFontSize, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.retryVPadding)
                    .background(p.caramelGradient, in: RoundedRectangle(cornerRadius: Constants.retryCorner, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, Constants.retryTopPadding)
        }
        .padding(Constants.errorCardPadding)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Constants.footerSpacing) {
            if settings.allUnlimited {
                // Illimité global : pas de toggle, juste le texte.
                Text(s.unlimitedFooter)
                    .font(.system(size: Constants.footerFontSize))
                    .foregroundStyle(p.text2)
            } else {
                Toggle("", isOn: Binding(
                    get: { brew.sessionUnlimited },
                    set: { _ in brew.toggleSessionUnlimited() }
                ))
                .labelsHidden()
                .toggleStyle(CaramelToggleStyle(palette: p, small: true))
                Text(s.sessionUnlimitedLabel)
                    .font(.system(size: Constants.footerFontSize))
                    .foregroundStyle(p.text2)
                    .lineLimit(Constants.footerLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Constants.footerSpacing)

            Button {
                brew.quit()
            } label: {
                HStack(spacing: Constants.quitSpacing) {
                    Image(systemName: "power")
                        .font(.system(size: Constants.quitIconFontSize, weight: .semibold))
                    Text(s.quit)
                        .font(.system(size: Constants.quitFontSize, weight: .semibold))
                }
                .foregroundStyle(p.text2)
                .padding(.horizontal, Constants.quitHPadding)
                .padding(.vertical, Constants.quitVPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Constants.footerHPadding)
        .padding(.top, Constants.footerTopPadding)
    }
}

// MARK: - Point pulsant (sessions Claude)

struct PulsingDot: View {

    private struct Constants {
        static let size: CGFloat = 7
        static let strokeOpacity: Double = 0.45
        static let strokeWidth: CGFloat = 2
        static let pulseScale: CGFloat = 2.6
        static let pulseDuration: Double = 1.8
    }

    let active: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(active ? Color(hex: 0x4FA868) : Color(hex: 0xB7A28D))
            .frame(width: Constants.size, height: Constants.size)
            .overlay {
                if active {
                    Circle()
                        .stroke(Color(hex: 0x4FA868).opacity(Constants.strokeOpacity), lineWidth: Constants.strokeWidth)
                        .scaleEffect(pulse ? Constants.pulseScale : 1)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: Constants.pulseDuration).repeatForever(autoreverses: false),
                                   value: pulse)
                }
            }
            .onAppear { pulse = true }
    }
}
