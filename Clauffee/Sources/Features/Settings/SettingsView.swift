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

private struct Constants {
    static let cardSpacing: CGFloat = 8
    static let animation: Double = 0.25
    static let heatThresholdHours: Double = 5

    // Header
    static let titleFontSize: CGFloat = 15
    static let chevronFontSize: CGFloat = 11
    static let backFontSize: CGFloat = 13
    static let backVPadding: CGFloat = 3
    static let backHPadding: CGFloat = 4
    static let headerBottomPadding: CGFloat = 2

    // Cartes
    static let cardCorner: CGFloat = 14
    static let borderWidth: CGFloat = 1
    static let dividerHeight: CGFloat = 1

    // Ligne segment
    static let rowSpacing: CGFloat = 10
    static let rowSpacerMin: CGFloat = 8
    static let labelFontSize: CGFloat = 12.5
    static let rowHPadding: CGFloat = 12
    static let rowVPadding: CGFloat = 9

    // Jauge de limite
    static let valueFontSize: CGFloat = 12.5
    static let sliderTopPadding: CGFloat = 2
    static let tickFontSize: CGFloat = 9
    static let tickHPadding: CGFloat = 2
    static let disabledOpacity: Double = 0.35
    static let cautionTopPadding: CGFloat = 8
    static let gaugePadding: CGFloat = 12
    static let halfHour: Double = 0.5

    // toggleRow
    static let subFontSize: CGFloat = 10.5

    // about
    static let aboutFontSize: CGFloat = 10.5
    static let aboutTopPadding: CGFloat = 2
    static let aboutBottomPadding: CGFloat = 8
    static let aboutHPadding: CGFloat = 4

    // caution
    static let cautionSpacing: CGFloat = 7
    static let cautionEmojiBig: CGFloat = 20
    static let cautionEmojiSmall: CGFloat = 13
    static let cautionTextBig: CGFloat = 11
    static let cautionTextSmall: CGFloat = 10.5
    static let cautionPadding: CGFloat = 10
    static let cautionCorner: CGFloat = 10

    // SegPicker
    static let segSpacing: CGFloat = 2
    static let segFontSize: CGFloat = 11
    static let segHPadding: CGFloat = 8
    static let segVPadding: CGFloat = 3.5
    static let segOuterPadding: CGFloat = 2.5
    static let segAnimation: Double = 0.2
}

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
        VStack(spacing: Constants.cardSpacing) {
            header
            appearanceCard
            brewCard
            miscCard
            about
        }
        .animation(.easeOut(duration: Constants.animation), value: settings.allUnlimited)
        .animation(.easeOut(duration: Constants.animation), value: settings.limitHours >= Constants.heatThresholdHours)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(s.settingsTitle)
                .font(.system(size: Constants.titleFontSize, weight: .heavy))
                .foregroundStyle(p.text1)
            HStack {
                Button {
                    vm.close()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: Constants.chevronFontSize, weight: .semibold))
                        Text(s.back)
                            .font(.system(size: Constants.backFontSize, weight: .semibold))
                    }
                    .foregroundStyle(accent)
                    .padding(.vertical, Constants.backVPadding)
                    .padding(.horizontal, Constants.backHPadding)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.bottom, Constants.headerBottomPadding)
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
                            .font(.system(size: Constants.labelFontSize, weight: .semibold))
                            .foregroundStyle(p.text1)
                        Spacer()
                        Text(settings.limitLabel)
                            .font(.system(size: Constants.valueFontSize, weight: .bold))
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
                    .padding(.top, Constants.sliderTopPadding)
                    HStack(spacing: 0) {
                        ForEach(SettingsStore.limitOptions.indices, id: \.self) { i in
                            Text(SettingsStore.limitOptions[i] == Constants.halfHour ? "½" : "\(Int(SettingsStore.limitOptions[i]))")
                                .font(.system(size: Constants.tickFontSize))
                                .foregroundStyle(p.text2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, Constants.tickHPadding)
                }
                .opacity(settings.allUnlimited ? Constants.disabledOpacity : 1)
                .disabled(settings.allUnlimited)

                if !settings.allUnlimited && settings.limitHours >= Constants.heatThresholdHours {
                    caution(big: false)
                        .padding(.top, Constants.cautionTopPadding)
                        .transition(.opacity)
                }
            }
            .padding(Constants.gaugePadding)

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
                    .padding(.horizontal, Constants.gaugePadding)
                    .padding(.bottom, Constants.cautionTopPadding)
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

    /// Version affichée, lue depuis le bundle (MARKETING_VERSION) → jamais à
    /// mettre à jour à la main.
    private static let appVersion = Bundle.main
        .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"

    private var about: some View {
        Text("Clauffee v\(Self.appVersion) · \(s.about)")
            .font(.system(size: Constants.aboutFontSize))
            .foregroundStyle(p.text2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.top, Constants.aboutTopPadding)
            .padding(.bottom, Constants.aboutBottomPadding)
            .padding(.horizontal, Constants.aboutHPadding)
    }

    // MARK: - Briques

    private var divider: some View {
        Rectangle().fill(p.divider).frame(height: Constants.dividerHeight)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
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

    private func segRow(title: String, @ViewBuilder control: () -> some View) -> some View {
        HStack(spacing: Constants.rowSpacing) {
            Text(title)
                .font(.system(size: Constants.labelFontSize, weight: .semibold))
                .foregroundStyle(p.text1)
                .lineLimit(1)
            Spacer(minLength: Constants.rowSpacerMin)
            control()
                .layoutPriority(1)   // le sélecteur garde sa taille, jamais tronqué
        }
        .padding(.horizontal, Constants.rowHPadding)
        .padding(.vertical, Constants.rowVPadding)
    }

    private func toggleRow(title: String, sub: String?, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: Constants.rowSpacing) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: Constants.labelFontSize, weight: .semibold))
                    .foregroundStyle(p.text1)
                    .fixedSize(horizontal: false, vertical: true)
                if let sub {
                    Text(sub)
                        .font(.system(size: Constants.subFontSize))
                        .foregroundStyle(p.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Constants.rowSpacerMin)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(CaramelToggleStyle(palette: p, small: true))
        }
        .padding(.horizontal, Constants.rowHPadding)
        .padding(.vertical, Constants.rowVPadding)
    }

    private func caution(big: Bool) -> some View {
        HStack(alignment: .top, spacing: Constants.cautionSpacing) {
            Text("⚠️")
                .font(.system(size: big ? Constants.cautionEmojiBig : Constants.cautionEmojiSmall))
            Text(s.heatCaution)
                .font(.system(size: big ? Constants.cautionTextBig : Constants.cautionTextSmall, weight: .semibold))
                .foregroundStyle(p.warn)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(big ? Constants.cautionPadding : 0)
        .background(
            big ? AnyShapeStyle(p.warnBg) : AnyShapeStyle(Color.clear),
            in: RoundedRectangle(cornerRadius: Constants.cautionCorner, style: .continuous)
        )
    }
}

// MARK: - Sélecteur segmenté capsule

struct SegPicker<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    let palette: Palette

    var body: some View {
        HStack(spacing: Constants.segSpacing) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                Button {
                    selection = option.0
                } label: {
                    Text(option.1)
                        .font(.system(size: Constants.segFontSize, weight: .semibold))
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, Constants.segHPadding)
                        .padding(.vertical, Constants.segVPadding)
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
        .padding(Constants.segOuterPadding)
        .background(palette.segBg, in: Capsule())
        .animation(.easeOut(duration: Constants.segAnimation), value: selection)
    }
}
