# Gridbloom polish pass

What shipped on top of Classic Garden, Greenhouse ad packs, Bloom revive, and New tray — no rewrite.

## Flower-forward core

Tiles are **bloom variants**: species × color × rarity. The catalog lives in `BloomCatalog.swift` — add a species by appending an enum case and one `SpeciesProfile` (colors, signature tint, stage title/theme, unlock). Glyph art stays per species; color is a tint lane.

Each species has **three color variants** (e.g. red / white / yellow rose) and each of those has a rarity ladder **Common → Rare → Epic → Ultra** (12 collectibles per species). Ultra variants still grant the board wipe.

- **Classic Garden** deals mixed unlocked variants (signature of every unlocked species, plus colors/rarities you’ve collected or harvested).
- **Today’s Bloom** always deals the six starter **signature Commons** so UTC trays stay fair and deterministic (no extra RNG, no scanned stamps, no Ultras).
- **Flower maps** (menu) are unlockable stages themed by plant family. Each uses that family’s tiles and a matching backdrop (Tulip Walk, Rose Garden, Succulent Dunes, …). Classic Garden remains the mixed meadow.

## Map / garden skins

Existing ad packs still unlock with one rewarded ad (Sakura Grove, Night Garden, Golden Sunflower). New playfield skins:

| Skin | How to unlock |
| --- | --- |
| Meadow Clay | Free (was Garden Clay) |
| Glasshouse | Win **Pattern Bloom** (no ad) |
| Desert Bloom | Spend **40 petals** in Greenhouse |

Select any owned skin in **Greenhouse**. Classic play is never gated.

## Match VFX

Line clears bloom **the matched species across the whole phone** — HUD included. A SwiftUI wash + ~280pt glyph (or scanned stamp) sits above SpriteView, plus a SpriteKit overlay whose hero is **82–94%** of the shorter scene edge. Combo scales size and wash. Board tiles still sparkle, punch, and float `+score`. Neither overlay steals touches; Reduce Motion is a brief tint only (~0.35s).

Tiles themselves show a **large cream flower glyph** (about 86% of the block) with a dark ink stroke and gold center, so matching reads as flower type + color — not a blank pastel square.

Opening or first-collecting an **Ultra** seed/variant plays the same full-screen bloom (combo-5 juice) over the current screen — garden pack reveal, harvest, or album collect.

## Scan a real flower

Home **Scan Flower**, or Album → **Scan**. Close returns to the menu.

- **Camera only.** Photo Library / upload was removed. `NSPhotoLibraryUsageDescription` is gone from `Info.plist` and the target build settings. Permission string: `NSCameraUsageDescription`.
- The Simulator has no camera — Scan shows “Camera is required…” instead of falling back to Photos. Test scan on a device.
- Classification is **heuristic-first and fully on-device**. A color+shape pass always names the bloom (Blush bloom, Golden bloom, Custom bloom, …). Vision’s built-in `VNClassifyImageRequest` upgrades that name when it recognizes a known species (tulip, rose, orchid, …). There is no cloud plant API.
- The JPEG stamp is stored under Application Support on the phone. Photos never leave the device.
- The circular/petal stamp becomes a playable Classic Garden tile (not Today’s Bloom, so UTC deals stay fair). Cap 12 scanned blooms; the 13th replaces the oldest.
- Classic’s opening tray is dealt before the profile attaches; scanned stamps are overlaid in place (no extra RNG) so they can show immediately.

## Progression loop

- **Petals** — 1 per cleared line, plus a small combo bonus. Sinks are data-driven in `PetalCatalog.swift`: Garden mist (10, mist spray VFX), Dew burst (22, dew sparkle + 1.5× / 15 min), Organic pouch (90), Bee lantern (8, garden bee + 1.5× / 1 min), pot tints (12–20, glaze the pot mesh), plus Lotus (30) and Desert Bloom (40).
- **Daily goals** — three UTC-stable chores (lines / combo / score / petal catch). Auto-claim, once per goal.
- **Streak** — unchanged Today’s Bloom UTC streak.
- **Album XP + collector tiers** — XP from collected variants (Common 8 / Rare 14 / Epic 24 / Ultra 40), +12 first-species bonus, +6 per camera scan. Tiers (not “super flower collector”):

| Tier | XP |
| --- | --- |
| Sprout Scout | 0 |
| Meadow Keeper | 80 |
| Bloom Sage | 280 |
| Greenhouse Legend | 800 |

