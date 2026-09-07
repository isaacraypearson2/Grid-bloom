# Gridbloom

Casual block-puzzle with a soft garden / bloom look — Block Blast energy, pastel greens, and petal accents.

Native **Swift + SpriteKit** core, **SwiftUI** menus and HUD. iPhone portrait, iOS 16+, no third-party SDKs.

## How to run

1. Clone this repo and open **`Gridbloom.xcodeproj`** in Xcode 15 or later.
2. Choose an **iPhone simulator** (iOS 16+), for example iPhone 16.
3. Press **Run** (⌘R).

The display name is **Gridbloom**. Select a Personal Team under *Signing & Capabilities* if Xcode asks you to sign the app.

To run unit tests: **Product → Test** (⌘U).

## Play

- **Play** — classic endless mode.
- **Today’s Bloom** — the same three-piece trays for everyone, seeded from the UTC date.
- Drag polyominoes from the tray onto the 8×8 board (pieces do not rotate).
- A **green** ghost means the drop is valid; **red** means it will shake back to the tray.
- Completed **rows and columns** clear together. Chain clears for a **Bloom xN** combo.
- Game over when none of the remaining tray pieces fit. Restart, or use the continue / shuffle hooks.

## Project layout

| Area | Role |
| --- | --- |
| `Gridbloom/Game/Board.swift` | 8×8 occupancy, placement, line clears |
| `Gridbloom/Game/Piece.swift` | Polyomino model |
| `Gridbloom/Game/GameState.swift` | Score, combo, tray, daily/classic rules |
| `Gridbloom/Scene/GameScene.swift` | Drag / snap, ghosts, juice |
| `Gridbloom/UI/` | Main menu, HUD, game-over |
| `Gridbloom/Monetization/MonetizationHooks.swift` | Rewarded continue / shuffle stubs, StoreKit 2 cosmetic IDs |
| `GridbloomTests/` | Board clears, scoring, combos, daily determinism |

Fair dealing down-weights bulky pieces as the board fills, and regenerates a tray until something still fits when that is possible.

## Monetization (hooks only)

`MonetizationHooks.swift` is the only ads/IAP surface:

- Rewarded **continue** (clears a few cells and refills the tray)
- Rewarded **tray shuffle**
- StoreKit 2 cosmetic product ID placeholders (`com.gridbloom.cosmetics.*`)

No live ad network or App Store products are connected yet. The development flag `grantsRewardsWithoutAds` lets those buttons grant the reward locally so you can try the flows.
