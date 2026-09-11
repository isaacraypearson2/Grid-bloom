import SwiftUI

enum GardenBurstFX: Equatable {
    case mist
    case dew
}

/// Soft spray that reads as garden-wide mist, not a silent water tick.
struct MistSprayFX: View {
    var reduced: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduced ? 1 : 1.0 / 24.0, paused: false)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let puffs = reduced ? 4 : 14
                for i in 0..<puffs {
                    let phase = (t * (reduced ? 0.35 : 0.55) + Double(i) * 0.19).truncatingRemainder(dividingBy: 1)
                    let x = size.width * (0.06 + 0.88 * CGFloat((sin(Double(i) * 1.3 + t * 0.4) + 1) / 2))
                    let y = size.height * CGFloat(0.08 + phase * 0.78)
                    let w = 18 + CGFloat(i % 5) * 7
                    var cloud = Path()
                    cloud.addEllipse(in: CGRect(x: x - w * 0.5, y: y - 10, width: w, height: 16 + CGFloat(i % 3) * 3))
                    context.fill(cloud, with: .color(Color.white.opacity(0.22 - phase * 0.12)))
                    context.fill(cloud, with: .color(Color(red: 0.62, green: 0.82, blue: 0.94).opacity(0.28 - phase * 0.16)))
                }
                let jets = reduced ? 3 : 8
                for i in 0..<jets {
                    let phase = (t * (reduced ? 0.8 : 1.4) + Double(i) * 0.28).truncatingRemainder(dividingBy: 1)
                    let x = size.width * (0.12 + 0.76 * CGFloat(i) / CGFloat(max(jets - 1, 1)))
                    var spray = Path()
                    spray.addEllipse(in: CGRect(x: x - 3, y: size.height * CGFloat(phase) - 8, width: 6, height: 14))
                    context.fill(spray, with: .color(Color(red: 0.40, green: 0.70, blue: 0.92).opacity(0.55 - phase * 0.35)))
                }
            }
        }
        .allowsHitTesting(false)
        .overlay(alignment: .top) {
            Image(systemName: "cloud.drizzle.fill")
                .font(.title2)
                .foregroundColor(Color(red: 0.38, green: 0.62, blue: 0.86))
                .padding(.top, 6)
                .opacity(reduced ? 0.65 : 0.9)
        }
        .accessibilityHidden(true)
    }
}

/// Sparkle wash that reads as dew landing on the beds.
struct DewSparkleFX: View {
    var reduced: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduced ? 1 : 1.0 / 24.0, paused: false)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let sparks = reduced ? 6 : 18
                for i in 0..<sparks {
                    let wobble = sin(t * 2.1 + Double(i) * 0.7)
                    let x = size.width * (0.08 + 0.84 * CGFloat((sin(Double(i) * 2.2) + 1) / 2))
                    let y = size.height * (0.12 + 0.72 * CGFloat((cos(Double(i) * 1.4 + t * 0.5) + 1) / 2))
                    let pulse = 0.35 + 0.65 * CGFloat((sin(t * 4 + Double(i)) + 1) / 2)
                    let r: CGFloat = reduced ? 3 : (2.2 + CGFloat(i % 4) + pulse * 1.6)
                    var star = Path()
                    star.addEllipse(in: CGRect(x: x - r, y: y - r + CGFloat(wobble) * 2, width: r * 2, height: r * 2))
                    let dew = i.isMultiple(of: 2)
                        ? Color(red: 0.55, green: 0.86, blue: 0.96)
                        : Color(red: 0.98, green: 0.92, blue: 0.55)
                    context.fill(star, with: .color(dew.opacity(0.35 + pulse * 0.45)))
                }
            }
        }
        .allowsHitTesting(false)
        .overlay(alignment: .top) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(Color(red: 0.42, green: 0.72, blue: 0.88))
                .padding(.top, 6)
                .opacity(reduced ? 0.65 : 0.95)
        }
        .accessibilityHidden(true)
    }
}