Album shows a progress bar and “N XP to next tier.” Fun facts sit on each unlocked species and on collected color rows (`BloomFacts` in `ScoreRewards.swift`).
- Rewarded **Bloom revive**, **New tray**, and Greenhouse **Watch to unlock** are unchanged and still player-initiated. Optional **Watch for fertilizer** uses the same rewarded unit, grants a regular charge you apply to a plant, and is never required to play Classic Garden.

## Garden growing loop

Home → **My Garden** (water / fertilizer) or **Seed Packs** (same screen). Fertilizer, Organic, unopened packs, petal shop, and pot tints sit **above** the six beds. The column scrolls on small phones. New profiles start with tulip, daisy, and rose seeds. Each bed is a **potted plant** — selected pot tint colors the pot mesh (rim / body / saucer), not a status-bar sliver. Watering plays a droplet overlay on that bed. **Garden mist** sprays the whole plot grid; **Dew burst** sparkles over the beds. **Bee lantern** sends a bee around planted flowers for 1.5× growth for about a minute.

### Grow times

No instant grows. Fertilizer changes *rate*, never skips to done.

| Rarity | Grow duration |
| --- | --- |
| Common | **12 min** |
| Rare | **18 min** |
| Epic | **30 min** |
| Ultra | **48 min** |

### Water / care

Every plant needs water about **every 3 hours** (same clock for all rarities). After that: **20 min** yellow “Needs water”, then **40 min** orange wilt, then death. Wilted plants pause growth. Death empties the bed (~22% seed salvage). Watering anytime while alive resets the 3h clock. Watering animation: falling droplets + soil wash (`WateringFX`). Legacy plots still get a fresh water clock on load.

### Fertilizer tiers

| Kind | How to get | Boost | Duration | Per-plant cooldown | Cap |
| --- | --- | --- | --- | --- | --- |
| Regular | Rewarded ad | 2× | 2 hours | 24 hours | 5 |
| Organic | Bee Trail (first win + every 3rd), score **2500+** once per UTC day, or 90 petals | 3× | 4 hours | 12 hours | 3 |

Select Regular (watch) or Organic, then **Fertilize** on a bed. Dew burst (22 petals) is a separate 1.5× / 15 min on all growing plants (with a dew sparkle). Bee lantern (8 petals) is a garden visit: 1.5× for ~1 minute while a bee flies the pots. It is no longer a Bee Trail hint.

## Flower maps (species stages)

Home → **Flower Maps**. Classic Garden is always playable from the big hero button. Each species has a named board that unlocks when you **collect** that flower (place it in Classic, harvest it, win its mini-game, buy Lotus, or unlock its map skin).

| Stage | Backdrop | How to unlock |
| --- | --- | --- |
| Classic Garden | Your Greenhouse skin | Always |
| Tulip Walk / Daisy Field / Rose Garden / Lily Pond / Lavender Lane / Hydrangea House | Meadow, sunflower, sakura, moonlight | Collect that starter (place it in Classic) |
| Orchid House | Night Garden look | Petal Catch |
| Peony Court | Sakura Grove look | Pattern Bloom |
| Lotus Pool | Glasshouse | 30 petals in the album |
| Succulent Dunes | Desert Bloom | Unlock Desert Bloom (40 petals) |
| Moon Terrace | Night Garden | Unlock Night Garden (ad) |
| Sakura Path | Sakura Grove | Unlock Sakura Grove (ad) |
| Starfire Grove / Night Orchid Court / Sunburst Meadow | Sunflower / moonlight | Harvest that Ultra (seed pack) |

Stage boards force their backdrop (you do not need to own the cosmetic to play the stage). Scanned camera tiles stay Classic-only. Ultra wipes work on Classic and on stages, never on Today’s Bloom.

## Seed packs

Fair gacha: a pack of rarity **X only grants seeds of that tier**, rolled across the species × color matrix (a Rare pack can drop Rare White Rose or Rare Blue Hydrangea, never a Common or Ultra).

| Pack | How to get | Contents |
| --- | --- | --- |
| Common | Score 100, Petal Catch repeats, Bloom Match, Bee Trail repeats, or 18 petals | 3 Common seeds |
| Rare | Score 500, first Petal Catch / Bee Trail, Pattern Bloom repeats, or 40 petals | 2 Rare seeds |
| Epic | Score 1000, first Pattern Bloom, or 70 petals | 1 Epic seed |
| Ultra | Score 2000 at **22%**, score 4000 guaranteed, winning **Petal Catch + Pattern Bloom** once, or 120 petals | 1 Ultra seed |

