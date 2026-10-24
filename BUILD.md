# BUILD.md — building 56sim and the sideload IPA

## Prerequisites

- Xcode 27.2 (27B5028f) or newer, on macOS.
- First build downloads the Swift Package Manager dependencies: `mlx-swift-lm` 3.32.3, `swift-huggingface` 0.9.0, `swift-transformers` 1.3.0, `SQLite.swift` 0.16.0, `piper1-gpl-spm`, `espeak-ng-spm`. (`piper-objc` is vendored in `Vendor/piper-objc/`.)
- Note: the project is the JSON `56sim.xcodeproj/project.xcproj` format — opening it in older Xcode won't work.

## The -skipMacroValidation rule

Every `xcodebuild` invocation in this repo needs `-skipMacroValidation`. Without it, the `MLXHuggingFaceMacros` build plugin trips macro validation and the build halts. There are no exceptions to this rule.

## Test

```
xcodebuild -skipMacroValidation -project 56sim.xcodeproj -scheme 56sim \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

Expect `** TEST SUCCEEDED **` (91 tests / 8 suites).

## Unsigned release archive

```
xcodebuild -skipMacroValidation -project 56sim.xcodeproj -scheme 56sim \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/56sim.xcarchive \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" archive
```

Expect `** ARCHIVE SUCCEEDED **`. MLX frameworks make this build slow and the result large — that is normal, not an error.

## Package the IPA (this is what an unsigned IPA is)

An unsigned IPA is the unsigned `.app` from the archive dropped into `Payload/` and zipped:

```
rm -rf build/ipa && mkdir -p build/ipa/Payload
cp -R build/56sim.xcarchive/Products/Applications/56sim.app build/ipa/Payload/
(cd build/ipa && zip -qry 56sim.ipa Payload)
```

→ `build/ipa/56sim.ipa`. Do NOT use `xcodebuild -exportArchive` — unsigned iOS export is not supported there.

## Verify

```
unzip -l build/ipa/56sim.ipa | grep -E "Payload/56sim.app/(56sim$|Info.plist)"
plutil -p build/ipa/Payload/56sim.app/Info.plist | grep -E "CFBundleShortVersionString|CFBundleVersion|CFBundleIdentifier"
codesign -dv build/ipa/Payload/56sim.app
```

Expected: `Payload/56sim.app/56sim` present; `1956.10.23`, `1`, `hu.9frontin.-6sim`; codesign reports **not signed**.

## Sideload it

[AltStore Classic](https://altstore.io) (AltServer on the same Wi-Fi, signs locally with your Apple ID) or Sideloadly — both accept the unsigned IPA and re-sign everything including embedded frameworks; free accounts must refresh every 7 days. TrollStore (iOS versions it supports) installs the unsigned IPA permanently with no signing. Note: embedded `Frameworks/` (MLX, espeak/piper data bundles) are stripped of signature by design — the sideloading tool re-signs them.

## Device coverage & runtime dependencies

The release archive is a device build for `generic/platform=iOS` (arm64 only — every iPhone iOS 27 runs on is arm64); `MinimumOSVersion 27.0` makes it installable on exactly the devices the minimum deployment allows.

The interrogation model (`LiquidAI/LFM2.5-1.2B-Instruct-MLX-4bit`, fallback `mlx-community/LFM2-1.2B-4bit`, `InterrogationEngine.modelID`) and the Radio Moscow voice (`en_US-reza_ibrahim-medium` from `rhasspy/piper-voices`, `PiperAnnouncer.voiceBase`) are fetched from huggingface.co on first use and cached in Application Support — network needed once per install, offline afterwards. `espeak-ng-data` (TTS phonemisation) and MLX's Metal kernels ship inside the IPA itself.

On the simulator MLX is deliberately blocked by the app itself (interference banner, opt-in env `56SIM_ALLOW_SIMULATOR_LLM=YES`) — device-only behaviour by design.