/// Drawn bee that patrols planted pots while a lantern is burning.
struct GardenBee: View {
    var flapping: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.white.opacity(flapping ? 0.82 : 0.45))
                .frame(width: 16, height: flapping ? 11 : 6)
                .offset(x: -7, y: -7)
                .rotationEffect(.degrees(-28))
            Ellipse()
                .fill(Color.white.opacity(flapping ? 0.78 : 0.4))
                .frame(width: 16, height: flapping ? 11 : 6)
                .offset(x: 5, y: -8)
                .rotationEffect(.degrees(24))
            Capsule()
                .fill(Color(red: 0.98, green: 0.82, blue: 0.22))
                .frame(width: 26, height: 14)
            Capsule()
                .fill(Color(red: 0.16, green: 0.12, blue: 0.08))
                .frame(width: 4, height: 14)
                .offset(x: -4)
            Capsule()
                .fill(Color(red: 0.16, green: 0.12, blue: 0.08))
                .frame(width: 4, height: 14)
                .offset(x: 4)
            Circle()
                .fill(Color(red: 0.14, green: 0.10, blue: 0.08))
                .frame(width: 10, height: 10)
                .offset(x: 13)
            Capsule()
                .fill(Color(red: 0.12, green: 0.10, blue: 0.08).opacity(0.7))
                .frame(width: 8, height: 2)
                .offset(x: 18, y: -4)
                .rotationEffect(.degrees(-25))
        }
        .frame(width: 42, height: 28)
        .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
        .accessibilityHidden(true)
    }
}

struct BeeLanternFlight: View {
    var plantedSlots: [Int]
    var reduced: Bool

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: reduced ? 0.5 : 1.0 / 24.0, paused: false)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let pose = Self.pose(at: t, in: geo.size, slots: plantedSlots, reduced: reduced)
                GardenBee(flapping: reduced ? false : sin(t * 18) > 0)
                    .scaleEffect(x: pose.facingRight ? 1 : -1, y: 1)
                    .position(pose.point)
            }
        }
        .allowsHitTesting(false)
        .accessibilityLabel("Bee lantern")
    }

    private struct Pose {
        var point: CGPoint
        var facingRight: Bool
    }

    private static func pose(at t: TimeInterval, in size: CGSize, slots: [Int], reduced: Bool) -> Pose {
        let targets = slots.isEmpty ? [0, 2, 5, 3] : slots.sorted()
        let speed = reduced ? 0.12 : 0.28
        let cycle = t * speed
        let count = max(targets.count, 1)
        let idx = Int(floor(cycle)) % count
        let nextIdx = (idx + 1) % count
        let frac = cycle - floor(cycle)
        let eased = frac * frac * (3 - 2 * frac)
        let a = slotPoint(targets[idx], in: size)
        let b = slotPoint(targets[nextIdx], in: size)
        let bob = reduced ? 0 : sin(t * 3.4) * 5
        let point = CGPoint(x: a.x + (b.x - a.x) * eased, y: a.y + (b.y - a.y) * eased + bob)
        return Pose(point: point, facingRight: b.x >= a.x)
    }

    private static func slotPoint(_ slot: Int, in size: CGSize) -> CGPoint {
        let col = CGFloat(slot % 3)
        let row = CGFloat(slot / 3)
        let x = size.width * (0.18 + col * 0.32)
        let y = size.height * (0.22 + row * 0.48)
        return CGPoint(x: x, y: y)
    }
}

/// Terracotta-style pot mesh. Tint cosmetics recolor the pot, not a status bar.
struct FlowerPotView: View {
    var tint: PotTint
    var empty: Bool

    var body: some View {
        ZStack(alignment: .top) {
            PotSaucer()
                .fill(tint.saucer)
                .frame(height: 10)
                .padding(.horizontal, 10)
                .offset(y: 58)
            FlowerPotShape()
                .fill(
                    LinearGradient(
                        colors: [tint.rim, tint.fill, tint.saucer],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    FlowerPotShape()
                        .stroke(tint.saucer.opacity(0.55), lineWidth: 1)
                )
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 5)
                        .padding(.vertical, 14)
                        .padding(.leading, 10)
                }
                .frame(height: 58)
                .padding(.horizontal, 8)
                .offset(y: 14)
            Capsule()
                .fill(tint.rim)
                .frame(height: 11)
                .padding(.horizontal, 4)
                .overlay(
                    Capsule()
                        .stroke(tint.saucer.opacity(0.45), lineWidth: 1)
                )
                .offset(y: 10)
            Ellipse()
                .fill(empty ? Color(red: 0.42, green: 0.32, blue: 0.22) : Color(red: 0.30, green: 0.22, blue: 0.14))
                .frame(height: 12)
                .padding(.horizontal, 12)
                .offset(y: 12)
        }
        .frame(height: 70)
        .accessibilityLabel("\(tint.title) pot")
    }
}

struct FlowerPotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rim = rect.height * 0.12
        let topInset = rect.width * 0.10
        let bottomInset = rect.width * 0.22
        path.move(to: CGPoint(x: rect.minX + topInset, y: rect.minY + rim))
        path.addLine(to: CGPoint(x: rect.maxX - topInset, y: rect.minY + rim))
        path.addLine(to: CGPoint(x: rect.maxX - bottomInset, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + bottomInset, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 3)
        )
        path.closeSubpath()
        return path
    }
}

struct PotSaucer: Shape {
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: rect)
    }
}