### Score → pack table (run end)

Classic, Today’s Bloom, and flower-map stages all use `ScorePackTable` in `ScoreRewards.swift`. Each rung is granted **at most once per run** (revive can unlock later rungs). Daily and Classic **do not share** a scoreboard entry.

| Score | Pack | Chance |
| --- | --- | --- |
| 100 | Common | always |
| 500 | Rare | always |
| 1000 | Epic | always |
| 2000 | Ultra | **22%** (rung still consumed on a miss) |
| 2500 | Organic fertilizer | once per UTC day |
| 4000 | Ultra | always (if 2000 missed) |

## High scores and leaderboards

- **Classic Garden** lifetime best: `gridbloom.best.classic` (unchanged key).
- **Today’s Bloom** keeps a *per-UTC-day* best *and* a separate **lifetime Daily** best (`gridbloom.best.daily.lifetime`). Home chips: **Classic** / **Daily** (lifetime) / streak. Game-over on Daily also shows today’s run best vs all-time Daily.
- Home trophy opens **Leaderboards**. Local bests always save. Friends: **coming soon** until Game Center boards exist.
- Game Center (optional): `LeaderboardService` submits to `gridbloom.classic.highscore` and `gridbloom.daily.highscore` when `GKLocalPlayer` is authenticated. **Publisher setup:** App Store Connect → the Gridbloom app → Game Center → create those two GKLeaderboard IDs (integer, higher is better). Enable the Game Center capability on the App ID. No friends list ships until those IDs exist.

## Ultra abilities

Any **Ultra** variant (Ultra Pink Tulip, Ultra Amber Starfire, …) wipes the rest of the board when it dominates a line clear — Classic and flower-map stages, never Today’s Bloom. Common–Epic stay collection/score. Starfire / Night orchid / Sunburst still exist as Ultra-themed species with their own color ladders.

## Mini-games

Home → **Mini-games** (earn seed packs / petals / Organic):

1. **Petal Catch** — tap falling petals, catch 10 in 22s. First win: **Orchid** + Rare pack. Repeats: Common pack.
2. **Pattern Bloom** — repeat the flashed flowers for 3 rounds. First win: **Peony**, **Glasshouse**, Epic pack. Repeats: Rare pack.
3. **Bee Trail** *(new)* — follow the bee’s visit order under a timer. First win: Rare pack + **Organic**. Repeats: Common pack; Organic every 3rd win. **Bee lantern** (8 petals) now lives in My Garden (1.5× / 1 min + bee), not as a Bee Trail hint.
4. **Bloom Match** *(new)* — flip pairs of color variants (6 pairs, 8 misses). First win: Common pack. Repeats: Common, or Rare if mismatches ≤ 2.

Winning Petal Catch + Pattern Bloom once also grants a single **Ultra** pack. Repeats still pay a small petal bonus.

## Music

Procedural 24-second looping WAVs generated in `GardenMusic.swift` — **no bundled stems**. Category `.ambient` (hardware silent switch + mix with others).

A single hummed voice (fundamental + soft partials) slowly glides between neighbor tones — *hmmmmm, hummmmm, hmmmmm* — with a breathing swell and a few distant procedural bird chirps (sparser on Home). Not a stacked chord pad and not noise.

| Bed | Where | Tone |
| --- | --- | --- |
| Home | Menu, album, shop, settings, maps, mini-game list, leaderboards | Higher hummed wander (C–D–E–D) over a quiet G pedal |
| Garden | **My Garden** only | Lower, slower drone-hum (D–C–G–C) over a D2 pedal |
| Off | Match play, scan, and the four mini-games | SFX only |

Settings: **Sound** (SFX) and **Music** (beds). Music also respects Sound-off and the silent switch. Toggle Music after mute to restart the current bed.

## UI polish

- First-run intro (**≤5 swipeable pages**, skippable) covers Classic bloom/match, garden watering, seed packs, album, and mini-games. Completing plants the player in **Classic Garden**; Skip goes to Home. Shown once (`PlayerProfile.hasSeenIntro` / UserDefaults, migrated from the old settings flag). Settings → How to play replays the same pages. In-game “Drag a flower…” hint still appears on the first match.
- Settings: How to play, haptics, sound, **music**, color-distinct pieces, Reduce Motion.
- Home background **fades through album blooms** the player has collected. Fresh profiles (empty album) use a gentle default set (tulip, daisy, rose, lily).
- Home is a **scrollable** screen. Shop / **Leaderboards** / Settings stay as top icons. Destinations in order:
  1. **Classic Garden** (hero — mixed board, always free)
  2. **Flower Maps** / **My Garden** / **Seed Packs** / **Mini-games** / **Album** / **Scan Flower** (2-column grid)
  3. **Today’s Bloom** (UTC daily)
