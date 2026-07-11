<p align="center">
  <img src="docs/banner.png" alt="Clauffee — keep your Mac awake for long Claude Code sessions" width="100%">
</p>

# Clauffee ☕

A tiny macOS **menu-bar app that keeps your Mac awake** — even with the lid
closed — so your long-running terminal sessions (e.g. Claude Code) keep going
while you step away. Toggle **Start Brew**, shut the lid, walk off.

- 🛡️ Blocks sleep via `pmset disablesleep` — works lid-closed
- ⏱️ Optional auto-off time limit (1–9 h) or **Eternal brew** (never sleep)
- 🔒 **Locks the screen** when you close the lid (stays awake, but secure)
- 🔔 "You're back" notification when you reopen the lid
- ☕ Animated cup, light/dark themes, EN / FR / RU
- 🪶 Lives in the menu bar (no Dock icon)

> Clauffee only **keeps the Mac awake**. Push notifications to your phone
> come from Claude Code's own Remote Control feature — see the in-app
> onboarding for the one-time `/config` setup.

## Download

Grab the latest **`Clauffee-<version>.zip`** from the
[**Releases**](https://github.com/axt3m/Clauffee/releases) page — no need to
build it yourself. Works on both Apple Silicon and Intel Macs.

1. Unzip and drag **Clauffee.app** into `/Applications`.
2. Because the app isn't notarized by Apple, macOS blocks it on first launch.
   **Right-click Clauffee.app → Open → Open** (you only do this once).
3. ☕ appears in your menu bar.

Then do the [one-time setup](#one-time-setup-on-first-brew) below.

## Requirements

- macOS 14 (Sonoma) or later — to run
- Xcode 16+ — only if you want to build it yourself

## Build & run

```sh
git clone https://github.com/axt3m/Clauffee.git
cd Clauffee
open Clauffee.xcodeproj
```

In Xcode:

1. Select the **Clauffee** target → **Signing & Capabilities** → choose **your
   own Team** (the project ships with no team set, so you must pick one — even
   "Sign to Run Locally" works for personal use).
2. Press **⌘R**.

## One-time setup (on first brew)

Clauffee toggles sleep with `pmset`, which needs admin rights. To avoid a
password prompt every time, it uses a passwordless `sudo` rule. The app shows
this command in-app on first launch — paste it once in Terminal:

```sh
echo '%admin ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0' | sudo tee /etc/sudoers.d/clauffee
```

Then click **Try again**. You'll also be asked to allow notifications on the
first brew.

## Releasing (maintainer)

The `.app` on the Releases page is built with an **ad-hoc signature** (no Apple
Developer account, hence the right-click-to-open step above).

Releases are published **by hand** so the title, notes, and asset stay under
your control. To cut one:

1. Build and package the app:

   ```sh
   ./scripts/build-release.sh   # produces dist/Clauffee-<version>.zip
   ```

2. On GitHub, **Draft a new release**, create the tag (e.g. `v1.0`), write the
   notes, and attach `dist/Clauffee-<version>.zip`.

The [`Release`](.github/workflows/release.yml) GitHub Action does **not** touch
Releases — it only builds/verifies the app on every `v*` tag (or manual
dispatch) and uploads the zip as a downloadable **workflow artifact**, so you
can grab a CI-built zip instead of building locally if you prefer.

> Want a friction-free install (plain double-click)? Join the Apple Developer
> Program, then sign with a **Developer ID** certificate and **notarize** the
> app. The Mac App Store isn't an option here — the app is unsandboxed and uses
> a private `login.framework` symbol.

## License

[MIT](LICENSE) © 2026 Angela Terao
