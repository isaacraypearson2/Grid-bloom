# Gridbloom polish pass

What shipped on top of Classic Garden, Greenhouse ad packs, Bloom revive, and New tray — no rewrite.

## Flower-forward core

Tiles are **flower species** (tulip, daisy, rose, lily, lavender, hydrangea, plus unlockable orchid, peony, lotus, cactus bloom, moonflower, cherry blossom, and Ultra **Starfire / Night orchid / Sunburst**). Color is still the ceramic fill.

- Classic Garden deals from the player’s unlocked album, including harvested garden flowers.
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
- Rewarded **Bloom revive**, **New tray**, and Greenhouse **Watch to unlock** are unchanged and still player-initiated. Optional **Watch for fertilizer** uses the same rewarded unit, grants a charge you apply to a plant, and is never required to play Classic Garden.

## Garden growing loop

Menu → **My garden** (leaf). Six beds. New profiles start with tulip, daisy, and rose seeds.

- Plant a seed; it grows in real time (Common 1 min, Rare 3, Epic 8, Ultra 15).
- **Water / care** — each plant needs water on a fair timer (about half its grow time, minimum 45s). UI warns **Needs water** (yellow, with time until wilt), then **Wilting — water within …** (orange). Wilted plants pause growth. If still neglected they **die**, leave the bed empty, and have a ~22% chance to salvage a seed. Watering anytime while alive resets the care clock. Legacy plots (pre-watering save) keep remaining grow time and get a fresh water clock so they don’t instantly wilt.
- **Fertilizer (ads)** — watching a rewarded ad adds a **fertilizer charge** (cap 5). Apply it to a growing plant: **2× growth for 2 hours**, not an instant skip. Each plant can accept fertilizer **at most once every 24 hours**. Cooldown and boost end times persist on the plot in `PlayerProfile`.
- Harvest (when ready, even if thirsty/wilted) unlocks that species for Classic Garden tiles and pays a few petals.
- Unlocks persist on `PlayerProfile` (plots, seed inventory, unopened packs, fertilizer charges).

## Seed packs

Fair gacha: a pack of rarity **X only grants seeds of that tier**. Clear Common / Rare / Epic / Ultra colors when you open it.

| Pack | How to get | Contents |
| --- | --- | --- |
| Common | Petal Catch repeats, or 18 petals | 3 Common seeds |
| Rare | First Petal Catch, Pattern Bloom repeats, or 40 petals | 2 Rare seeds |
| Epic | First Pattern Bloom, or 70 petals | 1 Epic seed |
| Ultra | Winning **both** side gardens (once), or 120 petals | 1 Ultra seed |

## Ultra abilities

Starfire, Night orchid, and Sunburst are Ultra. Common–Epic are collection/score only. Matching a line whose **dominant** flower is Ultra **clears the rest of the board** (Classic only) with a GRID bloom. Today’s Bloom never deals Ultras and never wipes.

## Mini-games

From the menu **Side gardens**:

1. **Petal Catch** — tap falling petals, catch 10 in 22s. First win: **Orchid** + Rare pack. Repeats: Common pack.
2. **Pattern Bloom** — repeat the flashed flowers for 3 rounds. First win: **Peony**, **Glasshouse**, Epic pack. Repeats: Rare pack.

Winning both games once also grants a single **Ultra** pack. Repeats still pay a small petal bonus.

## UI polish

- First-run onboarding (6 short pages, skippable) plus in-game “Drag a flower…” hint.
- Settings: How to play, haptics, sound, color-distinct pieces, Reduce Motion.
- Menu shows petals, rank, daily goals, album, **My garden**, and side gardens.

## How to test in Xcode Simulator

1. Open `Gridbloom.xcodeproj` in Xcode 16+ (iOS 16+ iPhone simulator).
2. **Product → Test (⌘U)** — includes flower roster, garden watering/wilt/death, fertilizer 2×/24h cooldown, seed-pack rarity, Ultra grid wipe, daily goals, Pattern Bloom, Glasshouse / Desert Bloom unlocks. Ads still use `MockRewardedAdService`.
3. **Product → Run (⌘R)** on an iPhone simulator.
4. Skip or finish onboarding. **Play** Classic Garden: pieces should show flower glyphs; clearing a line should flash a **full-screen bloom of that flower type** (bigger with combo), then let you keep playing.
5. Menu camera or Album → **Scan**. Simulator: use Photo Library (camera is limited; grant Photos if the camera fallback asks). Pick any colorful image. Plant it; it should show in the album. Start Classic Garden — the opening tray can already show that stamp. Today’s Bloom should not deal scanned tiles. A dull/gray photo is named **Custom bloom**.
6. Menu → **Flower album** (book). Starters unlock as you place them. Buy Lotus if you have 30 petals (play a bit, or complete daily goals).
7. Menu → **Side gardens** → Petal Catch. Catch 10 petals; album should show Orchid and **My garden** should have a Rare pack. Pattern Bloom: watch, repeat; Glasshouse + Epic pack. Winning **both** should add one Ultra pack (once).
8. Greenhouse: Meadow Clay is free. Glasshouse **Use** after Pattern Bloom. Desert Bloom **40 petals**. Sakura / Night / Sunflower still **Watch to unlock** (DEBUG `forceGoogleTestAds` if AdMob isn’t filling).
9. Pause → New tray and game over → Bloom revive still require a tap; no mid-drag ads.
10. Today’s Bloom should still deal the same tray for a UTC day (unit tests cover this).
11. Settings → Reduce Motion: full-screen bloom is a brief tint; tiles should not shake / punch / spray petals.
12. **My garden**: plant a starter seed. **Water** when the bed turns yellow (“Needs water”) — don’t wait for orange wilt. Harvest when ready. Open a seed pack and confirm the rarity banner matches the pack tier.
13. Buy a Common pack for 18 petals (play a bit first). **Watch for fertilizer** (optional ad) → apply **Fertilize** on a growing plant: it should show 2× for 2 hours. A second fertilize on that plant should be blocked until 24h. Classic Garden must remain playable with an empty garden / no ads.
14. Leave a plant unwatered past the wilt warning — it should die, empty the bed, and sometimes return a salvaged seed. Open the Ultra pack (from both mini-games, or 120 petals). Plant, water, harvest Starfire (or Night orchid / Sunburst). In **Classic** only, complete a line that is mostly that Ultra flower — the rest of the board should wipe with a GRID bloom. Today’s Bloom should not deal Ultras or wipe.

AdMob / StoreKit paths were not removed. `Products.storekit` remains unused by the shop. Restore still imports leftover IAP entitlements.
