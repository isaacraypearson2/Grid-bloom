# Gridbloom polish pass

What shipped on top of Classic Garden, Greenhouse ad packs, Bloom revive, and New tray — no rewrite.

## Flower-forward core

Tiles are **flower species** (tulip, daisy, rose, lily, lavender, hydrangea, plus unlockable orchid, peony, lotus, cactus bloom, moonflower, cherry blossom). Color is still the ceramic fill.

- Classic Garden deals from the player’s unlocked album.
- **Today’s Bloom** always deals the six starters so UTC trays stay fair and deterministic.

## Map / garden skins

Existing ad packs still unlock with one rewarded ad (Sakura Grove, Night Garden, Golden Sunflower). New playfield skins:

| Skin | How to unlock |
| --- | --- |
| Meadow Clay | Free (was Garden Clay) |
| Glasshouse | Win **Pattern Bloom** (no ad) |
| Desert Bloom | Spend **40 petals** in Greenhouse |

Select any owned skin in **Greenhouse**. Classic play is never gated.

## Match VFX

Line clears now burst more petals, sparkles, a flash ring, board punch + shake, floating `+score`, and a Bloom combo banner (SpriteKit + SwiftUI). Reduce Motion still short-circuits the juice. SFX stay AVFoundation (`clear` / `combo` wavs). Haptics fire on place, miss, bloom, and goal complete.

## Progression loop

- **Petals** — 1 per cleared line, plus a small combo bonus. Fair sinks: Lotus (30) in the album, Desert Bloom (40) in the shop.
- **Daily goals** — three UTC-stable chores (lines / combo / score / petal catch). Auto-claim, once per goal.
- **Streak** — unchanged Today’s Bloom UTC streak.
- **Album** — collect species. Rank: Sprout → Gardener → Bloomkeeper → Master florist.
- Rewarded **Bloom revive**, **New tray**, and Greenhouse **Watch to unlock** are unchanged and still player-initiated.

## Mini-games

From the menu **Side gardens**:

1. **Petal Catch** — tap falling petals, catch 10 in 22s. First win unlocks **Orchid**.
2. **Pattern Bloom** — repeat the flashed flowers for 3 rounds. First win unlocks **Peony** and the **Glasshouse** map.

Repeats still pay a small petal bonus.

## UI polish

- First-run onboarding (4 short pages, skippable) plus in-game “Drag a flower…” hint.
- Settings: How to play, haptics, sound, color-distinct pieces, Reduce Motion.
- Menu shows petals, rank, daily goals, album, and side gardens.

## How to test in Xcode Simulator

1. Open `Gridbloom.xcodeproj` in Xcode 16+ (iOS 16+ iPhone simulator).
2. **Product → Test (⌘U)** — includes flower roster, daily goals, Pattern Bloom, Glasshouse / Desert Bloom unlocks. Ads still use `MockRewardedAdService`.
3. **Product → Run (⌘R)** on an iPhone simulator.
4. Skip or finish onboarding. **Play** Classic Garden: pieces should show flower glyphs; clearing a line should sparkle / punch / banner.
5. Menu → **Flower album** (book). Starters unlock as you place them. Buy Lotus if you have 30 petals (play a bit, or complete daily goals).
6. Menu → **Side gardens** → Petal Catch. Catch 10 petals; album should show Orchid. Pattern Bloom: watch, repeat; Glasshouse should appear in Greenhouse and become selectable.
7. Greenhouse: Meadow Clay is free. Glasshouse **Use** after Pattern Bloom. Desert Bloom **40 petals**. Sakura / Night / Sunflower still **Watch to unlock** (DEBUG `forceGoogleTestAds` if AdMob isn’t filling).
8. Pause → New tray and game over → Bloom revive still require a tap; no mid-drag ads.
9. Today’s Bloom should still deal the same tray for a UTC day (unit tests cover this).
10. Settings → Reduce Motion: clears should not shake / punch / spray petals.

AdMob / StoreKit paths were not removed. `Products.storekit` remains unused by the shop. Restore still imports leftover IAP entitlements.
