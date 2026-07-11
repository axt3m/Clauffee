//
//  OnboardingView.swift
//  Clauffee
//
//  Deux écrans en overlay :
//   · choix  — type de compte (radio) ; le chemin Pro déploie les 3 étapes
//              Remote Control + sa case de confirmation ; case rappel d'arrêt.
//   · welcome — récap de valeur + encart limite + ligne selon le rappel.
//

import AppKit
import SwiftUI

private struct Constants {
    static let scrimOpacity: Double = 0.35

    // Titre / intro
    static let titleFontSize: CGFloat = 14
    static let welcomeTitleFontSize: CGFloat = 17
    static let introFontSize: CGFloat = 12
    static let introTopPadding: CGFloat = 12   // ~ même écart que sous le sous-titre
    static let introBottomPadding: CGFloat = 4 // resserré jusqu'au choix

    // Encart note
    static let noteSpacing: CGFloat = 8
    static let noteEmojiFontSize: CGFloat = 13
    static let noteFontSize: CGFloat = 11
    static let noteVPadding: CGFloat = 9
    static let noteHPadding: CGFloat = 11
    static let noteFillOpacity: Double = 0.13
    static let noteBorderOpacity: Double = 0.25
    static let noteBorderWidth: CGFloat = 1
    static let noteCorner: CGFloat = 10
    static let noteTopPadding: CGFloat = 11

    // Case de confirmation
    static let confirmSpacing: CGFloat = 8
    static let notifIconSpacing: CGFloat = 5   // icône ↔ « Style d'alerte »
    static let confirmIconFontSize: CGFloat = 15
    static let confirmFontSize: CGFloat = 11.5
    static let confirmTopPadding: CGFloat = 12

    // Bouton principal
    static let brewFontSize: CGFloat = 13.5
    static let brewVPadding: CGFloat = 10
    static let brewCorner: CGFloat = 11
    static let brewShadowOpacity: Double = 0.4
    static let brewShadowRadius: CGFloat = 7
    static let brewShadowY: CGFloat = 4
    static let brewTopPadding: CGFloat = 12
    static let brewDisabledOpacity: Double = 0.4
    static let brewAnimation: Double = 0.2

    // Expansion des étapes Remote Control sous le radio « Compte Pro »
    static let expandAnimation: Double = 0.25

    // Skip
    static let skipFontSize: CGFloat = 11.5
    static let skipPadding: CGFloat = 4
    static let skipTopPadding: CGFloat = 5

    // Feuille
    static let sheetTopInset: CGFloat = 22
    static let sheetLeadingInset: CGFloat = 20
    static let sheetBottomInset: CGFloat = 14
    static let sheetTrailingInset: CGFloat = 20
    static let sheetCorner: CGFloat = 20
    static let sheetBorderWidth: CGFloat = 1
    static let sheetTintOpacity: Double = 0.72
    static let sheetShadowOpacity: Double = 0.35
    static let sheetShadowRadius: CGFloat = 22
    static let sheetShadowY: CGFloat = 12
    static let sheetOuterPadding: CGFloat = 12

    // Divider + checks
    static let dividerHeight: CGFloat = 1
    static let checkSpacing: CGFloat = 9
    static let checkCircleSize: CGFloat = 18
    static let checkNumberFontSize: CGFloat = 10.5
    static let checkTitleFontSize: CGFloat = 12.5
    static let checkSubFontSize: CGFloat = 11.5
    static let checkVPadding: CGFloat = 8
    static let checkCircleTopPadding: CGFloat = 1
    static let checkTextSpacing: CGFloat = 2

    // Indentation des étapes Pro sous le radio
    static let proIndent: CGFloat = 16

    // Bulle info du rappel d'arrêt
    static let infoPopoverWidth: CGFloat = 220
    static let infoPopoverPadding: CGFloat = 12
}

struct OnboardingView: View {

    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var vm: OnboardingViewModel

    @State private var showReminderInfo = false
    @State private var showStyleWarning = false

    init(vm: OnboardingViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    private var p: Palette { settings.palette }
    private var s: Strings { settings.strings }

    var body: some View {
        ZStack {
            Color.black.opacity(Constants.scrimOpacity)
                .contentShape(Rectangle())
                .onTapGesture { } // bloque les clics vers le fond

            sheet

            // Confirmation INTERNE au popover (un .alert système ferme le
            // MenuBarExtra car il vole le focus). Voir tapNext().
            if showStyleWarning { styleWarningOverlay }
        }
        .transition(.opacity)
        .animation(.easeOut(duration: Constants.expandAnimation), value: showStyleWarning)
        .onAppear { vm.refreshNotifState() }
        // Rafraîchit le statut au retour des Réglages Système (style changé).
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            vm.refreshNotifState()
        }
    }

