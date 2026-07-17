//
//  L10n.swift
//  Clauffee
//
//  Localisation EN / FR / RU.
//  Choix délibéré d'un système maison plutôt qu'un String Catalog :
//  le changement de langue dans les Réglages est instantané, sans relancer l'app
//  (un .xcstrings nécessiterait un override AppleLanguages + relaunch).
//  Au premier lancement, on suit la langue système.
//

import Carbon
import Foundation

enum Language: String, CaseIterable, Identifiable {
    case en, fr, ru

    var id: String { rawValue }
    var label: String { rawValue.uppercased() }

    /// Langue système au premier lancement (EN par défaut).
    static var systemDefault: Language {
        let code = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
        return Language(rawValue: String(code)) ?? .en
    }

    /// Langue de la source de saisie (clavier) active.
    /// Repli EN si le clavier ne référence aucune langue supportée.
    static var fromKeyboard: Language {
        guard let src = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(src, kTISPropertyInputSourceLanguages)
        else { return .en }

        let langs = Unmanaged<CFArray>.fromOpaque(ptr).takeUnretainedValue() as? [String] ?? []
        for code in langs {
            if let lang = Language(rawValue: String(code.prefix(2)).lowercased()) {
                return lang
            }
        }
        return .en
    }
}

/// Choix utilisateur de langue : Auto (suit le clavier) ou explicite.
enum LanguagePref: String, CaseIterable, Identifiable {
    case auto, en, fr, ru

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto: return "Auto"
        case .en, .fr, .ru: return rawValue.uppercased()
        }
    }

    /// Langue effective pour le choix des chaînes.
    var resolved: Language {
        switch self {
        case .auto: return .fromKeyboard
        case .en: return .en
        case .fr: return .fr
        case .ru: return .ru
        }
    }
}

struct Strings {

    // MARK: Statuts & ligne principale
    let statusOff: String
    let statusOn: String
    let brewTitle: String
    let brewingTitle: String
    let unlimitedWord: String
    let brewSubOff: String
    let brewSubOn: String

    // MARK: Ligne minuteur
    let awakeFmt: String        // "En chauffe depuis %@"
    let autoOffFmt: String      // "Arrêt auto dans %@ — pour rester au frais"
    let noLimit: String

    // MARK: Ligne sessions Claude
    let sessions: (Int) -> String
    let sessionsSubActive: String
    let sessionsSubIdle: String

    // MARK: Footer
    let sessionUnlimitedLabel: String
    let unlimitedFooter: String
    let quit: String

    // MARK: Toasts
    let toasts: [(emoji: String, text: String)]
    let heatToast: (emoji: String, text: String)
    let autoOffToast: (String) -> (emoji: String, text: String)
    let claudeOffToast: (emoji: String, text: String)

    // MARK: Notifications
    let notifAsk: String
    let keep: String
    let off: String
    let notifDone: (String) -> String
    let ok: String

    // MARK: Onboarding
    let obTitle: String
    let obIntro: String
    let ob1t: String, ob1s: String
    let ob2t: String, ob2s: String
    let ob3t: String, ob3s: String
    let obNote: (String) -> String
    let obConfirm: String
    let obAccountApi: String
    let obAccountApiSub: String
    let obAccountPro: String
    let obAccountProSub: String
    let obNotif: String
    let obNotifSub: String
    let obNotifOn: String
    let obNotifDenied: String
    // Style d'alerte courant (lu via UNNotificationSettings.alertStyle) + lien
    let obNotifStylePersistent: String
    let obNotifStyleTemporary: String
    let obNotifStyleSilent: String
    let obNotifSettings: String
    let obNotifStyleLabel: String   // préfixe « Notifications : » (le mot suit, coloré)
    // Écran de bienvenue (après le choix, avant la vue normale)
    let obWelcomeTitle: String
    let obWelcomeBody: String
    let obWelcomeReminderOn: String
    let obWelcomeReminderOff: String
    let obWelcomeBtn: String
    let obNext: String
    let skip: String
    let obBack: String
    let obStyleWarnTitle: String
    let obStyleWarnBody: String
    let obStyleWarnConfirm: String

