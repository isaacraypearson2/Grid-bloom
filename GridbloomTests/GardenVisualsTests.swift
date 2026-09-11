import XCTest
@testable import Gridbloom

final class GardenVisualsTests: XCTestCase {
    func testPetalOfferCostsStayPut() {
        XCTAssertEqual(PetalOffer.mistAll.cost, 10)
        XCTAssertEqual(PetalOffer.dewBurst.cost, 22)
        XCTAssertEqual(PetalOffer.organicPouch.cost, 90)
        XCTAssertEqual(PetalOffer.beeHint.cost, 8)
        XCTAssertEqual(PetalOffer.potSage.cost, PotTint.sage.petalCost)
        XCTAssertEqual(PetalOffer.potBlush.cost, PotTint.blush.petalCost)
        XCTAssertEqual(PetalOffer.potMidnight.cost, PotTint.midnight.petalCost)
        XCTAssertEqual(PetalOffer.potCream.cost, PotTint.cream.petalCost)
    }

    func testDewStaysFifteenMinutesAndLanternIsOneMinuteAt1_5x() {
        XCTAssertEqual(SeedGardenRules.dewDuration, 15 * 60, accuracy: 0.1)
        XCTAssertEqual(SeedGardenRules.dewMultiplier, 1.5, accuracy: 0.01)
        XCTAssertEqual(SeedGardenRules.lanternDuration, 60, accuracy: 0.1)
        XCTAssertEqual(SeedGardenRules.lanternMultiplier, 1.5, accuracy: 0.01)
    }

    func testBeeLanternFromShopGrantsMinuteBoostAndShowsAsActive() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.visuals.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let plantedAt = Date(timeIntervalSince1970: 8_000_000)
        _ = try XCTUnwrap(profile.plantSeed(.tulip, slot: 0, now: plantedAt))
        profile.addPetals(8)
        XCTAssertTrue(profile.redeem(.beeHint, now: plantedAt))
        XCTAssertEqual(profile.beeHints, 0)
        XCTAssertTrue(profile.isBeeLanternActive(now: plantedAt.addingTimeInterval(10)))
        XCTAssertEqual(profile.beeLanternRemaining(now: plantedAt), 60, accuracy: 0.5)
        XCTAssertFalse(profile.isBeeLanternActive(now: plantedAt.addingTimeInterval(61)))

        var live = try XCTUnwrap(profile.gardenPlots.first)
        live.tick(now: plantedAt.addingTimeInterval(10), lanternUntil: profile.beeLanternUntil)
        XCTAssertEqual(live.growthRate(at: plantedAt, lanternUntil: profile.beeLanternUntil), 1.5, accuracy: 0.01)
        XCTAssertEqual(
            live.workRemaining,
            SeedRarity.common.growDuration - 15,
            accuracy: 0.3,
            "10s at 1.5× should burn 15s of work"
        )
    }

    func testLeftoverBeeHintsBecomeLanternTime() throws {
        let suiteName = "gridbloom.visuals.hints.\(UUID().uuidString)"
        let suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        suite.set(2, forKey: "gridbloom.profile.beeHints")
        let profile = PlayerProfile(defaults: suite)
        XCTAssertEqual(profile.beeHints, 0)
        XCTAssertEqual(profile.beeLanternRemaining(), 120, accuracy: 2)
    }

    func testLanternPersistsAcrossReload() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.visuals.persist.\(UUID().uuidString)"))
        let now = Date(timeIntervalSince1970: 9_000_000)
        let first = PlayerProfile(defaults: suite)
        first.addPetals(8)
        XCTAssertTrue(first.redeem(.beeHint, now: now))
        let until = try XCTUnwrap(first.beeLanternUntil)

        let second = PlayerProfile(defaults: suite)
        XCTAssertEqual(second.beeLanternUntil?.timeIntervalSince1970 ?? 0, until.timeIntervalSince1970, accuracy: 0.5)
        XCTAssertTrue(second.isBeeLanternActive(now: now.addingTimeInterval(30)))
    }

    func testHomeSlideshowUsesCollectedThenDefault() {
        XCTAssertEqual(HomeBloomSlideshow.blooms(collectedVariantIDs: []), HomeBloomSlideshow.defaultBlooms)
        XCTAssertEqual(HomeBloomSlideshow.defaultBlooms.count, 4)

        let rose = BloomCatalog.signature(.rose)
        let orchid = BloomCatalog.signature(.orchid)
        let slides = HomeBloomSlideshow.blooms(collectedVariantIDs: [rose.catalogKey, orchid.catalogKey])
        XCTAssertEqual(slides, [rose, orchid].sorted())
        XCTAssertFalse(slides.contains(where: { $0.species == .tulip }))
    }

    func testPotTintColorsPaintTheMeshNotOnlyABar() {
        for tint in PotTint.allCases {
            XCTAssertNotEqual(tint.fill, tint.rim)
            XCTAssertNotEqual(tint.fill, tint.saucer)
        }
        XCTAssertTrue(PetalOffer.potSage.blurb.lowercased().contains("pot"))
        XCTAssertTrue(PetalOffer.beeHint.blurb.lowercased().contains("1.5"))
        XCTAssertTrue(PetalOffer.mistAll.blurb.lowercased().contains("mist"))
        XCTAssertTrue(PetalOffer.dewBurst.blurb.lowercased().contains("dew"))
    }
}
