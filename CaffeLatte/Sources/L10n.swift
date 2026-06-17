//
//  L10n.swift
//  CaffeLatte
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
    let autoOffToast: (Int) -> (emoji: String, text: String)
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
    let obNote: (Int) -> String
    let obConfirm: String
    let obNotif: String
    let obNotifOn: String
    let obNotifDenied: String
    let brewBtn: String
    let skip: String

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
            n == 0 ? "No Claude Code sessions running"
                   : "\(n) Claude Code session\(n > 1 ? "s" : "") running"
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
        ],
        heatToast: ("🔥", "Long brew ahead — flat, plugged in, never in a bag"),
        autoOffToast: { h in ("😴", "Brew ended after \(h) h — staying cool") },
        claudeOffToast: ("😴", "No Claude sessions left — brew stopped"),
        notifAsk: "You're back! 👋 Turn off the brew?",
        keep: "Keep on",
        off: "Turn off",
        notifDone: { v in "You're back! ☕ The brew already ended — \(v) total" },
        ok: "OK",
        obTitle: "Before your first brew ☕",
        obIntro: "CaffeLatte keeps your Claude Code sessions alive with the lid closed. Three one-time checks:",
        ob1t: "Claude app on your iPhone",
        ob1s: "Installed, with notifications allowed.",
        ob2t: "Same account everywhere",
        ob2s: "Sign in with the same claude.ai account as your terminal.",
        ob3t: "Claude Code config",
        ob3s: "Run /config → set “Remote Control for all sessions” to true (not “default”) and turn on “Push when Claude decides”. Then new sessions need no /remote-control.",
        obNote: { h in "Every new session starts with a \(h) h block limit — adjustable in Settings ⚙︎. When you reopen the lid, CaffeLatte sums up or offers to stop." },
        obConfirm: "I set Remote Control for all sessions to “true”",
        obNotif: "Allow CaffeLatte notifications",
        obNotifOn: "Notifications allowed ✓",
        obNotifDenied: "Blocked — open System Settings",
        brewBtn: "Got it ✓",
        skip: "Remind me later",
        errTitle: "One-time permission needed",
        errBody: "CaffeLatte toggles sleep with pmset, which needs admin rights. Paste this once in Terminal, then try again:",
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
        lidNotifSub: "Shown when you reopen the lid — a reminder to stop blocking sleep",
        launchLogin: "Keep CaffeLatte in the menu bar",
        launchLoginSub: "Relaunches automatically each time you log in",
        about: "CaffeLatte v1.0 · Quitting saves your settings and always restores normal sleep"
    )
}

// MARK: - Français

