import Foundation
import UIKit
import Vision

struct FlowerScanDraft: Equatable {
    var name: String
    var speciesHint: FlowerSpecies?
    var hue: Double
    var saturation: Double
    var brightness: Double
    var usedVision: Bool
    var note: String
}

enum FlowerColorHeuristic {
    /// Classify from HSB of the colorful (non-foliage) pixels. Pure and testable.
    static func classify(hue: Double, saturation: Double, brightness: Double) -> FlowerScanDraft {
        let h = wrappedHue(hue)
        let s = min(1, max(0, saturation))
        let b = min(1, max(0, brightness))
        let species: FlowerSpecies
        let name: String
        switch h {
        case 0..<0.06, 0.92...1:
            species = .rose
            name = "Blush bloom"
        case 0.06..<0.12:
            species = .tulip
            name = "Coral bloom"
        case 0.12..<0.18:
            species = .cactusBloom
            name = "Sunset bloom"
        case 0.18..<0.22:
            species = .daisy
            name = "Golden bloom"
        case 0.22..<0.45:
            species = .lily
            name = s < 0.25 ? "Cream bloom" : "Meadow bloom"
        case 0.45..<0.58:
            species = .hydrangea
            name = "Sky bloom"
        case 0.58..<0.72:
            species = .lavender
            name = "Lilac bloom"
        case 0.72..<0.82:
            species = .orchid
            name = "Orchid bloom"
        default:
            species = .peony
            name = "Petal bloom"
        }
        let custom = s < 0.18 ? "Custom bloom" : name
        return FlowerScanDraft(
            name: custom,
            speciesHint: species,
            hue: h,
            saturation: s,
            brightness: b,
            usedVision: false,
            note: "Named on-device from color. No photo left this device."
        )
    }

    static func sample(image: UIImage) -> (hue: Double, saturation: Double, brightness: Double) {
        guard let cg = downsampled(image, maxSide: 48) else {
            return (0.92, 0.45, 0.7)
        }
        let width = cg.width
        let height = cg.height
        let bytesPerPixel = 4
        var data = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * bytesPerPixel,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (0.92, 0.45, 0.7)
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hueSum = 0.0, satSum = 0.0, briSum = 0.0, weight = 0.0
        for i in stride(from: 0, to: data.count, by: 4) {
            let r = Double(data[i]) / 255.0
            let g = Double(data[i + 1]) / 255.0
            let b = Double(data[i + 2]) / 255.0
            var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
            UIColor(red: r, green: g, blue: b, alpha: 1).getHue(&h, saturation: &s, brightness: &v, alpha: &a)
            // Skip washed-out pixels and typical foliage greens so the bloom color wins.
            if s < 0.18 || v < 0.12 { continue }
            if h > 0.22 && h < 0.45 && s > 0.25 && g > r && g > b { continue }
            let w = Double(s * s)
            hueSum += Double(h) * w
            satSum += Double(s) * w
            briSum += Double(v) * w
            weight += w
        }
        guard weight > 0 else { return (0.92, 0.4, 0.72) }
        return (hueSum / weight, satSum / weight, briSum / weight)
    }

    private static func wrappedHue(_ hue: Double) -> Double {
        let x = hue.truncatingRemainder(dividingBy: 1)
        return x < 0 ? x + 1 : x
    }

    private static func downsampled(_ image: UIImage, maxSide: Int) -> CGImage? {
        guard let cg = image.cgImage else { return nil }
        let longest = max(cg.width, cg.height)
        if longest <= maxSide { return cg }
        let scale = CGFloat(maxSide) / CGFloat(longest)
        let size = CGSize(width: CGFloat(cg.width) * scale, height: CGFloat(cg.height) * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.cgImage
    }
}

enum FlowerScanner {
    /// On-device classify. Tries Vision’s built-in image classifier, then a color heuristic.
    static func analyze(_ image: UIImage) -> FlowerScanDraft {
        let sample = FlowerColorHeuristic.sample(image: image)
        var draft = FlowerColorHeuristic.classify(hue: sample.hue, saturation: sample.saturation, brightness: sample.brightness)
        if let vision = visionMatch(image) {
            draft.name = vision.name
            draft.speciesHint = vision.species
            draft.usedVision = true
            draft.note = "Spotted on-device as \(vision.name). Photo never leaves this iPhone."
        }
        return draft
    }

    private static func visionMatch(_ image: UIImage) -> (name: String, species: FlowerSpecies)? {
        guard let cg = image.cgImage else { return nil }
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        let observations = (request.results as? [VNClassificationObservation]) ?? []
        for item in observations.prefix(8) {
            let id = item.identifier.lowercased()
            guard item.confidence >= 0.15 else { continue }
            if let species = mapIdentifier(id) {
                return (species.title, species)
            }
            if id.contains("flower") || id.contains("blossom") || id.contains("petal") {
                continue
            }
        }
        return nil
    }

    static func mapIdentifier(_ identifier: String) -> FlowerSpecies? {
        let id = identifier.lowercased()
        let pairs: [(String, FlowerSpecies)] = [
            ("tulip", .tulip),
            ("daisy", .daisy),
            ("rose", .rose),
            ("lily", .lily),
            ("lavender", .lavender),
            ("hydrangea", .hydrangea),
            ("orchid", .orchid),
            ("peony", .peony),
            ("lotus", .lotus),
            ("cactus", .cactusBloom),
            ("sunflower", .daisy),
            ("cherry", .cherryBlossom),
            ("blossom", .cherryBlossom),
            ("poppy", .cactusBloom),
            ("iris", .orchid),
            ("violet", .lavender),
            ("lilac", .lavender),
            ("jasmine", .moonflower)
        ]
        return pairs.first { id.contains($0.0) }?.1
    }
}
