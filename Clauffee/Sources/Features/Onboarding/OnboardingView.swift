//
//  OnboardingView.swift
//  Clauffee
//
//  Premier « Lancer le café » : trois vérifications uniques
//  (app Claude iPhone, même compte, /config) + l'encart qui explique
//  la limite par défaut et le comportement à la réouverture du capot.
//

import SwiftUI

private struct Constants {
    static let scrimOpacity: Double = 0.35

    // Titre / intro
    static let titleFontSize: CGFloat = 14
    static let introFontSize: CGFloat = 12
    static let introTopPadding: CGFloat = 5
    static let introBottomPadding: CGFloat = 10

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
    static let checkSpacing: CGFloat = 11
    static let checkCircleSize: CGFloat = 22
    static let checkNumberFontSize: CGFloat = 11.5
    static let checkTitleFontSize: CGFloat = 12.5
    static let checkSubFontSize: CGFloat = 11.5
    static let checkVPadding: CGFloat = 9
    static let checkCircleTopPadding: CGFloat = 1
    static let checkTextSpacing: CGFloat = 2
}

struct OnboardingView: View {

    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var vm: OnboardingViewModel

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
        }
        .transition(.opacity)
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            Text(s.obTitle)
                .font(.system(size: Constants.titleFontSize, weight: .heavy, design: .rounded))
                .foregroundStyle(p.text1)
                .multilineTextAlignment(.center)

            Text(s.obIntro)
                .font(.system(size: Constants.introFontSize))
                .foregroundStyle(p.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Constants.introTopPadding)
                .padding(.bottom, Constants.introBottomPadding)

            check(1, s.ob1t, s.ob1s)
            divider
            check(2, s.ob2t, s.ob2s)
            divider
            check(3, s.ob3t, s.ob3s)

            // Encart : limite par défaut + comportement capot
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

            // Confirmation explicite que /config est bien réglé —
            // débloque le bouton.
            Button {
                vm.remoteConfirmed.toggle()
            } label: {
                HStack(alignment: .top, spacing: Constants.confirmSpacing) {
                    Image(systemName: vm.remoteConfirmed ? "checkmark.square.fill" : "square")
                        .font(.system(size: Constants.confirmIconFontSize))
                        .foregroundStyle(vm.remoteConfirmed ? p.caramel : p.text2)
                    Text(s.obConfirm)
                        .font(.system(size: Constants.confirmFontSize, weight: .medium))
                        .foregroundStyle(p.text1)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, Constants.confirmTopPadding)

            Button {
                vm.complete(start: true)
            } label: {
                Text(s.brewBtn)
                    .font(.system(size: Constants.brewFontSize, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.brewVPadding)
                    .background(p.caramelGradient,
                                in: RoundedRectangle(cornerRadius: Constants.brewCorner, style: .continuous))
                    .shadow(color: p.caramelDeep.opacity(vm.remoteConfirmed ? Constants.brewShadowOpacity : 0),
                            radius: Constants.brewShadowRadius, y: Constants.brewShadowY)
            }
            .buttonStyle(.plain)
            .disabled(!vm.remoteConfirmed)
            .opacity(vm.remoteConfirmed ? 1 : Constants.brewDisabledOpacity)
            .animation(.easeOut(duration: Constants.brewAnimation), value: vm.remoteConfirmed)
            .padding(.top, Constants.brewTopPadding)

            Button {
                vm.complete(start: false)
            } label: {
                Text(s.skip)
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
        .background(
            // Feuille translucide « menu » : vibrancy + voile teinté, découpée
            // au rayon de la carte, bordure et ombre conservées.
            VisualEffectView(material: .popover)
                .overlay(p.popBg.opacity(Constants.sheetTintOpacity))
                .clipShape(RoundedRectangle(cornerRadius: Constants.sheetCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.sheetCorner, style: .continuous)
                        .strokeBorder(p.cardBorder, lineWidth: Constants.sheetBorderWidth)
                )
                .shadow(color: .black.opacity(Constants.sheetShadowOpacity),
                        radius: Constants.sheetShadowRadius, y: Constants.sheetShadowY)
        )
        .padding(Constants.sheetOuterPadding)
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
