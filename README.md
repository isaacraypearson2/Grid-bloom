# Gridbloom

Casual block-puzzle with a soft garden / bloom look — Block Blast energy, celadon tiles, and petal accents.

Native **Swift + SpriteKit** core, **SwiftUI** menus and HUD. iPhone portrait, iOS 16+, no paid third-party SDKs.

## How to run

**Pull `main` before playing.** Recent builds include crash fixes (empty tray slots, and a watchdog hang when Classic / Today’s Bloom started). If Xcode still has an old checkout, `git pull origin main` then rebuild.

1. Clone this repo and open **`Gridbloom.xcodeproj`** in Xcode 15 or later.
2. Choose an **iPhone simulator** (iOS 16+).
3. Press **Run** (⌘R).

Display name is **Gridbloom**. Pick a Personal Team under *Signing & Capabilities* if Xcode asks.

Unit tests: **Product → Test** (⌘U).

## Try the polished slice

- First launch shows a **short, skippable onboarding**.
- **Play** is classic endless; **Today’s Bloom** is UTC-seeded (same trays for everyone that day) with a **played today / streak** chip.
- Pause from the HUD. Settings: mute SFX, haptics, color-distinct pieces, reduce motion (also honors the system setting).
- **Bloom revive** on game over is once per run and only after you tap it. **New tray** lives in pause — never an ad mid-drag.
- Shop (**Greenhouse**) sells three cosmetic packs. Garden Clay is free.

## StoreKit (local)

The Gridbloom scheme is pointed at `Gridbloom/Monetization/Products.storekit`.

If prices show as “…”:

1. Product → Scheme → Edit Scheme…
2. Run → Options → **StoreKit Configuration**
3. Choose **Products.storekit**

Then: Greenhouse → buy a pack (StoreKit test sheet) → **Use** / **On**. **Restore purchases** syncs entitlements.

Create the same product IDs in App Store Connect before a real App Store build:

- `com.gridbloom.cosmetics.sakura`
- `com.gridbloom.cosmetics.moonlight`
- `com.gridbloom.cosmetics.sunflower`

## Ads (stub only)

`AdServing` is the seam. `MockRewardedAdService` waits briefly and grants the reward so the continue / shuffle UX can be felt without AdMob.

To ship real rewarded ads later:

1. Add your ad SDK (e.g. AdMob) in a follow-up.
2. Implement `AdServing` with your ad unit IDs (keep IDs out of the mock).
3. Assign it: `AdHub.service = YourAdMobAdapter()`.

No interstitials mid-run. Continue is capped at **one revive per run**.

## Project layout

| Area | Role |
| --- | --- |
| `Game/Board.swift` | 8×8 occupancy, placement, line clears |
| `Game/Piece.swift` | Polyomino model |
| `Game/GameState.swift` | Score, combo, tray, continues |
| `Game/FairDealer.swift` | Occupancy weights + opening-game grace |
| `Scene/GameScene.swift` | Drag / snap, ceramic tiles, juice |
| `UI/` | Menu, HUD, pause, settings, shop, onboarding |
| `Monetization/` | StoreKit 2 shop, `AdServing`, `.storekit` file |
| `GridbloomTests/` | Clears, scoring, combos, daily deals, dealing, continue, cosmetics, layout, session-start stability |

## What’s left for the publisher

- App Store Connect: bundle ID, IAP products, screenshots, privacy nutrition labels.
- Optional AdMob (or other) adapter behind `AdServing`.
- A Developer Team for device/TestFlight signing.
