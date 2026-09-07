# Gridbloom

Casual block-puzzle with a soft garden / bloom look — Block Blast energy, celadon tiles, and petal accents.

Native **Swift + SpriteKit** core, **SwiftUI** menus and HUD. iPhone portrait, iOS 16+. Greenhouse uses **StoreKit 2**. Bloom revive and New tray use **Google Mobile Ads** rewarded ads (test units by default).

## How to run

**Pull `main` before playing.**

1. Clone this repo and open **`Gridbloom.xcodeproj`** in Xcode 16 or later (Xcode 15.3+ can work; Google’s current Mobile Ads package prefers Xcode 16).
2. Let Swift Package Manager resolve **GoogleMobileAds** on first open.
3. Choose an **iPhone simulator** (iOS 16+).
4. Press **Run** (⌘R).

Display name is **Gridbloom**. Pick a Personal Team under *Signing & Capabilities* if Xcode asks.

Unit tests: **Product → Test** (⌘U). Tests use `MockRewardedAdService` and never need a live ad.

## Try the slice

- First launch shows a **short, skippable onboarding**.
- **Play** is classic endless; **Today’s Bloom** is UTC-seeded with a streak chip.
- Pause from the HUD. **Bloom revive** on game over is once per run and only after you tap it. **New tray** lives in pause — never an ad mid-drag.
- Shop (**Greenhouse**) sells three cosmetic packs. Garden Clay is free. Paid packs show StoreKit prices ($0.99 / $1.99 / $2.99 in the local StoreKit config).

## Greenhouse / StoreKit 2

The shared Gridbloom scheme already points at `Gridbloom/Monetization/Products.storekit` for Run, Test, and Profile.

Local prices:

| Product ID | Pack | StoreKit display price |
| --- | --- | --- |
| `com.gridbloom.cosmetics.sakura` | Sakura Petals | $0.99 |
| `com.gridbloom.cosmetics.moonlight` | Moonlight Garden | $1.99 |
| `com.gridbloom.cosmetics.sunflower` | Golden Sunflower | $2.99 |

If a pack shows **Unavailable** instead of a price:

1. Product → Scheme → Edit Scheme…
2. Run → Options → **StoreKit Configuration**
3. Choose **Products.storekit**
4. Greenhouse → **Try again**

Then buy a pack (StoreKit test sheet) → **Use** / **On**. **Restore purchases** syncs entitlements.

The shop loads `Product.products(for:)` at launch and again when Greenhouse opens. It never treats a missing product as a successful purchase.

### App Store Connect checklist (human)

Code is StoreKit 2 production-ready. Apple still needs the IAPs created in App Store Connect before TestFlight / App Store:

1. App Store Connect → your app (bundle ID `com.gridbloom.app`) → **Monetization** → **In-App Purchases**.
2. Create three **Non-Consumable** products with **exactly** these IDs:
   - `com.gridbloom.cosmetics.sakura` — Sakura Petals — $0.99 (or your storefront price).
   - `com.gridbloom.cosmetics.moonlight` — Moonlight Garden — $1.99.
   - `com.gridbloom.cosmetics.sunflower` — Golden Sunflower — $2.99.
3. Add localized display name + description, a review screenshot, and clear **Ready to Submit**.
4. Paid Apps / banking / tax agreements must be active or StoreKit returns empty product lists on device.
5. For local Simulator work, **keep** Products.storekit attached. For TestFlight, Xcode uses App Store Connect products (turn off the StoreKit config on that scheme, or use a separate scheme).
6. Submit the IAP with the binary. Same product IDs as `MonetizationHooks.Cosmetics`.

## Rewarded ads (AdMob)

Revive and tray shuffle call `AdMobRewardedAdService` through `AdHub.service`. Ads are **player-initiated only**. No interstitials. Continue is capped at **one revive per run**. If an ad fails to load or show, the reward is **not** granted.

### Test ads (default — works in Simulator now)

The repo ships Google’s official sample IDs:

- App ID: `ca-app-pub-3940256099942544~1458002511` (`GADApplicationIdentifier` in `Gridbloom/Info.plist`)
- Rewarded unit: `ca-app-pub-3940256099942544/1712485313` (`AdConfig.swift`)

On first Play → game over → **Bloom revive**, you should get a Google **test** rewarded ad. Same for Pause → **New tray**.

`MockRewardedAdService` remains for unit tests. Do not point `AdHub.service` at the mock in the app target.

### Swap in real AdMob IDs later (human)

1. [AdMob](https://apps.admob.com) → Apps → **Add app** (iOS, bundle `com.gridbloom.app`). Copy the **App ID** (`ca-app-pub-…~…`).
2. Create a **Rewarded** ad unit. Copy the **Ad unit ID** (`ca-app-pub-…/…`).
3. In `Gridbloom/Monetization/AdConfig.swift`, paste them into:
   - `productionApplicationID`
   - `productionRewardedUnitID`
4. In `Gridbloom/Info.plist`, set `GADApplicationIdentifier` to the **same** production App ID. The SDK reads App ID from Info.plist at launch; unit IDs come from `AdConfig`.
5. Never ship the sample IDs in a store build — Google can suspend the account.
6. Add the AdMob iOS app to the same Firebase/AdMob property if you use mediation later. Not required for this rewarded-only path.

`SKAdNetworkItems` in Info.plist already includes Google’s published buyer list from the [Mobile Ads iOS quick start](https://developers.google.com/admob/ios/quick-start).

## Project layout

| Area | Role |
| --- | --- |
| `Game/Board.swift` | 8×8 occupancy, placement, line clears |
| `Game/Piece.swift` | Polyomino model |
| `Game/GameState.swift` | Score, combo, tray, continues |
| `Game/FairDealer.swift` | Occupancy weights + opening-game grace |
| `Scene/GameScene.swift` | Drag / snap, ceramic tiles, juice |
| `UI/` | Menu, HUD, pause, settings, shop, onboarding |
| `Monetization/` | StoreKit 2 shop, AdMob rewarded, `.storekit` file |
| `Info.plist` | `GADApplicationIdentifier` + SKAdNetwork |
| `GridbloomTests/` | Clears, scoring, combos, daily deals, dealing, continue, cosmetics, ads config |

## What’s left for the publisher (cannot be done in git)

- Apple Developer team, bundle ID, signing, screenshots, privacy nutrition labels.
- App Store Connect IAP creation (checklist above).
- AdMob app + rewarded unit creation, then paste IDs into `AdConfig` + Info.plist.
- Optional App Tracking Transparency prompt (not shown; ads still run as limited ads).
