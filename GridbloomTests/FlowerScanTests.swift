import XCTest
@testable import Gridbloom
import UIKit

final class FlowerScanTests: XCTestCase {
    func testColorHeuristicMapsRedToBlushAndRose() {
        let draft = FlowerColorHeuristic.classify(hue: 0.98, saturation: 0.7, brightness: 0.7)
        XCTAssertEqual(draft.speciesHint, .rose)
        XCTAssertEqual(draft.name, "Blush bloom")
        XCTAssertFalse(draft.usedVision)
    }

    func testColorHeuristicMapsYellowToGoldenDaisy() {
        let draft = FlowerColorHeuristic.classify(hue: 0.19, saturation: 0.8, brightness: 0.85)
        XCTAssertEqual(draft.speciesHint, .daisy)
        XCTAssertEqual(draft.name, "Golden bloom")
    }

    func testColorHeuristicLowSaturationIsCustomBloom() {
        let draft = FlowerColorHeuristic.classify(hue: 0.8, saturation: 0.1, brightness: 0.9)
        XCTAssertEqual(draft.name, "Custom bloom")
    }

    func testVisionIdentifierMapping() {
        XCTAssertEqual(FlowerScanner.mapIdentifier("garden tulip"), .tulip)
        XCTAssertEqual(FlowerScanner.mapIdentifier("rose flower"), .rose)
        XCTAssertEqual(FlowerScanner.mapIdentifier("Phalaenopsis orchid"), .orchid)
        XCTAssertNil(FlowerScanner.mapIdentifier("bicycle"))
    }

    func testDominantStorageOnRowClear() {
        var board = Board()
        board.fillRow(2, value: FlowerSpecies.lily.rawValue)
        let result = board.clearCompletedLines()
        XCTAssertEqual(result.dominantStorage, FlowerSpecies.lily.rawValue)
        XCTAssertEqual(result.bloomSpecies, .lily)
        XCTAssertEqual(result.lineCount, 1)
    }

    func testDominantStoragePicksMajorityType() {
        var board = Board()
        for x in 0..<8 {
            board.fill(GridPoint(x: x, y: 4), value: x < 5 ? FlowerSpecies.tulip.rawValue : FlowerSpecies.daisy.rawValue)
        }
        let result = board.clearCompletedLines()
        XCTAssertEqual(result.dominantStorage, FlowerSpecies.tulip.rawValue)
        XCTAssertEqual(result.bloomSpecies, .tulip)
    }

    func testThirteenthScanReplacesOldest() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.scan.\(UUID().uuidString)"))
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        CustomBloomDisk.useTemporaryDirectoryForTests(dir)
        defer { CustomBloomDisk.useTemporaryDirectoryForTests(nil) }

        let profile = PlayerProfile(defaults: suite)
        let stamp = solidImage(color: .magenta)
        let draft = FlowerColorHeuristic.classify(hue: 0.9, saturation: 0.7, brightness: 0.8)
        for index in 0..<13 {
            _ = try XCTUnwrap(profile.addCustomBloom(name: "Bloom \(index)", stamp: stamp, draft: draft))
        }
        XCTAssertEqual(profile.customBlooms.count, CustomBloom.maxCount)
        XCTAssertFalse(profile.customBlooms.contains { $0.name == "Bloom 0" })
        XCTAssertEqual(profile.customBlooms.last?.name, "Bloom 12")
    }

    func testAttachProfileOverlaysCustomOnOpeningTray() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.scan.\(UUID().uuidString)"))
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        CustomBloomDisk.useTemporaryDirectoryForTests(dir)
        defer { CustomBloomDisk.useTemporaryDirectoryForTests(nil) }

        let profile = PlayerProfile(defaults: suite)
        let stamp = solidImage(color: UIColor(hue: 0.9, saturation: 0.7, brightness: 0.8, alpha: 1))
        let draft = FlowerColorHeuristic.classify(hue: 0.9, saturation: 0.7, brightness: 0.8)
        let bloom = try XCTUnwrap(profile.addCustomBloom(name: draft.name, stamp: stamp, draft: draft))

        let template = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h"))
        XCTAssertEqual(template.colorIndex % 3, 0)
        let game = GameState(mode: .classic, scoreStore: InMemoryScoreStore())
        game.replaceTray([template.spawned(), template.spawned(), template.spawned()])
        XCTAssertTrue(game.tray.compactMap { $0?.customBloomID }.isEmpty)
        game.attachProfile(profile)
        XCTAssertEqual(game.tray[0]?.customBloomID, bloom.id)
        XCTAssertEqual(game.tray[0]?.storageValue, bloom.storageValue)
    }

    func testCustomBloomStorageAndClassicStamp() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.scan.\(UUID().uuidString)"))
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        CustomBloomDisk.useTemporaryDirectoryForTests(dir)
        defer { CustomBloomDisk.useTemporaryDirectoryForTests(nil) }

        let profile = PlayerProfile(defaults: suite)
        let stamp = solidImage(color: UIColor(hue: 0.9, saturation: 0.7, brightness: 0.8, alpha: 1))
        let draft = FlowerColorHeuristic.classify(hue: 0.9, saturation: 0.7, brightness: 0.8)
        let bloom = try XCTUnwrap(profile.addCustomBloom(name: draft.name, stamp: stamp, draft: draft))
        XCTAssertEqual(bloom.storageValue, CustomBloom.storageBase + bloom.slot)
        XCTAssertTrue(CustomBloom.isCustomStorage(bloom.storageValue))
        XCTAssertEqual(profile.customBloom(storage: bloom.storageValue)?.id, bloom.id)
        XCTAssertNotNil(CustomBloomDisk.stamp(id: bloom.id))

        var dealer = FairDealer(rng: SplitMix64(seed: 3))
        dealer.flowerRoster = profile.playableFlowers(for: .classic)
        dealer.customBlooms = profile.customBlooms
        var sawCustom = false
        for _ in 0..<24 {
            let tray = dealer.dealTray(on: Board())
            if tray.contains(where: { $0.customBloomID == bloom.id }) {
                sawCustom = true
                break
            }
        }
        XCTAssertTrue(sawCustom, "Classic dealer should stamp scanned blooms onto colorIndex % 3 == 0 pieces")

        let daily = GameState(mode: .daily, utcDay: "2026-09-10", scoreStore: InMemoryScoreStore(), profile: profile)
        XCTAssertTrue(daily.tray.compactMap { $0?.customBloomID }.isEmpty, "Today’s Bloom must not deal scanned tiles")
    }

    func testCircularStampIsSquare() {
        let image = solidImage(color: .red, size: CGSize(width: 80, height: 40))
        let stamp = CustomBloomDisk.makeStamp(from: image, size: 64)
        XCTAssertEqual(stamp.size.width, 64, accuracy: 0.5)
        XCTAssertEqual(stamp.size.height, 64, accuracy: 0.5)
    }

    private func solidImage(color: UIColor, size: CGSize = CGSize(width: 32, height: 32)) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