    /// « Suivant » : si le style d'alerte n'est pas « Persistant », on confirme
    /// avant de continuer (sinon le rappel d'arrêt ne restera pas à l'écran).
    private func tapNext() {
        if vm.notifAlertStyle == .alert {
            vm.complete(start: true)
        } else {
            showStyleWarning = true
        }
    }

    private var sheet: some View {
        Group {
            if vm.phase == .choice {
                choiceContent
            } else {
                welcomeContent
            }
        }
        .animation(.easeOut(duration: Constants.expandAnimation), value: vm.phase)
        .padding(EdgeInsets(top: Constants.sheetTopInset, leading: Constants.sheetLeadingInset,
                            bottom: Constants.sheetBottomInset, trailing: Constants.sheetTrailingInset))
        .background(sheetBackground)
        .padding(Constants.sheetOuterPadding)
    }

    // Feuille translucide « menu » : vibrancy + voile teinté, découpée au rayon
    // de la carte, bordure et ombre. Partagée feuille / overlay de confirmation.
    private var sheetBackground: some View {
        VisualEffectView(material: .popover)
            .overlay(p.popBg.opacity(Constants.sheetTintOpacity))
            .clipShape(RoundedRectangle(cornerRadius: Constants.sheetCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.sheetCorner, style: .continuous)
                    .strokeBorder(p.cardBorder, lineWidth: Constants.sheetBorderWidth)
            )
            .shadow(color: .black.opacity(Constants.sheetShadowOpacity),
                    radius: Constants.sheetShadowRadius, y: Constants.sheetShadowY)
    }

