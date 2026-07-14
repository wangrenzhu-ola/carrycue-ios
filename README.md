# CarryCue

CarryCue is a native SwiftUI app for outpatient speech-language pathologists to turn one structured aphasia-session observation into an editable, clinician-approved caregiver practice card.

The app targets iOS 14 and Swift 5. It provides local JSON persistence, manual creation and recovery, optional consent-gated Kimi drafting, explicit approval, revision/deletion, accessible states, and a reachable privacy/safety screen. It does not collect audio or require patient identifiers.

## Build

```sh
xcodegen generate
xcodebuild -project CarryCue.xcodeproj -scheme CarryCue -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' build
swift test
```

For local cloud-draft validation, inject `KIMI_API_KEY` through an untracked build configuration. Never commit credentials. The complete manual workflow does not require a key or network.
