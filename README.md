# Twinkle Town

A SwiftUI and SpriteKit puzzle game for iPhone and iPad, with a Cloudflare Worker website.

## iOS app

1. Open `TwinkleTown.xcodeproj` in Xcode and resolve Swift packages.
2. Add your Firebase iOS configuration as `TwinkleTown/GoogleService-Info.plist` (excluded from Git).
3. Choose your signing team and run the `TwinkleTown` scheme on an iPhone or iPad simulator.

The app includes Diamond Match, Crystal Sorting, Diamond Memory, local progression, cosmetic rewards, a garden and fictional leaderboards. Successful launch routing decisions are saved locally. Firebase Messaging handles optional push registration.

## Website

See [website/README.md](website/README.md) for local development and Cloudflare deployment. Supply deployment secrets through the environment or Wrangler secrets, never through source files.

## App Store assets

`app-store-screenshots/` contains screenshots captured from the running app on iPhone and iPad. Additional iPhone screens are in `iphone/extras/`.

## Codemagic

The `twinkletown-release` workflow in `codemagic.yaml` builds a signed App Store IPA and uploads it to TestFlight without submitting for App Review. It obtains the next build number from App Store Connect using the numeric Apple app ID.

The app-scoped `twinkletown_release` secret group supplies `APP_STORE_CONNECT_PRIVATE_KEY`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_ISSUER_ID`, `CERTIFICATE_PRIVATE_KEY`, and `FIREBASE_CONFIG_BASE64`. Firebase configuration is restored before Xcode resolves/builds the app. Signing files are fetched or created for `com.twinkletown.sparklefriends` during the build.
