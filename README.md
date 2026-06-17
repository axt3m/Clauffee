# CaffeLatte ☕

A tiny macOS **menu-bar app that keeps your Mac awake** — even with the lid
closed — so your long-running terminal sessions (e.g. Claude Code) keep going
while you step away. Toggle **Start Brew**, shut the lid, walk off.

- 🛡️ Blocks sleep via `pmset disablesleep` — works lid-closed
- ⏱️ Optional auto-off time limit (1–9 h) or **Eternal brew** (never sleep)
- 🔒 **Locks the screen** when you close the lid (stays awake, but secure)
- 🔔 "You're back" notification when you reopen the lid
- ☕ Animated cup, light/dark themes, EN / FR / RU
- 🪶 Lives in the menu bar (no Dock icon)

> CaffeLatte only **keeps the Mac awake**. Push notifications to your phone
> come from Claude Code's own Remote Control feature — see the in-app
> onboarding for the one-time `/config` setup.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16+ (to build it yourself)

## Build & run

```sh
git clone <repo-url>
cd CaffeLatte
open CaffeLatte.xcodeproj
```

In Xcode:

1. Select the **CaffeLatte** target → **Signing & Capabilities** → choose **your
   own Team** (the project ships with no team set, so you must pick one — even
   "Sign to Run Locally" works for personal use).
2. Press **⌘R**.

## One-time setup (on first brew)

CaffeLatte toggles sleep with `pmset`, which needs admin rights. To avoid a
password prompt every time, it uses a passwordless `sudo` rule. The app shows
this command in-app on first launch — paste it once in Terminal:

```sh
echo '%admin ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0' | sudo tee /etc/sudoers.d/caffelatte
```

Then click **Try again**. You'll also be asked to allow notifications on the
first brew.

## Notes for contributors

- **App Sandbox is disabled** (`ENABLE_APP_SANDBOX = NO`) — required because the
  app shells out to `pmset`/`pgrep` (`Process`) and reads the lid state via
  IOKit. Sandboxing would block these.
- **Screen lock** uses a private `login.framework` symbol
  (`SACLockScreenImmediate`) with a `pmset displaysleepnow` fallback — see
  `Sources/Core/ScreenLocker.swift`.
- Source is organized under `CaffeLatte/Sources/` (`Core/`, `UI/`, plus
  `AppState`, `L10n`, `Theme`). Localization is a hand-rolled struct in
  `L10n.swift` so language switches instantly without relaunch.

## License

[MIT](LICENSE) © 2026 Angela Terao