- **Seed Packs** and **My Garden** both open the garden screen. Pack count + fertilizer charges show on the Seed Packs tile.

## How to test in Xcode Simulator

1. Open `Gridbloom.xcodeproj` in Xcode 16+ (iOS 16+ iPhone simulator).
2. **Product → Test (⌘U)** — includes grow/water timers, score→pack table, Classic vs Daily boards, collector XP tiers, petal offers, Organic fertilizer, Bee Trail / Bloom Match rules, Ultra obtain flag, procedural music WAV render. Ads still use `MockRewardedAdService`.
3. **Product → Run (⌘R)** on an iPhone simulator.
4. First launch: swipe or tap through **≤5** intro pages, then **Let’s plant** should open **Classic Garden** (not an empty menu). Skip should land on Home. Relaunch must not show the intro again. Pieces should show a large flower on each colored block. Clearing a line should flash that **species across the whole phone** (HUD included, bigger with combo), then let you keep playing. End a run at 100+ and confirm a Common pack on game over (500 Rare, 1000 Epic). Classic best and Daily best on Home must be different chips.
5. Home **Scan Flower** or Album → **Scan**. Simulator has **no camera** and **no photo library fallback** — you should see the camera-required message. On a device, grant Camera, scan a bloom, plant it; Classic can deal it, Today’s Bloom must not.
6. Home → **Album**. Confirm Sprout Scout → Meadow Keeper progress, XP bar, and a fun fact on unlocked species. Starters collect as you place them. Buy Lotus if you have 30 petals.
7. Home → **Mini-games**: Petal Catch (Orchid + Rare), Pattern Bloom (Peony + Glasshouse + Epic), **Bee Trail** (Organic + Rare), **Bloom Match** (Common). Winning Petal Catch + Pattern Bloom still adds one Ultra pack (once). Open that Ultra pack — a full-screen Ultra bloom should play.
8. Greenhouse: Meadow Clay is free. Glasshouse **Use** after Pattern Bloom. Desert Bloom **40 petals**. Sakura / Night / Sunflower still **Watch to unlock** (DEBUG `forceGoogleTestAds` if AdMob isn’t filling).
9. Pause → New tray and game over → Bloom revive still require a tap; no mid-drag ads. Revive after 100 points should not grant a second Common pack; crossing 500 after revive should grant Rare.
10. Today’s Bloom should still deal the same tray for a UTC day (unit tests cover this). Its high score must not overwrite Classic’s.
11. Settings → Music off: home/garden loops stop. Sound off: SFX and music stop. Silent switch: both should duck (`.ambient`). Reduce Motion: full-screen bloom is a brief tint; watering FX is quieter.
12. Home → **My Garden**: plant a starter. Grow copy should show **12:00** (Common), not 1:00. **Water** plays droplets. Beds stay hydrated for ~3 hours. **Watch for fertilizer** still 2×/2h/24h. Earn Organic (Bee Trail) and apply — 3×/4h/12h. Spend petals on mist / dew — a mist spray or dew sparkle should play over the beds. Bee lantern should spawn a flying bee and 1.5× for ~1:00. Pot tints recolor the actual pot mesh. Home should fade through collected album flowers (or the default meadow if the album is empty).
13. Trophy on Home → Leaderboards. Classic and Daily cards are separate. Friends copy is “coming soon” unless Game Center is signed in and the two board IDs exist in App Store Connect.
14. Leave a plant unwatered past the 3h + 20m + 40m wilt window — it should die, empty the bed, and sometimes return a salvaged seed. Harvest an Ultra variant (or open an Ultra pack) and confirm the full-screen Ultra bloom. In **Classic** or a flower map (not Today’s Bloom), complete a line that is mostly that Ultra bloom — the rest of the board should wipe with a GRID bloom.
15. Place a tulip in Classic, then open **Flower Maps** — **Tulip Walk** should unlock and deal only tulips on the meadow board. Today’s Bloom should still ignore extra colors/rarities.

AdMob / StoreKit paths were not removed. `Products.storekit` remains unused by the shop. Restore still imports leftover IAP entitlements.
