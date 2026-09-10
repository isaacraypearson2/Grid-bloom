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

Line clears bloom **that flower type across the screen** — a short full-screen petal overlay of the dominant species (or your scanned photo stamp), scaled by combo. Board tiles still sparkle, punch, and float `+score`. The overlay does not steal touches and fades in well under a second so you can keep placing. Reduce Motion is a brief tint only.

## Scan a real flower

Album → **Scan**, or the camera button on the menu.

- Camera or Photo Library. Permission strings: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` in `Info.plist`.
- Classification is **heuristic-first and fully on-device**. A color+shape pass always names the bloom (Blush bloom, Golden bloom, Custom bloom, …). Vision’s built-in `VNClassifyImageRequest` upgrades that name when it recognizes a known species (tulip, rose, orchid, …). There is no cloud plant API.
- The JPEG stamp is stored under Application Support on the phone. Photos never leave the device.
- The circular/petal stamp becomes a playable Classic Garden tile (not Today’s Bloom, so UTC deals stay fair). Cap 12 scanned blooms; the 13th replaces the oldest.
- Classic’s opening tray is dealt before the profile attaches; scanned stamps are overlaid in place (no extra RNG) so they can show immediately.

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

- First-run onboarding (5 short pages, skippable) plus in-game “Drag a flower…” hint.
- Settings: How to play, haptics, sound, color-distinct pieces, Reduce Motion.
- Menu shows petals, rank, daily goals, album, and side gardens.

## How to test in Xcode Simulator

1. Open `Gridbloom.xcodeproj` in Xcode 16+ (iOS 16+ iPhone simulator).
2. **Product → Test (⌘U)** — includes flower roster, daily goals, Pattern Bloom, Glasshouse / Desert Bloom unlocks. Ads still use `MockRewardedAdService`.
3. **Product → Run (⌘R)** on an iPhone simulator.
4. Skip or finish onboarding. **Play** Classic Garden: pieces should show flower glyphs; clearing a line should flash a **full-screen bloom of that flower type** (bigger with combo), then let you keep playing.
5. Menu camera or Album → **Scan**. Simulator: use Photo Library (camera is limited; grant Photos if the camera fallback asks). Pick any colorful image. Plant it; it should show in the album. Start Classic Garden — the opening tray can already show that stamp. Today’s Bloom should not deal scanned tiles. A dull/gray photo is named **Custom bloom**.
6. Menu → **Flower album** (book). Starters unlock as you place them. Buy Lotus if you have 30 petals (play a bit, or complete daily goals).
7. Menu → **Side gardens** → Petal Catch. Catch 10 petals; album should show Orchid. Pattern Bloom: watch, repeat; Glasshouse should appear in Greenhouse and become selectable.
8. Greenhouse: Meadow Clay is free. Glasshouse **Use** after Pattern Bloom. Desert Bloom **40 petals**. Sakura / Night / Sunflower still **Watch to unlock** (DEBUG `forceGoogleTestAds` if AdMob isn’t filling).
9. Pause → New tray and game over → Bloom revive still require a tap; no mid-drag ads.
10. Today’s Bloom should still deal the same tray for a UTC day (unit tests cover this).
11. Settings → Reduce Motion: full-screen bloom is a brief tint; tiles should not shake / punch / spray petals.

AdMob / StoreKit paths were not removed. `Products.storekit` remains unused by the shop. Restore still imports leftover IAP entitlements.
