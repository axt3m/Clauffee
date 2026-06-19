//
//  SettingsView.swift
//  Clauffee
//
//  Réglages : Apparence (Lait/Expresso), Langue (EN/FR/RU), temps maximum
//  d'infusion (30 min → 9 h), Infusion éternelle, bulles, notification capot,
//  lancement à l'ouverture de session.
//
//  Les bascules persistées sont liées directement au SettingsStore ; les
//  actions à effet de bord passent par le SettingsViewModel.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var vm: SettingsViewModel

    init(vm: SettingsViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    private var p: Palette { settings.palette }
    private var s: Strings { settings.strings }
    private var accent: Color { settings.theme == .milk ? p.caramelDeep : p.crema }

    var body: some View {
        VStack(spacing: 8) {
            header
            appearanceCard
            brewCard
            miscCard
            about
        }
        .animation(.easeOut(duration: 0.25), value: settings.allUnlimited)
        .animation(.easeOut(duration: 0.25), value: settings.limitHours >= 5)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(s.settingsTitle)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(p.text1)
            HStack {
                Button {
                    vm.close()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text(s.back)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(accent)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.bottom, 2)
    }

    // MARK: - Apparence & langue

    private var appearanceCard: some View {
        card {
            segRow(title: s.appearance) {
                SegPicker(
                    options: [(Theme.milk, s.themeMilk), (Theme.espresso, s.themeEsp)],
                    selection: $settings.theme,
                    palette: p
                )
            }
            divider
            segRow(title: s.language) {
                SegPicker(
                    options: LanguagePref.allCases.map { ($0, $0.label) },
                    selection: $settings.languagePref,
                    palette: p
                )
            }
        }
    }

    // MARK: - Infusion

    private var brewCard: some View {
        card {
            // Jauge de limite
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text(s.limitTitle)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(p.text1)
                        Spacer()
                        Text(settings.limitLabel)
                            .font(.system(size: 12.5, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(accent)
                    }
                    // Slider sur l'INDICE de l'option (valeurs non régulières :
                    // 30 min puis heures entières).
                    Slider(
                        value: Binding(
                            get: { Double(SettingsStore.limitOptions.firstIndex(of: settings.limitHours) ?? 1) },
                            set: { idx in
                                let i = max(0, min(SettingsStore.limitOptions.count - 1, Int(idx.rounded())))
                                settings.limitHours = SettingsStore.limitOptions[i]
                            }
                        ),
                        in: 0...Double(SettingsStore.limitOptions.count - 1),
                        step: 1
                    )
                    .tint(p.caramelDeep)
                    .padding(.top, 2)
                    HStack(spacing: 0) {
                        ForEach(SettingsStore.limitOptions.indices, id: \.self) { i in
                            Text(SettingsStore.limitOptions[i] == 0.5 ? "½" : "\(Int(SettingsStore.limitOptions[i]))")
                                .font(.system(size: 9))
                                .foregroundStyle(p.text2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .opacity(settings.allUnlimited ? 0.35 : 1)
                .disabled(settings.allUnlimited)

                if !settings.allUnlimited && settings.limitHours >= 5 {
                    caution(big: false)
                        .padding(.top, 8)
                        .transition(.opacity)
                }
            }
            .padding(12)

            divider

            // Illimité global
            toggleRow(
                title: s.allUnlimited,
                sub: s.allUnlimitedSub,
                isOn: Binding(
                    get: { settings.allUnlimited },
                    set: { vm.setAllUnlimited($0) }
                )
            )
            if settings.allUnlimited {
                caution(big: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Divers

    private var miscCard: some View {
        card {
            toggleRow(title: s.funToasts, sub: nil, isOn: $settings.funToasts)
            divider
            toggleRow(title: s.lidNotif, sub: s.lidNotifSub, isOn: $settings.lidNotification)
            divider
            toggleRow(title: s.launchLogin, sub: s.launchLoginSub, isOn: $settings.launchAtLogin)
        }
    }

    private var about: some View {
        Text(s.about)
            .font(.system(size: 10.5))
            .foregroundStyle(p.text2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
            .padding(.bottom, 8)
            .padding(.horizontal, 4)
    }

    // MARK: - Briques

    private var divider: some View {
        Rectangle().fill(p.divider).frame(height: 1)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
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

    private func segRow(title: String, @ViewBuilder control: () -> some View) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(p.text1)
                .lineLimit(1)
            Spacer(minLength: 8)
            control()
                .layoutPriority(1)   // le sélecteur garde sa taille, jamais tronqué
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private func toggleRow(title: String, sub: String?, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(p.text1)
                    .fixedSize(horizontal: false, vertical: true)
                if let sub {
                    Text(sub)
                        .font(.system(size: 10.5))
                        .foregroundStyle(p.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(CaramelToggleStyle(palette: p, small: true))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private func caution(big: Bool) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Text("⚠️")
                .font(.system(size: big ? 20 : 13))
            Text(s.heatCaution)
                .font(.system(size: big ? 11 : 10.5, weight: .semibold))
                .foregroundStyle(p.warn)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(big ? 10 : 0)
        .background(
            big ? AnyShapeStyle(p.warnBg) : AnyShapeStyle(Color.clear),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}

// MARK: - Sélecteur segmenté capsule

struct SegPicker<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    let palette: Palette

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    selection = option.0
                } label: {
                    Text(option.1)
                        .font(.system(size: 11, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(
                            selection == option.0
                                ? AnyShapeStyle(palette.segSelected)
                                : AnyShapeStyle(Color.clear),
                            in: Capsule()
                        )
                        .foregroundStyle(selection == option.0
                                         ? palette.segSelectedText
                                         : palette.text2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2.5)
        .background(palette.segBg, in: Capsule())
        .animation(.easeOut(duration: 0.2), value: selection)
    }
}
