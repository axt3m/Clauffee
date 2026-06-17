//
//  OnboardingSheet.swift
//  Clauffee
//
//  Premier « Lancer le café » : trois vérifications uniques
//  (app Claude iPhone, même compte, /config) + l'encart qui explique
//  la limite par défaut, l'arrêt auto Claude et le comportement
//  à la réouverture du capot.
//

import SwiftUI

struct OnboardingOverlay: View {

    @EnvironmentObject private var state: AppState
    @State private var remoteConfirmed = false

    private var p: Palette { state.palette }
    private var s: Strings { state.strings }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .contentShape(Rectangle())
                .onTapGesture { } // bloque les clics vers le fond

            sheet
        }
        .transition(.opacity)
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            Text(s.obTitle)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(p.text1)
                .multilineTextAlignment(.center)

            Text(s.obIntro)
                .font(.system(size: 12))
                .foregroundStyle(p.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 5)
                .padding(.bottom, 10)

            check(1, s.ob1t, s.ob1s)
            divider
            check(2, s.ob2t, s.ob2s)
            divider
            check(3, s.ob3t, s.ob3s)

            // Encart : limite par défaut + arrêt auto Claude + capot
            HStack(alignment: .top, spacing: 8) {
                Text("⏱").font(.system(size: 13))
                Text(s.obNote(state.limitHours))
                    .font(.system(size: 11))
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 9)
            .padding(.horizontal, 11)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(p.caramel.opacity(0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(p.caramel.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.top, 11)

            // Confirmation explicite que /config est bien réglé —
            // débloque le bouton « infuser ».
            Button {
                remoteConfirmed.toggle()
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: remoteConfirmed ? "checkmark.square.fill" : "square")
                        .font(.system(size: 15))
                        .foregroundStyle(remoteConfirmed ? p.caramel : p.text2)
                    Text(s.obConfirm)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(p.text1)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 12)

            Button {
                state.completeOnboarding(start: true)
            } label: {
                Text(s.brewBtn)
                    .font(.system(size: 13.5, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(p.caramelGradient,
                                in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .shadow(color: p.caramelDeep.opacity(remoteConfirmed ? 0.4 : 0), radius: 7, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!remoteConfirmed)
            .opacity(remoteConfirmed ? 1 : 0.4)
            .animation(.easeOut(duration: 0.2), value: remoteConfirmed)
            .padding(.top, 12)

            Button {
                state.completeOnboarding(start: false)
            } label: {
                Text(s.skip)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(p.text2)
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 5)
        }
        .padding(EdgeInsets(top: 22, leading: 20, bottom: 14, trailing: 20))
        .background(
            // Feuille translucide « menu » : vibrancy + voile teinté, découpée
            // au rayon de la carte, bordure et ombre conservées.
            VisualEffectView(material: .popover)
                .overlay(p.popBg.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(p.cardBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 22, y: 12)
        )
        .padding(12)
    }

    private var divider: some View {
        Rectangle().fill(p.divider).frame(height: 1)
    }

    private func check(_ number: Int, _ title: String, _ sub: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Circle()
                .fill(p.caramelGradient)
                .frame(width: 22, height: 22)
                .overlay(
                    Text("\(number)")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundStyle(.white)
                )
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(p.text1)
                Text(sub)
                    .font(.system(size: 11.5))
                    .foregroundStyle(p.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
    }
}
