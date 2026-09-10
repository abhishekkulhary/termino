# Releasing

What a release needs, and what it needs from you. Everything in this repository
is set up; the parts that require an account, a certificate or a private key
are listed here because they cannot be committed.

## Versioning

`pubspec.yaml` holds `version: major.minor.patch+build`. The build number must
increase with every submission to the App Store and Google Play — they reject a
build number they have seen before, and it is the most common reason a first
upload fails.

```bash
# Bump both, then tag.
sed -i '' 's/^version: .*/version: 1.0.1+2/' pubspec.yaml
git commit -am "chore: release 1.0.1" && git tag v1.0.1 && git push --tags
```

Pushing a `v*` tag runs the release workflow, which builds every platform and
attaches the artifacts to a GitHub release.

## Icons and splash

Both are generated, not hand-drawn:

```bash
flutter test test/tools/generate_icon_test.dart --update-goldens
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

The first command renders `assets/icon/*.png` using Flutter itself, because
this project has no ImageMagick or librsvg to rely on and an icon nobody can
regenerate is an icon nobody can change.

## What you must supply

| Platform | What is needed | Where it goes |
|---|---|---|
| Android | An upload keystore | `android/key.properties` (see `key.properties.example`); in CI, the secrets below |
| iOS | An Apple Developer account, a distribution certificate and a provisioning profile | Xcode signing, plus an App Store Connect API key for CI |
| macOS | A Developer ID certificate for direct distribution, or App Store signing | Xcode signing; notarisation needs an API key |
| Windows | A code signing certificate (optional; unsigned installs show a SmartScreen warning) | `msix_config` in `pubspec.yaml` |
| Linux | Nothing | — |
| Web | A host, and a relay if SSH is wanted | See `tools/relay/README.md` |

**The Android keystore cannot be replaced.** Losing it means losing the ability
to update the app on Google Play, permanently. Back it up somewhere you would
trust with a password manager.

### CI secrets

The release workflow builds unsigned artifacts without any of these, and signs
or uploads only what it has the secrets for. Nothing fails merely because a
secret is absent — that is deliberate, so a fork can build the project.

| Secret | Used for |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | The keystore, base64-encoded |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | Signing |
| `PLAY_SERVICE_ACCOUNT_JSON` | Uploading to the Play internal track |
| `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_PRIVATE_KEY` | TestFlight and notarisation |
| `MACOS_CERTIFICATE_BASE64`, `MACOS_CERTIFICATE_PASSWORD` | macOS signing |

## macOS: two builds, deliberately

The default macOS build has the **App Sandbox off**, because a sandboxed
process cannot run the user's own programs or read their files — which is the
whole point of a terminal. That build is for direct distribution as a DMG.

A Mac App Store build would need the sandbox on and the local shell feature-
gated off, leaving SSH only. `PlatformCapabilities` is already the mechanism
for that; the build flavour is not set up, because whether to ship a
deliberately reduced App Store build is a product decision rather than an
engineering one.

## Checklist

- [ ] `flutter analyze --fatal-infos --fatal-warnings` and `flutter test` pass
- [ ] `cd tools/relay && dart test` passes
- [ ] Integration tests pass on a desktop: `for f in integration_test/*_test.dart; do flutter test "$f" -d macos; done`
- [ ] `./tool/sync_site_images.sh && ./tool/check_site.sh` pass
- [ ] The Pages deploy is green and the site loads
- [ ] `CHANGELOG.md` has an entry for this version
- [ ] Version and build number bumped
- [ ] Tag pushed

A tag now **publishes** the release rather than drafting it, so pushing one is a
public act with no review step in between. The website's download buttons
resolve through `releases/latest`, and the asset names below are the contract
they depend on — `tool/check_site.sh` fails if the site and the workflow ever
name different files:

```
Termino-macos.dmg              Termino-windows-x64.zip
Termino-windows-x64.msix       Termino-linux-x86_64.AppImage
Termino-android-universal.apk  Termino-android.aab
Termino-ios-unsigned.zip       Termino-web.tar.gz
```

There is no version in a filename on purpose: the tag carries the version, so
`releases/latest/download/Termino-macos.dmg` stays a permanent link.

After the first published release, open the site and confirm each of the four
download cards shows a version and a size. A card still reading "See all
downloads" means the name it asks for and the name the workflow produced have
diverged — check the release's asset list before the script.
