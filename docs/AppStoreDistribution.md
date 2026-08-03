# KuaiClip distribution channels

KuaiClip uses one public source tree and two independently signed distribution
channels. The application code is shared; signing identities, App Store Connect
credentials, StoreKit test configuration, archives, and packaged applications
are never committed.

## Direct / GitHub

- Bundle identifier: `com.kuaiclip.clipboard`
- Entitlements: `Config/Direct.entitlements`
- Distribution: Developer ID signed and notarized GitHub Release
- Packaging: `scripts/package.sh`
- App Sandbox: disabled

`scripts/package.sh` intentionally packages only the Direct channel. It must not
be used to create or upload a Mac App Store build.

## Mac App Store

- Bundle identifier: `com.kuaiclip.clipboard.appstore`
- Entitlements: `Config/AppStore.entitlements`
- Distribution: Xcode Archive uploaded to App Store Connect
- App Sandbox: enabled
- Compilation condition: `APP_STORE`

Open `KuaiClip.xcodeproj` and select the shared `KuaiClip-AppStore` scheme.
The target uses the same `Sources/KuaiClip` directory as Swift Package Manager,
so Direct and App Store builds do not maintain duplicate source files.

Create `Config/AppStore.local.xcconfig` locally and set the Apple developer team
and the lifetime product identifier there:

```xcconfig
DEVELOPMENT_TEAM = YOUR_TEAM_ID
KUAICLIP_LIFETIME_PRODUCT_ID = YOUR_LIFETIME_PRODUCT_ID
```

The repository ignores this file. Create one matching non-consumable lifetime
product in App Store Connect and set its intended paid price. The seven-day
trial starts locally when the user chooses the trial button; it is not a second
In-App Purchase product.

For local purchase testing, create a StoreKit Configuration file in Xcode with
a `.storekit` suffix, reproduce the lifetime product, and select it under
Scheme > Run > Options > StoreKit Configuration. StoreKit configuration files
are ignored and must not be committed.

The App Store build must be archived by a shared Xcode scheme. Do not publish
the resulting `.app`, `.pkg`, `.xcarchive`, or dSYM in a GitHub Release.

## Files that must remain private

- Apple Distribution and Developer ID certificate exports (`.p12`)
- App Store Connect API private keys (`.p8`)
- provisioning profiles
- StoreKit local test configurations (`.storekit`)
- local signing/account xcconfig files (`*.local.xcconfig`)
- app-specific passwords and CI environment files
- archives, packages, apps, and debug symbols

CI credentials belong in the CI provider's encrypted secret store. Run
`bash scripts/check-release-safety.sh` before staging or publishing a release.

## Direct paste in the App Store build

Direct paste remains a shared feature. Posting Command-V uses the macOS
PostEvent TCC privilege, checked with `CGPreflightPostEventAccess()` and
requested with `CGRequestPostEventAccess()`. This privilege is distinct from
full Accessibility API access. If permission is declined, KuaiClip still puts
the selected item on the pasteboard so the user can paste manually.

## Purchase behavior

- Direct builds always have full access and never load StoreKit products.
- App Store builds read only verified StoreKit 2 transactions.
- Starting the trial records its start date locally and grants seven days of
  premium access without initiating a purchase.
- The lifetime non-consumable unlocks permanently unless Apple revokes it.
- Restoring calls `AppStore.sync()` and then re-evaluates current entitlements.
- Screenshot capture and AI polish/translation require an active trial or the
  lifetime purchase. Clipboard history, copying, data deletion, and direct
  paste remain available after the trial so users retain access to their data.
