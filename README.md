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
