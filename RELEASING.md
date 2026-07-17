# Releasing Clauffee

How to publish a new version. Maintainer-only — users just download from the
[Releases](https://github.com/axt3m/Clauffee/releases) page.

## Signing

The `.app` is built with an **ad-hoc signature** — no Apple Developer account
needed. Because it isn't notarized, first launch requires right-click → Open
(documented in the README).

## Cutting a release

Releases are published **by hand**, so the title, notes, and asset stay under
your control.

1. Build and package the app:

   ```sh
   ./scripts/build-release.sh   # produces dist/Clauffee-<version>.{zip,dmg}
   ```

2. On GitHub, **Draft a new release**, create the tag (e.g. `v1.0`), write the
   notes, and attach both `dist/Clauffee-<version>.zip` and
   `dist/Clauffee-<version>.dmg`.

## CI

The [`Release`](.github/workflows/release.yml) GitHub Action does **not** touch
Releases. It only builds/verifies the app — on every pull request into `main`
(the required `build` status check) and on every `v*` tag or manual dispatch —
and uploads the zip as a downloadable **workflow artifact**. So you can grab a
CI-built zip instead of building locally if you prefer.

## Notarization (optional, future)

Want a friction-free install (plain double-click)? Join the Apple Developer
Program, then sign with a **Developer ID** certificate and **notarize** the
app. The Mac App Store isn't an option here — the app is unsandboxed and uses a
private `login.framework` symbol.