    // Confirmation « Suivant sans style Persistant » — overlay interne.
    private var styleWarningOverlay: some View {
        ZStack {
            Color.black.opacity(Constants.scrimOpacity)
                .contentShape(Rectangle())
                .onTapGesture { showStyleWarning = false }

            VStack(spacing: 0) {
                Text(s.obStyleWarnTitle)
                    .font(.system(size: Constants.confirmFontSize, weight: .semibold))
                    .foregroundStyle(p.text1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(s.obStyleWarnBody)
                    .font(.system(size: Constants.checkSubFontSize))
                    .foregroundStyle(p.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Constants.introTopPadding)

                primaryButton(s.obStyleWarnConfirm, enabled: true) {
                    showStyleWarning = false
                    vm.complete(start: true)
                }

                Button { showStyleWarning = false } label: {
                    Text(s.obBack)
                        .font(.system(size: Constants.skipFontSize, weight: .semibold))
                        .foregroundStyle(p.text2)
                        .padding(Constants.skipPadding)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, Constants.skipTopPadding)
            }
            .padding(EdgeInsets(top: Constants.sheetTopInset, leading: Constants.sheetLeadingInset,
                                bottom: Constants.sheetBottomInset, trailing: Constants.sheetTrailingInset))
            .background(sheetBackground)
            .padding(Constants.sheetOuterPadding)
        }
        .transition(.opacity)
    }

    // MARK: - Écran 1 : choix du compte

    private var choiceContent: some View {
        VStack(spacing: 0) {
            Text(s.obTitle)
                .font(.system(size: Constants.titleFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(p.text1)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(s.obIntro)
                .font(.system(size: Constants.introFontSize, weight: .semibold))
                .foregroundStyle(p.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Constants.introTopPadding)
                .padding(.bottom, Constants.introBottomPadding)

            // Choix du compte (radio) : Clé API d'abord, puis Compte Pro.
            // L'option Pro déploie SOUS elle les 3 étapes Remote Control.
            radioCard(.apiKey, title: s.obAccountApi, sub: s.obAccountApiSub)

            VStack(spacing: 0) {
                radioCard(.pro, title: s.obAccountPro, sub: s.obAccountProSub)
                if vm.account == .pro {
                    proSteps.transition(.opacity)
                }
            }
            .animation(.easeOut(duration: Constants.expandAnimation), value: vm.account)

            notifRow

            primaryButton(s.obNext, enabled: vm.canStart) { tapNext() }
                .animation(.easeOut(duration: Constants.brewAnimation), value: vm.canStart)

            Button {
                vm.dismiss()
            } label: {
                Label(s.obBack, systemImage: "chevron.left")
                    .font(.system(size: Constants.skipFontSize, weight: .semibold))
                    .foregroundStyle(p.text2)
                    .padding(Constants.skipPadding)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, Constants.skipTopPadding)
        }
    }

    // MARK: - Écran 2 : bienvenue

    private var welcomeContent: some View {
        VStack(spacing: 0) {
            Text(s.obWelcomeTitle)
                .font(.system(size: Constants.welcomeTitleFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(p.text1)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Corps + suite selon que le rappel d'arrêt est actif ou non.
            Text(s.obWelcomeBody + (vm.reminderEnabled ? s.obWelcomeReminderOn : s.obWelcomeReminderOff))
                .font(.system(size: Constants.introFontSize))
                .foregroundStyle(p.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Constants.introTopPadding)
                .padding(.bottom, Constants.introBottomPadding)

            noteBox

            primaryButton(s.obWelcomeBtn, enabled: true) { vm.finishWelcome() }

            Button {
                vm.backToChoice()
            } label: {
                Label(s.obBack, systemImage: "chevron.left")
                    .font(.system(size: Constants.skipFontSize, weight: .semibold))
                    .foregroundStyle(p.text2)
                    .padding(Constants.skipPadding)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, Constants.skipTopPadding)
        }
    }

    // Bouton principal (gradient caramel) — partagé choix / bienvenue.
    private func primaryButton(_ title: String, enabled: Bool,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Constants.brewFontSize, weight: .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.brewVPadding)
                .background(p.caramelGradient,
                            in: RoundedRectangle(cornerRadius: Constants.brewCorner, style: .continuous))
                .shadow(color: p.caramelDeep.opacity(enabled ? Constants.brewShadowOpacity : 0),
                        radius: Constants.brewShadowRadius, y: Constants.brewShadowY)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : Constants.brewDisabledOpacity)
        .padding(.top, Constants.brewTopPadding)
    }

    // Case à cocher style « chemin » : icône + titre + sous-titre optionnel.
    private func pathCheckbox(checked: Bool, title: String, sub: String?,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Constants.confirmSpacing) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .font(.system(size: Constants.confirmIconFontSize))
                    .foregroundStyle(checked ? p.caramel : p.text2)
                VStack(alignment: .leading, spacing: Constants.checkTextSpacing) {
                    Text(title)
                        .font(.system(size: Constants.confirmFontSize, weight: .medium))
                        .foregroundStyle(p.text1)
                        .fixedSize(horizontal: false, vertical: true)
                    if let sub {
                        Text(sub)
                            .font(.system(size: Constants.checkSubFontSize))
                            .foregroundStyle(p.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, Constants.confirmTopPadding)
    }

    // Carte radio (un seul choix). Sélectionnée → cercle plein + voile caramel.
    private func radioCard(_ kind: OnboardingViewModel.AccountKind,
                           title: String, sub: String) -> some View {
        let selected = vm.account == kind
        return Button {
            vm.selectAccount(kind)
        } label: {
            HStack(alignment: .top, spacing: Constants.confirmSpacing) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: Constants.confirmIconFontSize))
                    .foregroundStyle(selected ? p.caramel : p.text2)
                VStack(alignment: .leading, spacing: Constants.checkTextSpacing) {
                    Text(title)
                        .font(.system(size: Constants.confirmFontSize, weight: .semibold))
                        .foregroundStyle(p.text1)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(sub)
                        .font(.system(size: Constants.checkSubFontSize))
                        .foregroundStyle(p.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, Constants.noteVPadding)
            .padding(.horizontal, Constants.noteHPadding)
            .background(
                RoundedRectangle(cornerRadius: Constants.noteCorner, style: .continuous)
                    .fill(p.caramel.opacity(selected ? Constants.noteFillOpacity : 0))
                    .overlay(
                        RoundedRectangle(cornerRadius: Constants.noteCorner, style: .continuous)
                            .strokeBorder(selected ? p.caramel.opacity(Constants.noteBorderOpacity) : p.cardBorder,
                                          lineWidth: Constants.noteBorderWidth)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, Constants.confirmTopPadding)
    }

    // Les 3 étapes Remote Control + la case de confirmation (chemin Pro).
    private var proSteps: some View {
        VStack(spacing: 0) {
            check(1, s.ob1t, s.ob1s)
            divider
            check(2, s.ob2t, s.ob2s)
            divider
            check(3, s.ob3t, s.ob3s)
            pathCheckbox(checked: vm.remoteConfirmed, title: s.obConfirm, sub: nil) {
                vm.toggleRemote()
                // Cocher révèle la bulle d'info notifications, SAUF si le style
                // est déjà « Persistant » (rien à régler → pas d'interruption).
                if vm.remoteConfirmed && !vm.reminderEnabled { showReminderInfo = true }
            }
        }
        .padding(.leading, Constants.proIndent)   // rattaché visuellement au radio Pro
    }

    // Encart ⏱ : limite de blocage par défaut (réutilisé par l'écran welcome).
    private var noteBox: some View {
        HStack(alignment: .top, spacing: Constants.noteSpacing) {
            Text("⏱").font(.system(size: Constants.noteEmojiFontSize))
            Text(s.obNote(settings.limitLabel))
                .font(.system(size: Constants.noteFontSize))
                .foregroundStyle(p.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Constants.noteVPadding)
        .padding(.horizontal, Constants.noteHPadding)
        .background(
            RoundedRectangle(cornerRadius: Constants.noteCorner, style: .continuous)
                .fill(p.caramel.opacity(Constants.noteFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.noteCorner, style: .continuous)
                        .strokeBorder(p.caramel.opacity(Constants.noteBorderOpacity), lineWidth: Constants.noteBorderWidth)
                )
        )
        .padding(.top, Constants.noteTopPadding)
    }

    // Étape OPTIONNELLE : autorise les notifications pour le rappel d'arrêt.
    // Ne bloque pas la validation. Le détail est masqué derrière un bouton ⓘ
    // (bulle popover) pour garder la rangée compacte.
    private var notifRow: some View {
        HStack(spacing: Constants.confirmSpacing) {
            Button {
                vm.tapNotif()
            } label: {
                HStack(spacing: Constants.notifIconSpacing) {
                    Image(systemName: notifIcon)
                        .font(.system(size: Constants.confirmIconFontSize))
                        .foregroundStyle(notifIconColor)
                    notifLabel
                        .font(.system(size: Constants.confirmFontSize, weight: .medium))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button {
                showReminderInfo.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: Constants.confirmIconFontSize))
                    .foregroundStyle(p.text2)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showReminderInfo, arrowEdge: .bottom) {
                Text(s.obNotifSub)
                    .font(.system(size: Constants.checkSubFontSize))
                    .foregroundStyle(p.text1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: Constants.infoPopoverWidth)
                    .padding(Constants.infoPopoverPadding)
                    .background(
                        VisualEffectView(material: .popover)
                            .overlay(p.popBg.opacity(Constants.sheetTintOpacity))
                    )
                    .presentationBackground(.clear)
            }
        }
        .padding(.top, Constants.confirmTopPadding)
    }

    // Autorisé : réveil si « Persistant », sinon X (Temporaire/Silencieux).
    // Pas encore demandé : réveil contour. Refusé : X.
    private var notifIcon: String {
        switch vm.notifState {
        case .authorized: return vm.notifAlertStyle == .alert ? "alarm.fill" : "xmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "alarm"
        }
    }

    private var notifIconColor: Color {
        (vm.notifState == .authorized && vm.notifAlertStyle == .alert) ? p.caramel : p.text2
    }

    // Autorisé → « Style d'alerte : <mot caramel> » (incite au clic) ;
    // sinon phrase d'invite / blocage en texte normal.
    private var notifLabel: Text {
        switch vm.notifState {
        case .authorized:
            return Text(s.obNotifStyleLabel).foregroundStyle(p.text1)
                 + Text(notifStyleWord).foregroundStyle(p.caramel)
        case .denied:
            return Text(s.obNotifDenied).foregroundStyle(p.text1)
        case .notDetermined:
            return Text(s.obNotif).foregroundStyle(p.text1)
        }
    }

    private var notifStyleWord: String {
        switch vm.notifAlertStyle {
        case .alert: return s.obNotifStylePersistent
        case .banner: return s.obNotifStyleTemporary
        case .silent: return s.obNotifStyleSilent
        case .unknown: return s.obNotifStyleTemporary
        }
    }

    private var divider: some View {
        Rectangle().fill(p.divider).frame(height: Constants.dividerHeight)
    }

    private func check(_ number: Int, _ title: String, _ sub: String) -> some View {
        HStack(alignment: .top, spacing: Constants.checkSpacing) {
            Circle()
                .fill(p.caramelGradient)
                .frame(width: Constants.checkCircleSize, height: Constants.checkCircleSize)
                .overlay(
                    Text("\(number)")
                        .font(.system(size: Constants.checkNumberFontSize, weight: .heavy))
                        .foregroundStyle(.white)
                )
                .padding(.top, Constants.checkCircleTopPadding)
            VStack(alignment: .leading, spacing: Constants.checkTextSpacing) {
                Text(title)
                    .font(.system(size: Constants.checkTitleFontSize, weight: .semibold))
                    .foregroundStyle(p.text1)
                    .fixedSize(horizontal: false, vertical: true)
                Text(sub)
                    .font(.system(size: Constants.checkSubFontSize))
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Constants.checkVPadding)
    }
}