    // MARK: Erreur sudoers
    let errTitle: String
    let errBody: String
    let retry: String
    let copy: String
    let copied: String

    // MARK: Réglages
    let back: String
    let settingsTitle: String
    let appearance: String
    let language: String
    let themeMilk: String
    let themeEsp: String
    let limitTitle: String
    let heatCaution: String
    let allUnlimited: String
    let allUnlimitedSub: String
    let claudeStop: String
    let claudeStopSub: String
    let funToasts: String
    let lidNotif: String
    let lidNotifSub: String
    let launchLogin: String
    let launchLoginSub: String
    let about: String

    func awake(_ v: String) -> String { String(format: awakeFmt, v) }
    func autoOff(_ v: String) -> String { String(format: autoOffFmt, v) }

    static func `for`(_ lang: Language) -> Strings {
        switch lang {
        case .en: return .en
        case .fr: return .fr
        case .ru: return .ru
        }
    }
}

// MARK: - English

extension Strings {
    static let en = Strings(
        statusOff: "No sleep block active",
        statusOn: "Keep calm and keep Clauding… 🧘🏻‍♀️",
        brewTitle: "Start Brew",
        brewingTitle: "Brewing…",
        unlimitedWord: "Unlimited",
        brewSubOff: "Blocks sleep — even with the lid closed",
        brewSubOn: "Sleep is blocked — safe to close the lid",
        awakeFmt: "Brewing for %@",
        autoOffFmt: "Auto-off in %@ — keeps things cool",
        noLimit: "No auto-off — watch the heat",
        sessions: { n in
            n == 0 ? "No Claude Code sessions open"
                   : "\(n) Claude Code session\(n > 1 ? "s" : "") open"
        },
        sessionsSubActive: "Remote Control on · pushes go to your iPhone",
        sessionsSubIdle: "Nothing running — no need to keep warm",
        sessionUnlimitedLabel: "Unlimited block for this session",
        unlimitedFooter: "Unlimited block",
        quit: "Quit",
        toasts: [
            ("🍮", "Lay me flat & plugged in — it's about to get toasty"),
            ("☕", "Espresso yourself — Claude's listening"),
            ("♨️", "Fresh tokens, hot off the roaster"),
            ("🧘", "Decaf is for quitters"),
            ("🤫", "Shhh… the barista is compiling"),
            ("🌙", "Night shift: beans on, lid down"),
            ("🚀", "May your builds be green and your latte strong"),
            ("🫘", "Grinding beans and tokens since 09:41"),
            ("🧠", "Big brain time — double shot, zero sleep"),
            ("🐛", "Bugs fear the smell of fresh coffee"),
            ("♾️", "while(awake) { claude() }"),
            ("🔌", "Plugged in, tuned in, clauding on"),
            ("🥛", "Steamed milk, steamed CPU — easy on both"),
            ("📦", "Shipping features, sipping lattes"),
            ("🤖", "The agent never sleeps. Neither does your Mac now"),
            ("☁️", "Head in the cloud, beans on the ground"),
            ("🎯", "One more token, one more sip"),
            ("☕", "Compiling caffeine…"),
            ("🔥", "Hot loop, hotter brew"),
            ("🫖", "Steeping code, one commit at a time"),
            ("🧋", "Certified productivi-tea"),
            ("💾", "Saving state, savoring taste"),
            ("🐙", "Merge conflicts fear the espresso"),
            ("🎩", "Abracadabra — your Mac stays awake"),
            ("🛰️", "Ground control to major roast"),
            ("🪫", "Low battery is a lifestyle — plug in"),
            ("🍩", "Donuts optional, uptime mandatory"),
            ("🧊", "Cool head, warm mug"),
            ("🥐", "Croissant loaded, context loaded"),
            ("🎬", "Lights, camera, claude"),
            ("🧩", "Every token, a puzzle piece"),
            ("🕹️", "Player one never sleeps"),
            ("📡", "Streaming tokens, steaming milk"),
            ("🦉", "Owl mode: lid down, beans up"),
            ("🎧", "Lo-fi beats, high-test beans"),
            ("🚦", "Green tests, green light, go"),
            ("🧭", "Lost in the code? Follow the coffee"),
            ("🛠️", "Building dreams, brewing beans"),
            ("🐝", "Busy as a bean"),
            ("🎈", "Light on sleep, heavy on shipping"),
            ("🧀", "Say cheese, ship the release"),
            ("🌊", "Riding the token wave"),
            ("🌵", "Stay hydrated… with caffeine"),
            ("🪐", "Beans aligned, stars aligned"),
            ("🧙", "Prompt wizard at work"),
            ("🔋", "Charged up, chilled out"),
            ("🌞", "Who needs sleep when the beans are fresh?"),
        ],
        heatToast: ("🔥", "Long brew ahead — flat, plugged in, never in a bag"),
        autoOffToast: { label in ("😴", "Brew ended after \(label) — staying cool") },
        claudeOffToast: ("😴", "No Claude sessions left — brew stopped"),
        notifAsk: "You're back! 👋 Turn off the brew?",
        keep: "Keep on",
        off: "Turn off",
        notifDone: { v in "You're back! ☕ The brew already ended — \(v) total" },
        ok: "OK",
        obTitle: "Before your first Clauffee\nsession ☕",
        obIntro: "How do you use Claude?",
        ob1t: "Claude app on your iPhone",
        ob1s: "Install the app and allow notifications.",
        ob2t: "Same account everywhere",
        ob2s: "Sign in with the same claude.ai account as your terminal.",
        ob3t: "Claude Code config",
        ob3s: "Run /config and set “Remote Control for all sessions”, “Push when actions required” and “Push when Claude decides” to true.\nYou won't need to type /\u{2060}remote\u{2011}control in each session.",
        obNote: { label in "Every new session starts with a \(label) block limit — adjustable in Settings ⚙︎." },
        obConfirm: "I enabled Remote Control + both push notifications",
        obAccountApi: "API key (Claude Code only)",
        obAccountApiSub: "Remote Control unavailable — reopen your Mac to take over.",
        obAccountPro: "Pro, Max or Team account",
        obAccountProSub: "Remote Control available — reply to Claude from your phone, lid closed.",
        obNotif: "Enable the stop-session reminder",
        obNotifSub: "Set the alert style to “Persistent” so you remember to stop your Clauffee session when you reopen your Mac.",
        obNotifOn: "Stop reminder enabled ✓",
        obNotifDenied: "Blocked — open System Settings > Notifications > Clauffee > Alert style: Persistent",
        obNotifStylePersistent: "Persistent",
        obNotifStyleTemporary: "Temporary",
        obNotifStyleSilent: "Silent",
        obNotifSettings: "Settings",
        obNotifStyleLabel: "Notifications: ",
        obWelcomeTitle: "You're all set! ☕",
        obWelcomeBody: "Clauffee keeps your Claude Code sessions alive even while your Mac sleeps or its lid is closed.",
        obWelcomeReminderOn: " When you reopen your computer, Clauffee will offer to stop the session.",
        obWelcomeReminderOff: " Soon, switch the alert style to “Persistent” in Settings so Clauffee can offer to stop the session.",
        obWelcomeBtn: "Let's go!",
        obNext: "Next",
        skip: "Remind me later",
        obBack: "Back",
        obStyleWarnTitle: "Are you sure you don't want to change the notification alert style?",
        obStyleWarnBody: "Alert notifications let you stop the session when you reopen your Mac.",
        obStyleWarnConfirm: "Yes, I'm sure",
        errTitle: "One-time permission needed",
        errBody: "Clauffee toggles sleep with pmset, which needs admin rights. Paste this once in Terminal, then try again:",
        retry: "Try again",
        copy: "Copy",
        copied: "Copied ✓",
        back: "Back",
        settingsTitle: "Settings",
        appearance: "Appearance",
        language: "Language",
        themeMilk: "Milk",
        themeEsp: "Espresso",
        limitTitle: "Maximum brew time",
        heatCaution: "Heat risk — lay the Mac flat, plugged in, in open air. Never in a bag.",
        allUnlimited: "Eternal brew",
        allUnlimitedSub: "Blocks sleep with no time limit — your Mac will never go to sleep",
        claudeStop: "Auto-stop when Claude is done",
        claudeStopSub: "Stops the brew when the last Claude Code session ends",
        funToasts: "Message bubble when a session starts",
        lidNotif: "“You're back” notification",
        lidNotifSub: "Shown when you come back (reopen the lid, wake, or unlock), a reminder to stop the session. Turns off the reminder, not the system permission.",
        launchLogin: "Keep Clauffee in the menu bar",
        launchLoginSub: "Relaunches automatically each time you log in",
        about: "Quitting saves your settings and always restores normal sleep"
    )
}

