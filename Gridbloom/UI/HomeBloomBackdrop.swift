import SwiftUI

/// Home menu slideshow: fade through album blooms, or a gentle default meadow.
enum HomeBloomSlideshow {
    static let dwell: TimeInterval = 4.4
    static let fade: TimeInterval = 1.15
    static let maxSlides = 16

    static let defaultBlooms: [BloomVariant] = [
        BloomCatalog.signature(.tulip),
        BloomCatalog.signature(.daisy),
        BloomCatalog.signature(.rose),
        BloomCatalog.signature(.lily)
    ]

    static func blooms(collectedVariantIDs: Set<String>) -> [BloomVariant] {
        let collected = collectedVariantIDs
            .compactMap(BloomVariant.parse)
            .sorted()
        if collected.isEmpty { return defaultBlooms }
        if collected.count <= maxSlides { return collected }
        let step = Double(collected.count) / Double(maxSlides)
        return (0..<maxSlides).map { collected[Int(Double($0) * step)] }
    }
}

struct HomeBloomBackdrop: View {
    var blooms: [BloomVariant]
    var reduced: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduced ? 1 : 1.0 / 20.0, paused: false)) { timeline in
            let slides = blooms.isEmpty ? HomeBloomSlideshow.defaultBlooms : blooms
            let pair = Self.crossfade(at: timeline.date, count: slides.count, reduced: reduced)
            ZStack {
                slide(slides[pair.current], opacity: pair.outgoing)
                if slides.count > 1 {
                    slide(slides[pair.next], opacity: pair.incoming)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func slide(_ bloom: BloomVariant, opacity: Double) -> some View {
        ZStack {
            BloomMark(size: 210, petal: bloom.swiftTint)
                .opacity(0.22 * opacity)
                .offset(x: 88, y: -36)
            BloomMark(size: 128, petal: bloom.swiftTint)
                .opacity(0.16 * opacity)
                .offset(x: -110, y: 210)
            BloomMark(size: 72, petal: bloom.swiftTint)
                .opacity(0.20 * opacity)
                .offset(x: 120, y: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private struct FadePair {
        var current: Int
        var next: Int
        var outgoing: Double
        var incoming: Double
    }

    private static func crossfade(at date: Date, count: Int, reduced: Bool) -> FadePair {
        let n = max(count, 1)
        if reduced || n == 1 {
            let pulse = 0.82 + 0.18 * (sin(date.timeIntervalSinceReferenceDate * 0.35) + 1) / 2
            return FadePair(current: 0, next: 0, outgoing: pulse, incoming: 0)
        }
        let period = HomeBloomSlideshow.dwell
        let cycle = date.timeIntervalSinceReferenceDate / period
        let current = Int(floor(cycle)) % n
        let next = (current + 1) % n
        let frac = cycle - floor(cycle)
        let fade = min(0.45, HomeBloomSlideshow.fade / period)
        if frac < 1 - fade {
            return FadePair(current: current, next: next, outgoing: 1, incoming: 0)
        }
        let t = (frac - (1 - fade)) / fade
        return FadePair(current: current, next: next, outgoing: 1 - t, incoming: t)
    }
}
