import Foundation
import UIKit

/// A player-scanned flower that can appear as a Classic Garden tile.
/// Photos live on-device under Application Support; only this metadata is in UserDefaults.
struct CustomBloom: Codable, Equatable, Identifiable, Sendable {
    static let storageBase = 100
    static let maxCount = 12

    var id: UUID
    var name: String
    var slot: Int
    var guessedSpeciesRaw: Int?
    var hue: Double
    var saturation: Double
    var brightness: Double
    var identifiedOnDevice: Bool

    var storageValue: Int { Self.storageBase + slot }

    var guessedSpecies: FlowerSpecies? {
        guessedSpeciesRaw.flatMap(FlowerSpecies.init(rawValue:))
    }

    var fillColor: UIColor {
        UIColor(hue: hue, saturation: min(1, max(0.25, saturation)), brightness: min(1, max(0.35, brightness)), alpha: 1)
    }

    static func isCustomStorage(_ value: Int) -> Bool {
        value >= storageBase
    }
}

enum CustomBloomDisk {
    private static var memory: [UUID: UIImage] = [:]
    private static var directoryOverride: URL?

    static func useTemporaryDirectoryForTests(_ url: URL?) {
        directoryOverride = url
        if url == nil { memory.removeAll() }
    }

    static func directory() -> URL {
        if let directoryOverride { return directoryOverride }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("Gridbloom/Blooms", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(stamp: UIImage, id: UUID) {
        memory[id] = stamp
        guard let data = stamp.jpegData(compressionQuality: 0.82) else { return }
        try? data.write(to: fileURL(for: id), options: .atomic)
    }

    static func stamp(id: UUID) -> UIImage? {
        if let cached = memory[id] { return cached }
        guard let data = try? Data(contentsOf: fileURL(for: id)),
              let image = UIImage(data: data) else { return nil }
        memory[id] = image
        return image
    }

    static func remove(id: UUID) {
        memory.removeValue(forKey: id)
        try? FileManager.default.removeItem(at: fileURL(for: id))
    }

    static func fileURL(for id: UUID) -> URL {
        directory().appendingPathComponent("\(id.uuidString).jpg")
    }

    /// Circular petal stamp, cropped to the most interesting square.
    static func makeStamp(from image: UIImage, size: CGFloat = 256) -> UIImage {
        let square = centerSquare(image)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: size, height: size).insetBy(dx: 6, dy: 6)
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.clip()
            square.draw(in: rect)
            UIColor.white.withAlphaComponent(0.55).setStroke()
            ctx.cgContext.setLineWidth(5)
            ctx.cgContext.strokeEllipse(in: rect)
        }
    }

    static func centerSquare(_ image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let side = min(cg.width, cg.height)
        let x = (cg.width - side) / 2
        let y = (cg.height - side) / 2
        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: side, height: side)) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}