// MARK: - Français

extension Strings {
    static let fr = Strings(
        statusOff: "Aucune veille bloquée actuellement",
        statusOn: "Et que ça Claude ! ✨",
        brewTitle: "Lancer le Clauffee",
        brewingTitle: "Ça infuse…",
        unlimitedWord: "Illimité",
        brewSubOff: "Bloque la veille — même capot fermé",
        brewSubOn: "Veille bloquée — tu peux fermer le capot",
        awakeFmt: "En chauffe depuis %@",
        autoOffFmt: "Arrêt auto dans %@ — pour rester au frais",
        noLimit: "Pas d'arrêt auto — surveille la chauffe",
        sessions: { n in
            n == 0 ? "Aucune session Claude Code ouverte"
                   : "\(n) session\(n > 1 ? "s" : "") Claude Code ouverte\(n > 1 ? "s" : "")"
        },
        sessionsSubActive: "Remote Control actif · notifs sur ton iPhone",
        sessionsSubIdle: "Rien ne tourne — plus besoin de chauffer",
        sessionUnlimitedLabel: "Blocage illimité pour cette session",
        unlimitedFooter: "Blocage illimité",
        quit: "Quitter",
        toasts: [
            ("🍮", "Pose-moi à plat et branché — ça va chauffer là-dessous"),
            ("☕", "Un petit café, un grand refactor"),
            ("♨️", "Tokens fraîchement torréfiés"),
            ("🧘", "Le déca, c'est pour les lâcheurs"),
            ("🤫", "Chut… le barista compile"),
            ("🌙", "Service de nuit : grains on, capot down"),
            ("🚀", "Que tes builds soient verts et ton latte serré"),
            ("🫘", "On moud des grains et des tokens depuis 09:41"),
            ("🧠", "Mode grand cerveau — double shot, zéro veille"),
            ("🐛", "Les bugs craignent l'odeur du café frais"),
            ("♾️", "while(éveillé) { claude() }"),
            ("🔌", "Branché, posé, claudé"),
            ("🥛", "Lait vapeur, CPU vapeur — doucement sur les deux"),
            ("📦", "On ship des features, on sirote des lattes"),
            ("🤖", "L'agent ne dort jamais. Ton Mac non plus, maintenant"),
            ("☁️", "La tête dans le cloud, les grains sur terre"),
            ("🎯", "Encore un token, encore une gorgée"),
            ("☕", "Compilation de caféine…"),
            ("🔥", "Ça mouline, ça mijote"),
            ("🫖", "Le code infuse, commit après commit"),
            ("🧋", "Productivi-thé certifiée"),
            ("💾", "On sauvegarde, on savoure"),
            ("🐙", "Les conflits de merge redoutent l'espresso"),
            ("🎩", "Abracadabra — ton Mac reste éveillé"),
            ("🛰️", "Allô la Terre ? Ici Major Torréfaction"),
            ("🪫", "Batterie faible ? Un mode de vie. Branche-toi"),
            ("🍩", "Donuts optionnels, uptime obligatoire"),
            ("🧊", "Tête froide, mug chaud"),
            ("🥐", "Croissant chargé, contexte chargé"),
            ("🎬", "Silence, ça claude !"),
            ("🧩", "Chaque token, une pièce du puzzle"),
            ("🕹️", "Le Joueur 1 ne dort jamais"),
            ("📡", "Tokens en streaming, lait en vapeur"),
            ("🦉", "Mode hibou : capot fermé, grains à fond"),
            ("🎧", "Beats lo-fi, grains haute tension"),
            ("🚦", "Tests verts, feu vert, go"),
            ("🧭", "Perdu dans le code ? Suis l'odeur du café"),
            ("🛠️", "On bâtit des rêves, on infuse des grains"),
            ("🐝", "Ça bourdonne, ça moud, ça code"),
            ("🎈", "Léger en sommeil, lourd en livraisons"),
            ("🧀", "Souris : la release part"),
            ("🌊", "On surfe sur la vague de tokens"),
            ("🌵", "Reste hydraté… à la caféine"),
            ("🪐", "Grains alignés, étoiles alignées"),
            ("🧙", "Sorcier du prompt au travail"),
            ("🔋", "Chargé à bloc, détendu"),
            ("🌞", "Qui a besoin de dormir quand les grains sont frais ?"),
        ],
        heatToast: ("🔥", "Longue infusion — à plat, branché, jamais dans un sac"),
        autoOffToast: { label in ("😴", "Infusion terminée après \(label) — on reste au frais") },
        claudeOffToast: ("😴", "Plus de session Claude — infusion arrêtée"),
        notifAsk: "Te revoilà ! 👋 On arrête l'infusion ?",
        keep: "Continuer",
        off: "Arrêter",
        notifDone: { v in "Te revoilà ! ☕ L'infusion s'est terminée toute seule — \(v) de brew" },
        ok: "OK",
        obTitle: "Avant ta première\nsession Clauffee ☕",
        obIntro: "Comment utilises-tu Claude ?",
        ob1t: "L'app Claude sur ton iPhone",
        ob1s: "Installe l'application et autorise les notifications.",
        ob2t: "Le même compte partout",
        ob2s: "Connecte-toi avec le même compte claude.ai que dans ton terminal.",
        ob3t: "Config Claude Code",
        ob3s: "Lance /config et mets à true « Remote Control for all sessions », « Push when actions required » et « Push when Claude decides ».\nTu n'auras plus besoin de taper /\u{2060}remote\u{2011}control dans chaque session.",
        obNote: { label in "Chaque nouvelle session démarre avec un temps limite de \(label) de blocage — modifiable dans les Réglages ⚙︎." },
        obConfirm: "J'ai activé Remote Control + les deux notifications push",
        obAccountApi: "Clé API (Claude Code seul)",
        obAccountApiSub: "Remote Control non accessible — rouvre ton Mac pour reprendre la main.",
        obAccountPro: "Compte Pro, Max ou Team",
        obAccountProSub: "Remote Control disponible — réponds à Claude depuis ton téléphone, capot fermé.",
        obNotif: "Activer le rappel d'arrêt de session",
        obNotifSub: "Sélectionne « Persistant » comme style d'alerte pour penser à arrêter la session Clauffee à la réouverture de ton Mac.",
        obNotifOn: "Rappel d'arrêt activé ✓",
        obNotifDenied: "Bloquées — ouvre Réglages Système > Notifications > Clauffee > Style d'alerte : Persistant",
        obNotifStylePersistent: "Persistant",
        obNotifStyleTemporary: "Temporaire",
        obNotifStyleSilent: "Silencieux",
        obNotifSettings: "Réglages",
        obNotifStyleLabel: "Notifications : ",
        obWelcomeTitle: "Tout est prêt ! ☕",
        obWelcomeBody: "Clauffee garde tes sessions Claude Code vivantes, malgré la veille ou la fermeture de ton Mac.",
        obWelcomeReminderOn: " À la réouverture de ton ordinateur, Clauffee te proposera d'arrêter la session.",
        obWelcomeReminderOff: " Pense à passer le style d'alerte sur « Persistant » dans les Réglages pour que Clauffee te propose d'arrêter la session.",
        obWelcomeBtn: "C'est parti !",
        obNext: "Suivant",
        skip: "Me le rappeler plus tard",
        obBack: "Retour",
        obStyleWarnTitle: "Es-tu sûr·e de ne pas vouloir changer le style d'alerte pour les notifications ?",
        obStyleWarnBody: "Les notifications d'alerte permettent d'arrêter la session à la réouverture du Mac.",
        obStyleWarnConfirm: "Oui, j'en suis sûr·e",
        errTitle: "Autorisation unique requise",
        errBody: "Clauffee pilote la veille via pmset, qui demande les droits admin. Colle ça une fois dans le Terminal puis réessaie :",
        retry: "Réessayer",
        copy: "Copier",
        copied: "Copié ✓",
        back: "Retour",
        settingsTitle: "Réglages",
        appearance: "Apparence",
        language: "Langue",
        themeMilk: "Lait",
        themeEsp: "Expresso",
        limitTitle: "Temps maximum d'infusion",
        heatCaution: "Risque de chauffe — Mac à plat, branché, à l'air libre. Jamais dans un sac.",
        allUnlimited: "Infusion éternelle",
        allUnlimitedSub: "Bloque la veille sans temps limite — L'ordinateur ne se mettra jamais en veille",
        claudeStop: "Arrêt auto sans session Claude",
        claudeStopSub: "Stoppe l'infusion quand la dernière session Claude Code se termine",
        funToasts: "Bulle de message au lancement d'une session",
        lidNotif: "Notification « Te revoilà »",
        lidNotifSub: "Affichée à ton retour (réouverture du capot, réveil ou déverrouillage), pour penser à couper la session. Coupe le rappel d'arrêt, pas la permission système.",
        launchLogin: "Garder Clauffee dans la barre des menus",
        launchLoginSub: "Se relance automatiquement à chaque ouverture de session",
        about: "Quitter sauvegarde tes réglages et rétablit toujours la veille normale"
    )
}

