//
//  Theme.swift
//  CaffeLatte
//
//  Palettes Milk (Lait) / Espresso — les couleurs de la maquette v7.
//

import SwiftUI

enum Theme: String, CaseIterable {
    case milk, espresso
}

struct Palette {

    // Fonds
    let popBg: Color
    let card: Color
    let cardBorder: Color
    let divider: Color

    // Textes
    let text1: Color
    let text2: Color

    // Accents
    let caramel: Color
    let caramelDeep: Color
    let crema: Color
    let foam: Color
    let warn: Color
    let warnBg: Color

    // Composants
    let toggleOff: Color
    let badgeOff: [Color]
    let badgeOn: [Color]
    let segBg: Color
    let segSelected: Color
    let segSelectedText: Color
    let kbdBg: Color
    let kbdText: Color
    let liquidTop: Color
    let liquidBottom: Color
    let cremaSurface: Color

    var caramelGradient: LinearGradient {
        LinearGradient(colors: [caramel, caramelDeep],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func `for`(_ theme: Theme) -> Palette {
        theme == .milk ? .milk : .espresso
    }

    // MARK: Milk (clair)

    static let milk = Palette(
        popBg: Color(hex: 0xFAF4EB),
        card: Color.white.opacity(0.62),
        cardBorder: Color(hex: 0x3C2818).opacity(0.10),
        divider: Color(hex: 0x3C2818).opacity(0.08),
        text1: Color(hex: 0x2B1D14),
        text2: Color(hex: 0x8A7361),
        caramel: Color(hex: 0xC08A52),
        caramelDeep: Color(hex: 0xA06B38),
        crema: Color(hex: 0xE8C9A0),
        foam: Color(hex: 0xF6EEE3),
        warn: Color(hex: 0xA8502E),
        warnBg: Color(hex: 0xA8502E).opacity(0.10),
        toggleOff: Color(hex: 0x785A3C).opacity(0.25),
        badgeOff: [Color(hex: 0xF6EEE3), Color(hex: 0xEFDFC8)],
        badgeOn: [Color(hex: 0xE8C9A0), Color(hex: 0xD9A86B)],
        segBg: Color(hex: 0x785A3C).opacity(0.14),
        segSelected: Color(hex: 0xFDFAF5),
        segSelectedText: Color(hex: 0x2B1D14),
        kbdBg: Color(hex: 0x2B1D14),
        kbdText: Color(hex: 0xF1E2CC),
        liquidTop: Color(hex: 0xD9A86B),
        liquidBottom: Color(hex: 0x8A5A30),
        cremaSurface: Color(hex: 0xF2DCBA)
    )

    // MARK: Espresso (sombre)

    static let espresso = Palette(
        popBg: Color(hex: 0x22180F),
        card: Color(hex: 0xFFF4E6).opacity(0.07),
        cardBorder: Color(hex: 0xFFEBD2).opacity(0.10),
        divider: Color(hex: 0xFFEBD2).opacity(0.08),
        text1: Color(hex: 0xF4EADC),
        text2: Color(hex: 0xB49C87),
        caramel: Color(hex: 0xC08A52),
        caramelDeep: Color(hex: 0xA06B38),
        crema: Color(hex: 0xE8C9A0),
        foam: Color(hex: 0x3A2A1D),
        warn: Color(hex: 0xE8906B),
        warnBg: Color(hex: 0xE8906B).opacity(0.12),
        toggleOff: Color(hex: 0xFFEBD2).opacity(0.18),
        badgeOff: [Color(hex: 0x3A2A1D), Color(hex: 0x4A3522)],
        badgeOn: [Color(hex: 0x6B4A28), Color(hex: 0x8A5E33)],
        segBg: Color(hex: 0xFFEBD2).opacity(0.10),
        segSelected: Color(hex: 0x4A3522),
        segSelectedText: Color(hex: 0xE8C9A0),
        kbdBg: Color(hex: 0xF1E2CC),
        kbdText: Color(hex: 0x2B1D14),
        liquidTop: Color(hex: 0xD9A86B),
        liquidBottom: Color(hex: 0x8A5A30),
        cremaSurface: Color(hex: 0xF2DCBA)
    )
}

// MARK: - Toggle caramel

struct CaramelToggleStyle: ToggleStyle {
    let palette: Palette
    var small = false

    func makeBody(configuration: Configuration) -> some View {
        let width: CGFloat = small ? 32 : 46
        let height: CGFloat = small ? 19 : 27

        Button {
            configuration.isOn.toggle()
        } label: {
            Capsule()
                .fill(configuration.isOn
                      ? AnyShapeStyle(palette.caramelGradient)
                      : AnyShapeStyle(palette.toggleOff))
                .frame(width: width, height: height)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
                        .padding(2)
                }
                .animation(.spring(duration: 0.28, bounce: 0.25), value: configuration.isOn)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