extension Strings {
    static let fr = Strings(
        statusOff: "Aucune veille bloquée actuellement",
        statusOn: "Et que ça Claude ! ✨",
        brewTitle: "Lancer le café",
        brewingTitle: "Ça infuse…",
        unlimitedWord: "Illimité",
        brewSubOff: "Bloque la veille — même capot fermé",
        brewSubOn: "Veille bloquée — tu peux fermer le capot",
        awakeFmt: "En chauffe depuis %@",
        autoOffFmt: "Arrêt auto dans %@ — pour rester au frais",
        noLimit: "Pas d'arrêt auto — surveille la chauffe",
        sessions: { n in
            n == 0 ? "Aucune session Claude Code active"
                   : "\(n) session\(n > 1 ? "s" : "") Claude Code active\(n > 1 ? "s" : "")"
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
        ],
        heatToast: ("🔥", "Longue infusion — à plat, branché, jamais dans un sac"),
        autoOffToast: { h in ("😴", "Infusion terminée après \(h) h — on reste au frais") },
        claudeOffToast: ("😴", "Plus de session Claude — infusion arrêtée"),
        notifAsk: "Te revoilà ! 👋 On arrête l'infusion ?",
        keep: "Continuer",
        off: "Arrêter",
        notifDone: { v in "Te revoilà ! ☕ L'infusion s'est terminée toute seule — \(v) de brew" },
        ok: "OK",
        obTitle: "Avant ta première infusion ☕",
        obIntro: "CaffeLatte garde tes sessions Claude Code vivantes capot fermé. Trois vérifs — une seule fois :",
        ob1t: "L'app Claude sur ton iPhone",
        ob1s: "Installée, avec les notifications autorisées.",
        ob2t: "Le même compte partout",
        ob2s: "Connecte-toi avec le même compte claude.ai que dans ton terminal.",
        ob3t: "Config Claude Code",
        ob3s: "Lance /config → règle « Remote Control for all sessions » sur true (pas « default ») et active « Push when Claude decides ». Plus besoin de taper /remote-control.",
        obNote: { h in "Chaque nouvelle session démarre avec un temps limite de \(h) h de blocage — modifiable dans les Réglages ⚙︎. À la réouverture du capot, CaffeLatte te résume ou te propose d'arrêter." },
        obConfirm: "J'ai réglé « Remote Control for all sessions » sur « true »",
        obNotif: "Autoriser les notifications CaffeLatte",
        obNotifOn: "Notifications autorisées ✓",
        obNotifDenied: "Bloquées — ouvrir les Réglages Système",
        brewBtn: "C'est noté ✓",
        skip: "Me le rappeler plus tard",
        errTitle: "Autorisation unique requise",
        errBody: "CaffeLatte pilote la veille via pmset, qui demande les droits admin. Colle ça une fois dans le Terminal puis réessaie :",
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
        lidNotifSub: "Affichée à la réouverture du capot — un rappel pour arrêter le blocage de la mise en veille",
        launchLogin: "Garder CaffeLatte dans la barre des menus",
        launchLoginSub: "Se relance automatiquement à chaque ouverture de session",
        about: "CaffeLatte v1.0 · Quitter sauvegarde tes réglages et rétablit toujours la veille normale"
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
            if n == 0 { return "Нет активных сессий Claude Code" }
            if n == 1 { return "1 сессия Claude Code активна" }
            if n < 5 { return "\(n) сессии Claude Code активны" }
            return "\(n) сессий Claude Code активно"
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
        ],
        heatToast: ("🔥", "Долгая заварка — ровно, в сети и никогда в сумке"),
        autoOffToast: { h in ("😴", "Заварка окончена через \(h) ч — остываем") },
        claudeOffToast: ("😴", "Сессии Claude завершены — заварка остановлена"),
        notifAsk: "С возвращением! 👋 Выключить заварку?",
        keep: "Оставить",
        off: "Выключить",
        notifDone: { v in "С возвращением! ☕ Заварка уже закончилась — всего \(v)" },
        ok: "OK",
        obTitle: "Перед первой заваркой ☕",
        obIntro: "CaffeLatte держит твои сессии Claude Code живыми при закрытой крышке. Три проверки — один раз:",
        ob1t: "Приложение Claude на iPhone",
        ob1s: "Установлено, уведомления разрешены.",
        ob2t: "Один аккаунт везде",
        ob2s: "Войди с тем же аккаунтом claude.ai, что и в терминале.",
        ob3t: "Настройка Claude Code",
        ob3s: "Запусти /config → задай «Remote Control for all sessions» = true (не «default») и включи «Push when Claude decides». Тогда новым сессиям не нужен /remote-control.",
        obNote: { h in "Каждая новая сессия стартует с лимитом блокировки \(h) ч — меняется в Настройках ⚙︎. Когда откроешь крышку, CaffeLatte подведёт итог или предложит остановить." },
        obConfirm: "Я задал «Remote Control for all sessions» = «true»",
        obNotif: "Разрешить уведомления CaffeLatte",
        obNotifOn: "Уведомления разрешены ✓",
        obNotifDenied: "Заблокировано — открыть Настройки",
        brewBtn: "Понятно ✓",
        skip: "Напомнить позже",
        errTitle: "Нужно одноразовое разрешение",
        errBody: "CaffeLatte управляет сном через pmset — нужны права администратора. Вставь это один раз в Терминал и попробуй снова:",
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
        lidNotifSub: "Показывается при открытии крышки — напомнит снять блокировку сна",
        launchLogin: "Держать CaffeLatte в строке меню",
        launchLoginSub: "Автоматически запускается при каждом входе",
        about: "CaffeLatte v1.0 · Выход сохраняет настройки и всегда возвращает обычный сон"
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