// MARK: - Русский

extension Strings {
    static let ru = Strings(
        statusOff: "Блокировка сна сейчас не активна",
        statusOn: "Спокойствие, только Claude ✨",
        brewTitle: "Заварить кофе",
        brewingTitle: "Заваривается…",
        unlimitedWord: "Безлимит",
        brewSubOff: "Блокирует сон — даже с закрытой крышкой",
        brewSubOn: "Сон заблокирован — крышку можно закрыть",
        awakeFmt: "Варится %@",
        autoOffFmt: "Авто-стоп через %@ — чтобы не перегреться",
        noLimit: "Без авто-стопа — следи за нагревом",
        sessions: { n in
            if n == 0 { return "Нет открытых сессий Claude Code" }
            if n == 1 { return "1 сессия Claude Code открыта" }
            if n < 5 { return "\(n) сессии Claude Code открыты" }
            return "\(n) сессий Claude Code открыто"
        },
        sessionsSubActive: "Remote Control включён · пуши идут на iPhone",
        sessionsSubIdle: "Ничего не запущено — греть незачем",
        sessionUnlimitedLabel: "Безлимитная блокировка для этой сессии",
        unlimitedFooter: "Безлимитная блокировка",
        quit: "Выйти",
        toasts: [
            ("🍮", "Положи меня ровно и подключи — будет жарко"),
            ("☕", "Маленький кофе — большой рефакторинг"),
            ("♨️", "Свежеобжаренные токены подъехали"),
            ("🧘", "Без кофеина — без коммитов"),
            ("🤫", "Тсс… бариста компилирует"),
            ("🌙", "Ночная смена: зёрна в деле, крышка закрыта"),
            ("🚀", "Зелёных билдов и крепкого латте"),
            ("🫘", "Мелем зёрна и токены с 09:41"),
            ("🧠", "Режим большого мозга — двойной шот, ноль сна"),
            ("🐛", "Баги боятся запаха свежего кофе"),
            ("♾️", "while(не_спит) { claude() }"),
            ("🔌", "Подключён, настроен, клодит"),
            ("🥛", "Молоко на пару, CPU на пару — аккуратнее с обоими"),
            ("📦", "Шипим фичи, потягиваем латте"),
            ("🤖", "Агент не спит. Теперь и твой Mac тоже"),
            ("☁️", "Голова в облаке, зёрна на земле"),
            ("🎯", "Ещё один токен, ещё один глоток"),
            ("☕", "Компиляция кофеина…"),
            ("🔥", "Цикл кипит, и кофе тоже"),
            ("🫖", "Код настаивается, коммит за коммитом"),
            ("🏆", "Кофе — официальный спонсор твоей сессии"),
            ("💾", "Сохраняем состояние, смакуем вкус"),
            ("🐙", "Конфликты слияния боятся эспрессо"),
            ("🎩", "Абракадабра — твой Mac не спит"),
            ("🛰️", "Земля вызывает майора Обжарку"),
            ("🪫", "Низкий заряд — это стиль жизни, подключись"),
            ("🍩", "Пончики по желанию, аптайм обязателен"),
            ("🧊", "Холодная голова, тёплая кружка"),
            ("🥐", "Круассан загружен, контекст загружен"),
            ("💻", "Human.exe не отвечает — ставлю coffee.exe"),
            ("☠️", "Дай кофе — и никто не пострадает"),
            ("🦥", "Не ленюсь — я в режиме энергосбережения"),
            ("📡", "Токены стримятся, молоко парит"),
            ("🦉", "Режим совы: крышка вниз, зёрна вверх"),
            ("🎧", "Lo-fi бит, крепкие зёрна"),
            ("🚦", "Тесты зелёные, свет зелёный, поехали"),
            ("🧭", "Заблудился в коде? Иди на запах кофе"),
            ("🛠️", "Строим мечты, завариваем зёрна"),
            ("🐝", "Жужжим, мелем, кодим"),
            ("⌨️", "Самый дорогой кофе — тот, что на клавиатуре"),
            ("🧀", "Скажи «сыр», выкати релиз"),
            ("⛽", "Топливо: сарказм и эспрессо"),
            ("😩", "Депрессо — это когда кончился кофе"),
            ("🪐", "Зёрна сошлись, звёзды сошлись"),
            ("🧙", "Волшебник промптов за работой"),
            ("🔋", "Заряжен, но расслаблен"),
            ("🌞", "Кому нужен сон, когда зёрна свежие?"),
        ],
        heatToast: ("🔥", "Долгая заварка — ровно, в сети и никогда в сумке"),
        autoOffToast: { label in ("😴", "Заварка окончена через \(label) — остываем") },
        claudeOffToast: ("😴", "Сессии Claude завершены — заварка остановлена"),
        notifAsk: "С возвращением! 👋 Выключить заварку?",
        keep: "Оставить",
        off: "Выключить",
        notifDone: { v in "С возвращением! ☕ Заварка уже закончилась — всего \(v)" },
        ok: "OK",
        obTitle: "Перед первой\nсессией Clauffee ☕",
        obIntro: "Как ты используешь Claude?",
        ob1t: "Приложение Claude на iPhone",
        ob1s: "Установи приложение и разреши уведомления.",
        ob2t: "Один аккаунт везде",
        ob2s: "Войди с тем же аккаунтом claude.ai, что и в терминале.",
        ob3t: "Настройка Claude Code",
        ob3s: "Запусти /config и включи «Remote Control for all sessions», «Push when actions required» и «Push when Claude decides».\nБольше не нужно вводить /\u{2060}remote\u{2011}control в каждой сессии.",
        obNote: { label in "Каждая новая сессия стартует с лимитом блокировки \(label) — меняется в Настройках ⚙︎." },
        obConfirm: "Я включил Remote Control + оба push-уведомления",
        obAccountApi: "API-ключ (только Claude Code)",
        obAccountApiSub: "Remote Control недоступен — открой Mac, чтобы снова взять управление.",
        obAccountPro: "Аккаунт Pro, Max или Team",
        obAccountProSub: "Remote Control доступен — отвечай Claude с телефона, крышка закрыта.",
        obNotif: "Включить напоминание об остановке",
        obNotifSub: "Выбери стиль уведомлений «Постоянный», чтобы не забыть остановить сессию Clauffee при открытии Mac.",
        obNotifOn: "Напоминание включено ✓",
        obNotifDenied: "Заблокировано — открой Настройки > Уведомления > Clauffee > Стиль уведомлений: Постоянный",
        obNotifStylePersistent: "Постоянный",
        obNotifStyleTemporary: "Временный",
        obNotifStyleSilent: "Без звука",
        obNotifSettings: "Настройки",
        obNotifStyleLabel: "Уведомления: ",
        obWelcomeTitle: "Всё готово! ☕",
        obWelcomeBody: "Clauffee держит твои сессии Claude Code живыми, даже когда Mac спит или крышка закрыта.",
        obWelcomeReminderOn: " Когда снова откроешь компьютер, Clauffee предложит остановить сессию.",
        obWelcomeReminderOff: " Скоро смени стиль уведомлений на «Постоянные» в Настройках, чтобы Clauffee предлагал остановить сессию.",
        obWelcomeBtn: "Поехали!",
        obNext: "Далее",
        skip: "Напомнить позже",
        obBack: "Назад",
        obStyleWarnTitle: "Точно не хочешь менять стиль уведомлений?",
        obStyleWarnBody: "Уведомления-предупреждения позволяют остановить сессию при открытии Mac.",
        obStyleWarnConfirm: "Да, уверен",
        errTitle: "Нужно одноразовое разрешение",
        errBody: "Clauffee управляет сном через pmset — нужны права администратора. Вставь это один раз в Терминал и попробуй снова:",
        retry: "Повторить",
        copy: "Копировать",
        copied: "Скопировано ✓",
        back: "Назад",
        settingsTitle: "Настройки",
        appearance: "Оформление",
        language: "Язык",
        themeMilk: "Молоко",
        themeEsp: "Эспрессо",
        limitTitle: "Максимальное время заварки",
        heatCaution: "Риск перегрева — Mac ровно, в сети, на открытом воздухе. Никогда в сумке.",
        allUnlimited: "Вечная заварка",
        allUnlimitedSub: "Блокирует сон без ограничения по времени — компьютер никогда не уснёт",
        claudeStop: "Авто-стоп без сессий Claude",
        claudeStopSub: "Останавливает заварку, когда завершается последняя сессия Claude Code",
        funToasts: "Сообщение при запуске сессии",
        lidNotif: "Уведомление «С возвращением»",
        lidNotifSub: "Показывается при возвращении (открытие крышки, пробуждение или разблокировка) — напоминание остановить сессию. Отключает напоминание, а не системное разрешение.",
        launchLogin: "Держать Clauffee в строке меню",
        launchLoginSub: "Автоматически запускается при каждом входе",
        about: "Выход сохраняет настройки и всегда возвращает обычный сон"
    )
}

// MARK: - Format horloge (m:ss / h:mm:ss)

func formatClock(_ seconds: TimeInterval) -> String {
    let s = max(0, Int(seconds))
    let h = s / 3600
    let m = (s % 3600) / 60
    let ss = s % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, ss)
    }
    return String(format: "%d:%02d", m, ss)
}
