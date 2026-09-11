import SwiftUI

/// Droplets + soil darken when a bed is watered.
struct WateringFX: View {
    var accent: Color
    var reduced: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduced ? 1 : 1.0 / 24.0, paused: false)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let drops = reduced ? 3 : 10
                for i in 0..<drops {
                    let phase = (t * (reduced ? 0.9 : 1.6) + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
                    let x = size.width * (0.18 + 0.7 * CGFloat((sin(Double(i) * 1.7) + 1) / 2))
                    let y = size.height * CGFloat(phase)
                    var drop = Path()
                    drop.addEllipse(in: CGRect(x: x - 3, y: y - 6, width: 6, height: 11))
                    context.fill(drop, with: .color(Color(red: 0.42, green: 0.68, blue: 0.92).opacity(0.85 - phase * 0.5)))
                }
                context.fill(
                    Path(roundedRect: CGRect(x: 6, y: size.height * 0.72, width: size.width - 12, height: size.height * 0.22), cornerRadius: 8),
                    with: .color(Color(red: 0.28, green: 0.42, blue: 0.28).opacity(0.22))
                )
            }
        }
        .allowsHitTesting(false)
        .overlay(alignment: .top) {
            Image(systemName: "drop.fill")
                .font(.title2)
                .foregroundColor(Color(red: 0.32, green: 0.58, blue: 0.86))
                .padding(.top, 8)
                .opacity(reduced ? 0.7 : 1)
        }
        .accessibilityHidden(true)
    }
}
